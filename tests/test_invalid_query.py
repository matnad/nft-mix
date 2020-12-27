#!/usr/bin/python3
import brownie


def test_balanceOf(nft, zero_addr):
    with brownie.reverts():
        nft.balanceOf(zero_addr)


def test_ownerOf(nft):
    with brownie.reverts():
        nft.ownerOf(0)
