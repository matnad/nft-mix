#!/usr/bin/python3
import brownie


def test_approve(nft, accounts, zero_addr):
    nft.safeMint(accounts[2], 1337)

    assert nft.getApproved(1337) == zero_addr
    nft.approve(accounts[1], 1337, {'from': accounts[2]})
    assert nft.getApproved(1337) == accounts[1]


def test_change_approve(nft, accounts):
    nft.safeMint(accounts[2], 1337)

    nft.approve(accounts[1], 1337, {'from': accounts[2]})
    nft.approve(accounts[0], 1337, {'from': accounts[2]})
    assert nft.getApproved(1337) == accounts[0]


def test_revoke_approve(nft, accounts, zero_addr):
    nft.safeMint(accounts[2], 1337)

    nft.approve(accounts[1], 1337, {'from': accounts[2]})
    nft.approve(zero_addr, 1337, {'from': accounts[2]})
    assert nft.getApproved(1337) == zero_addr


def test_no_return_value(nft, accounts):
    nft.safeMint(accounts[2], 1337)

    tx = nft.approve(accounts[1], 1337, {'from': accounts[2]})
    assert tx.return_value is None


def test_approval_event_fire(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    tx = nft.approve(accounts[1], 1337, {'from': accounts[2]})
    assert len(tx.events) == 1
    assert tx.events["Approval"].values() == [accounts[2], accounts[1], 1337]


def test_illegal_approval(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Not owner nor approved for all"):
        nft.approve(accounts[1], 1337, {'from': accounts[1]})


def test_get_approved_nonexistent(nft, accounts):
    with brownie.reverts("Query for nonexistent token"):
        nft.getApproved(1337)
