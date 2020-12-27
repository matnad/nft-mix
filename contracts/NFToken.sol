pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Strings.sol";
import "../interfaces/IERC721TokenReceiver.sol";

/**
    @title Minimalistic Non-Fungible Token implementation
           including metadata and enumerable extensions
    @notice Based on the ERC-721 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-721
 */
contract NFToken {

    using SafeMath for uint256;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    string public name;
    string public symbol;

    struct TokenSet {
        uint256[] _tokenIds;
        mapping (uint256 => uint256) _indexes;
    }
    mapping (address => TokenSet) private _holderTokens;

    struct TokenEntry {
        uint256 _tokenId;
        address _owner;
    }
    struct TokenMap {
        TokenEntry[] _tokenEntries;
        mapping(uint256 => uint256) _indexes; // tokenId => position in array, starting at 1
    }
    TokenMap private _tokenOwners;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping(bytes4 => bool) private _supportedInterfaces;

    string public baseURI;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Checks if an NFT with `tokenId` exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners._indexes[tokenId] != 0;
    }

    // --Ownership

    /// @notice Count all NFTs assigned to an owner
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Query for zero address");
        return _holderTokens[_owner]._tokenIds.length;
    }

    /// @notice Find the owner of an NFT
    function ownerOf(uint256 tokenId) public view returns (address) {
        uint256 mapIndex = _tokenOwners._indexes[tokenId];
        require(mapIndex != 0, "Query for nonexistent tokenId");
        return _tokenOwners._tokenEntries[mapIndex - 1]._owner; // Indices are 1-based
    }

    // --Approve

    /// @notice Change or reaffirm the approved address for an NFT
    function approve(address approved, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not owner nor approved for all"
        );
        _approve(approved, tokenId);
    }

    /// @notice Get the approved address for a single NFT
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Query if an address is an authorized operator for another address
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _approve(address approved, uint256 tokenId) private {
        _tokenApprovals[tokenId] = approved;
        emit Approval(ownerOf(tokenId), approved, tokenId);
    }

    // --Transfer

    /// @notice Add token to owner if they don't hold it already. Separate token map update is required.
    function _addTokenToOwner(address to, uint256 tokenId) private {
        if (_holderTokens[to]._indexes[tokenId] == 0) {
            _holderTokens[to]._tokenIds.push(tokenId);
            _holderTokens[to]._indexes[tokenId] = _holderTokens[to]._tokenIds.length;
        }
    }

    /// @notice Remove token from owner if they hold it. Separate token map update is required.
    /// @dev Make sure `from` owns the token. There is no check for this here.
    function _removeTokenFromOwner(address from, uint256 tokenId) private {
        uint256 tokenIndex = _holderTokens[from]._indexes[tokenId];
        // Perform `swap and pop` on the `_tokenEntries` array. Runs in O(1), but modifies order.
        uint256 toDeleteIndex = tokenIndex - 1;
        uint256 lastIndex = _holderTokens[from]._tokenIds.length - 1;
        uint256 lastValue = _holderTokens[from]._tokenIds[lastIndex];

        // Move the last value to the index where the value to delete is
        _holderTokens[from]._tokenIds[toDeleteIndex] = lastValue;
        // Update the index for the moved value
        _holderTokens[from]._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based

        // Delete the slot where the moved value was stored
        _holderTokens[from]._tokenIds.pop();

        // Delete the index for the deleted slot
        delete _holderTokens[from]._indexes[tokenId];
    }

    /// @notice Update token ownership map.
    function _updateTokenOwnership(address newOwner, uint256 tokenId) private {
        uint256 tokenIndex = _tokenOwners._indexes[tokenId];
        if (tokenIndex == 0) {
            // Token does not exist yet, push to the `_tokenEntries` array.
            _tokenOwners._tokenEntries.push(TokenEntry({_tokenId: tokenId, _owner: newOwner}));
            _tokenOwners._indexes[tokenId] = _tokenOwners._tokenEntries.length;
        } else {
            // Token exists, update ownership
            _tokenOwners._tokenEntries[tokenIndex - 1]._owner = newOwner;
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer of unowned token");
        require(to != address(0), "Transfer to the zero address");

        // Clear approvals from the previous owner
        // Is this strictly required by the spec?
        // if (_tokenApprovals[tokenId] != address(0)) {
        //    _approve(address(0), tokenId);
        // }

        _removeTokenFromOwner(from, tokenId);
        _addTokenToOwner(to, tokenId);
        _updateTokenOwnership(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721 receiver");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    // --Metadata Module

    /// @notice Concatenates tokenId to baseURI and returns the string.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // --Enumerable Module

    /// @notice Count NFTs tracked by this contract
    function totalSupply() external view returns (uint256) {
        return _tokenOwners._tokenEntries.length;
    }

    /// @notice Enumerate valid NFTs
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(_tokenOwners._tokenEntries.length > index, "Index out of bounds");
        return _tokenOwners._tokenEntries[index]._tokenId;
    }

    /// @notice Enumerate NFTs assigned to an owner
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(_holderTokens[owner]._tokenIds.length > index, "Index out of bounds");
        return _holderTokens[owner]._tokenIds[index];
    }

    // --Minting

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "Transfer to non ERC721 receiver");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _addTokenToOwner(to, tokenId);
        _updateTokenOwnership(to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    // --Interface Code

    /**
     * @dev Internal function to invoke onERC721Received on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        private
        returns (bool)
    {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(to) }
        if (size == 0) {
            return true;
        }

        (bool success, bytes memory returnData) = to.call{ value: 0 }(
            abi.encodeWithSelector(
                ERC721TokenReceiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        require(success, "Transfer to non ERC721 receiver");
        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return (returnValue == _ERC721_RECEIVED);
    }

    /*
     * The interface id is defined as XOR of all function selectors in the interface:
     *     bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /*
     * The interface id is defined as XOR of all function selectors in the interface:
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///      uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///         `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    // --Constructor

     constructor(
        string memory _name,
        string memory _symbol
    )
        public
    {
        name = _name;
        symbol = _symbol;
        _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721_METADATA] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721_ENUMERABLE] = true;
    }

    // --Modify these methods, should require some form of contract ownership
    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI_) external {
        baseURI = baseURI_;
    }

}