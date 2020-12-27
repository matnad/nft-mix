#!/usr/bin/python3

def test_erc165_support(nft):
    erc165_interface_id = "0x01ffc9a7"
    assert nft.supportsInterface(erc165_interface_id) is True


def test_erc721_support(nft):
    erc721_interface_id = "0x80ac58cd"
    assert nft.supportsInterface(erc721_interface_id) is True
