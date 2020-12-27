# nft-mix

A minimalistic implementation of the Ethereum [ERC-721 standard](https://eips.ethereum.org/EIPS/eip-721), written in [Solidity](https://github.com/ethereum/solidity).
This includes the optional specifications for metadata and enumeration as well as minting of tokens.

## Installation

1. [Install Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html), if you haven't already.

2. Download the mix.

    ```bash
    brownie bake nft
    ```

## Basic Use

This mix provides a [simple template](contracts/NFToken.sol) upon which you can build your own token, as well as unit tests providing 100% coverage for core ERC721 functionality.

To interact with a deployed contract in a local environment, start by opening the console:

```bash
brownie console
```

Next, deploy a test NFT contract:

```python
>>> nft = NFToken.deploy("Test Token", "TEST", {'from': accounts[0]})

Transaction sent: 0x722bf73508b51d78549cdbbe0bca45c958bd590e8b450a2b1a465a63be921d9e
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 0
  NFToken.constructor confirmed - Block: 1   Gas used: 1490494 (12.42%)
  NFToken deployed at: 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87
```

You now have an NFT token contract deployed:

```python
>>> nft
<NFToken Contract '0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87'>
```

Mint a new NFT with a custom id:
```python
>>> nft.safeMint(accounts[0], 1337)
Transaction sent: 0x96fce5d421fea72089b4ff6d747ecc693acd3c2b15c1d9cf61bb41adc58c6a94
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 1
  NFToken.safeMint confirmed - Block: 2   Gas used: 172157 (1.43%)

>>> nft.balanceOf(accounts[0])
1

>>> nft.ownerOf(1337)
'0x66aB6D9362d4F35596279692F0251Db635165871'

>>> nft.safeTransferFrom(accounts[0], accounts[1], 1337, {'from': accounts[0]})
Transaction sent: 0x3831a74066c759e255c9c58955c138704443474ade23c3147b8a0a77bc06e1b0
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 2
  NFToken.safeTransferFrom confirmed - Block: 3   Gas used: 78967 (0.66%)

<Transaction '0x3831a74066c759e255c9c58955c138704443474ade23c3147b8a0a77bc06e1b0'>
```

Make sure to restrict the public `safeMint()` and `setBaseURI()` functions before deploying the contract in production.

## Testing

To run the tests:

```bash
brownie test
```

The unit tests included in this mix are very generic and should work with any ERC721 compliant smart contract that implement a `safeMint()` function. To use them in your own project, all you must do is modify the deployment logic in the [`tests/conftest.py::nft`](tests/conftest.py) fixture.

## Resources

To get started with Brownie:

* Check out the other [Brownie mixes](https://github.com/brownie-mix/) that can be used as a starting point for your own contracts. They also provide example code to help you get started.
* ["Getting Started with Brownie"](https://medium.com/@iamdefinitelyahuman/getting-started-with-brownie-part-1-9b2181f4cb99) is a good tutorial to help you familiarize yourself with Brownie.
* For more in-depth information, read the [Brownie documentation](https://eth-brownie.readthedocs.io/en/stable/).


Any questions? Join our [Gitter](https://gitter.im/eth-brownie/community) channel to chat and share with others in the community.

## License

This project is licensed under the [MIT license](LICENSE).
