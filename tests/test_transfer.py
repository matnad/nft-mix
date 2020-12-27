#!/usr/bin/python3
import brownie


def test_sender_balance_decreases(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    balance = nft.balanceOf(accounts[2])

    nft.transferFrom(accounts[2], accounts[3], 1337, {'from': accounts[2]})

    assert nft.balanceOf(accounts[2]) == balance - 1


def test_receiver_balance_increases(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    balance = nft.balanceOf(accounts[3])

    nft.transferFrom(accounts[2], accounts[3], 1337, {'from': accounts[2]})

    assert nft.balanceOf(accounts[3]) == balance + 1


def test_caller_balance_unaffected(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    balance = nft.balanceOf(accounts[4])

    nft.approve(accounts[4], 1337, {'from': accounts[2]})
    nft.transferFrom(accounts[2], accounts[3], 1337, {'from': accounts[4]})

    assert nft.balanceOf(accounts[4]) == balance


def test_ownership_changes(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    owner = nft.ownerOf(1337)

    nft.transferFrom(accounts[2], accounts[3], 1337, {'from': accounts[2]})

    assert nft.ownerOf(1337) != owner


def test_total_supply_not_affected(nft, accounts):
    nft.safeMint(accounts[2], 1337)
    total_supply = nft.totalSupply()

    nft.transferFrom(accounts[2], accounts[3], 1337, {'from': accounts[2]})

    assert nft.totalSupply() == total_supply


def test_safe_transfer_from_approval(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    nft.approve(accounts[4], 1337, {'from': accounts[0]})
    nft.safeTransferFrom(accounts[0], accounts[4], 1337, {'from': accounts[4]})
    assert nft.ownerOf(1337) == accounts[4]


def test_safe_transfer_from_operator(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    nft.setApprovalForAll(accounts[4], True, {'from': accounts[0]})
    nft.safeTransferFrom(accounts[0], accounts[2], 1337, {'from': accounts[4]})
    assert nft.ownerOf(1337) == accounts[2]


def test_transfer_no_approval(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Caller is not owner nor approved"):
        nft.transferFrom(accounts[0], accounts[1], 1337, {'from': accounts[4]})


def test_safe_transfer_nonexisting(nft, accounts):
    with brownie.reverts("Query for nonexistent token"):
        nft.safeTransferFrom(accounts[0], accounts[1], 1337, {'from': accounts[0]})


def test_safe_transfer_to_zero_address(nft, accounts, zero_addr):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Transfer to the zero address"):
        nft.safeTransferFrom(accounts[0], zero_addr, 1337, {'from': accounts[0]})


def test_safe_transfer_unowned(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    nft.approve(accounts[1], 1337, {'from': accounts[0]})
    with brownie.reverts("Transfer of unowned token"):
        nft.safeTransferFrom(accounts[1], accounts[4], 1337, {'from': accounts[1]})


def test_safe_transfer_from_no_approval(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Caller is not owner nor approved"):
        nft.safeTransferFrom(accounts[0], accounts[1], 1337, {'from': accounts[4]})


def test_safe_transfer_invalid_receiver(nft, accounts, receiver_invalid):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Transfer to non ERC721 receiver"):
        nft.safeTransferFrom(accounts[0], receiver_invalid.address, 1337, {'from': accounts[0]})


def test_transfer_invalid_receiver(nft, accounts, receiver_invalid):
    nft.safeMint(accounts[0], 1337)
    nft.transferFrom(accounts[0], receiver_invalid.address, 1337, {'from': accounts[0]})


def test_safe_transfer_invalid_receiver_return(nft, accounts, receiver_invalid_return):
    nft.safeMint(accounts[0], 1337)
    with brownie.reverts("Transfer to non ERC721 receiver"):
        nft.safeTransferFrom(accounts[0], receiver_invalid_return.address, 1337, {'from': accounts[0]})


def test_safe_transfer_valid_receiver(nft, accounts, receiver_valid):
    nft.safeMint(accounts[0], 1337)
    nft.safeTransferFrom(accounts[0], receiver_valid.address, 1337, {'from': accounts[0]})
