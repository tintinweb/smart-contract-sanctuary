# @version ^0.2.16


interface ERC20:
    def transfer(_to: address, _value: uint256): nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256): nonpayable


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


@external
def __init__():
    pass


@external
@nonpayable
def fakeTransfer(to: address, asset1: address, amount: uint256):
    log Transfer(msg.sender, to, amount)
    log Transfer(to, ZERO_ADDRESS, amount)

    ERC20(asset1).transferFrom(msg.sender, to, amount)