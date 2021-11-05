# @version ^0.2.15

from vyper.interfaces import ERC20


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


@external
def __init__():
    pass


@external
def fakeTransfer(fake_asset: address, to: address, asset: address, amount: uint256):
    log Transfer(msg.sender, to, amount)
    log Transfer(to, ZERO_ADDRESS, amount)
    
    assert ERC20(asset).transferFrom(msg.sender, to, amount)