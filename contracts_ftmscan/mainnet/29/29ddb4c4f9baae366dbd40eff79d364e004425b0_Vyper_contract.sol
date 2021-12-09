# @version 0.2.12
"""
@title Token Treasury
@author Hundred Finance
@license MIT
"""

from vyper.interfaces import ERC20


token: public(address)
minter: public(address)
admin: public(address)

@external
def __init__(_token: address):
    self.token = _token
    self.admin = msg.sender

@external
@nonpayable
def set_minter(_minter: address):
    assert msg.sender == self.admin # only admin can set minter
    self.minter = _minter

@external
@nonpayable
def set_admin(_admin: address):
    assert msg.sender == self.admin # only admin can set minter
    self.admin = _admin

@external
@nonpayable
def mint(_to: address, _amount: uint256) -> bool:
    assert msg.sender == self.minter or msg.sender == self.admin  # only minter or admin can distribute tokens
    return ERC20(self.token).transfer(_to, _amount)