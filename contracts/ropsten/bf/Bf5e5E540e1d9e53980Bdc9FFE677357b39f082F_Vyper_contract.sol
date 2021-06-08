# @version 0.2.12
from vyper.interfaces import ERC20


admin: public(address)


@external
def __init__():
    self.admin = msg.sender


@external
def set_admin(new_admin: address):
    assert msg.sender == self.admin
    self.admin = new_admin


@external
def recover_ether(recipient: address = msg.sender):
    assert msg.sender == self.admin
    if self.balance != 0:
        raw_call(recipient, b"", value=self.balance)


@external
def recover_erc20(token: address, recipient: address = msg.sender):
    assert msg.sender == self.admin
    token_balance: uint256 = ERC20(token).balanceOf(self)
    if token_balance != 0:
        assert ERC20(token).transfer(recipient, token_balance)