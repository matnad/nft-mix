#!/usr/bin/python3
import brownie


def test_mint(nft, accounts):
    assert nft.totalSupply() == 0
    assert nft.balanceOf(accounts[1]) == 0

    nft.safeMint(accounts[1], 5)

    assert nft.totalSupply() == 1
    assert nft.balanceOf(accounts[1]) == 1
    assert nft.ownerOf(5) == accounts[1]


def test_mint_to_zero_reverts(nft, zero_addr):
    with brownie.reverts():
        nft.safeMint(zero_addr, 5)


def test_mint_existing_reverts(nft, accounts):
    nft.safeMint(accounts[0], 5)
    with brownie.reverts():
        nft.safeMint(accounts[1], 5)


def test_safe_mint_invalid_receiver(nft, receiver_invalid):
    with brownie.reverts("Transfer to non ERC721 receiver"):
        nft.safeMint(receiver_invalid.address, 1337)


def test_safe_mint_invalid_receiver_return(nft, receiver_invalid_return):
    with brownie.reverts("Transfer to non ERC721 receiver"):
        nft.safeMint(receiver_invalid_return.address, 1337)


def test_safe_mint_valid_receiver(nft, receiver_valid):
    nft.safeMint(receiver_valid.address, 1337)
