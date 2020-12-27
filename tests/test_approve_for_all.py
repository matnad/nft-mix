#!/usr/bin/python3


def test_approve_all(nft, accounts):
    assert nft.isApprovedForAll(accounts[0], accounts[1]) is False
    nft.setApprovalForAll(accounts[1], True, {'from': accounts[0]})
    assert nft.isApprovedForAll(accounts[0], accounts[1]) is True


def test_approve_all_multiple(nft, accounts):
    operators = accounts[4:8]
    for op in operators:
        assert nft.isApprovedForAll(accounts[1], op) is False

    for op in operators:
        nft.setApprovalForAll(op, True, {'from': accounts[1]})

    for op in operators:
        assert nft.isApprovedForAll(accounts[1], op) is True


def test_revoke_operator(nft, accounts):
    nft.setApprovalForAll(accounts[1], True, {'from': accounts[0]})
    assert nft.isApprovedForAll(accounts[0], accounts[1]) is True

    nft.setApprovalForAll(accounts[1], False, {'from': accounts[0]})
    assert nft.isApprovedForAll(accounts[0], accounts[1]) is False


def test_no_return_value(nft, accounts):
    tx = nft.setApprovalForAll(accounts[1], True, {'from': accounts[0]})
    assert tx.return_value is None


def test_approval_all_event_fire(nft, accounts):
    tx = nft.setApprovalForAll(accounts[1], True, {'from': accounts[0]})
    assert len(tx.events) == 1
    assert tx.events["ApprovalForAll"].values() == [accounts[0], accounts[1], True]


def test_operator_approval(nft, accounts):
    nft.safeMint(accounts[0], 1337)
    nft.setApprovalForAll(accounts[1], True, {'from': accounts[0]})
    nft.approve(accounts[2], 1337, {'from': accounts[1]})
