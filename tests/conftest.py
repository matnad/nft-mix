#!/usr/bin/python3

import pytest
from brownie import compile_source


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.12.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def nft(NFToken, accounts):
    return NFToken.deploy("Test NFT", "TEST", {'from': accounts[9]})


@pytest.fixture(scope="module")
def zero_addr():
    return "0x0000000000000000000000000000000000000000"


@pytest.fixture(scope="module")
def receiver_invalid(accounts):
    receiver_invalid_src = """pragma solidity ^0.7.0;

    contract Invalid {}
    """
    compiled = compile_source(receiver_invalid_src)
    receiver = compiled.Invalid.deploy({'from': accounts[0]})
    return receiver


@pytest.fixture(scope="module")
def receiver_invalid_return(accounts):
    receiver_invalid_ret_src = """pragma solidity ^0.7.0;

    contract Invalid {
        function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) 
          external returns(bytes4) {
            return 0x0;
        }
    }
    """
    compiled = compile_source(receiver_invalid_ret_src)
    receiver = compiled.Invalid.deploy({'from': accounts[0]})
    return receiver


@pytest.fixture(scope="module")
def receiver_valid(accounts):
    receiver_valid_src = """pragma solidity ^0.7.0;

    contract Valid {
        function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) 
          external returns(bytes4) {
            return 0x150b7a02;
        }
    }
    """
    compiled = compile_source(receiver_valid_src)
    receiver = compiled.Valid.deploy({'from': accounts[0]})
    return receiver
