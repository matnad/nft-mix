#!/usr/bin/python3
import random

import brownie
import pytest


def test_enumeration_support(nft):
    enumeration_interface_id = "0x780e9d63"
    assert nft.supportsInterface(enumeration_interface_id) is True


@pytest.mark.parametrize("n_tokens", [1, 3, 5])
def test_total_supply(nft, accounts, n_tokens):
    assert nft.totalSupply() == 0

    for n in range(n_tokens):
        random_account = random.choice(accounts)
        nft.safeMint(random_account, n)

    assert nft.totalSupply() == n_tokens


def test_token_by_index(nft, accounts):
    token_ids = [10, 15, 1337, 22, 55]

    for token in token_ids:
        nft.safeMint(accounts[0], token)

    for idx, token in enumerate(token_ids):
        assert nft.tokenByIndex(idx) == token


def test_token_by_index_reverts(nft, accounts):
    nft.safeMint(accounts[0], 55)
    nft.safeMint(accounts[0], 56)
    with brownie.reverts():
        nft.tokenByIndex(2)


def test_token_of_owner_by_index(nft, accounts):
    token_ids = [10, 15, 1337, 22, 55]
    owners = [accounts[0], accounts[0], accounts[1], accounts[2], accounts[0]]

    for tid, owner in zip(token_ids, owners):
        nft.safeMint(owner, tid)

    assert nft.tokenOfOwnerByIndex(accounts[0], 0) == 10
    assert nft.tokenOfOwnerByIndex(accounts[0], 1) == 15
    assert nft.tokenOfOwnerByIndex(accounts[1], 0) == 1337
    assert nft.tokenOfOwnerByIndex(accounts[2], 0) == 22
    assert nft.tokenOfOwnerByIndex(accounts[0], 2) == 55


def test_token_of_owner_by_index_reverts(nft, accounts):
    nft.safeMint(accounts[0], 55)
    nft.safeMint(accounts[0], 56)
    with brownie.reverts():
        nft.tokenOfOwnerByIndex(accounts[0], 2)
    with brownie.reverts():
        nft.tokenOfOwnerByIndex(accounts[1], 0)
