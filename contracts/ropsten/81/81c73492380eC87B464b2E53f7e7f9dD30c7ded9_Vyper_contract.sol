# @version 0.2.12
from vyper.interfaces import ERC20


steth_token: public(address)
ust_token: public(address)
ust_per_steth: public(uint256)

admin: public(address)
steth_vault: public(address)


@external
def __init__(steth_token: address, ust_token: address, steth_vault: address, ust_per_steth: uint256):
    self.admin = msg.sender
    self.steth_token = steth_token
    self.ust_token = ust_token
    self.steth_vault = steth_vault
    self.ust_per_steth = ust_per_steth


@external
def set_admin(new_admin: address):
    assert msg.sender == self.admin
    self.admin = new_admin


@external
def set_rate(ust_per_steth: uint256):
    assert msg.sender == self.admin
    self.ust_per_steth = ust_per_steth


@external
def recover_erc20(token: address, recipient: address = msg.sender):
    assert msg.sender == self.admin
    token_balance: uint256 = ERC20(token).balanceOf(self)
    if token_balance != 0:
        assert ERC20(token).transfer(recipient, token_balance)


@external
def liquidate(ust_recipient: address) -> uint256:
    steth_token: address = self.steth_token
    steth_amount: uint256 = ERC20(steth_token).balanceOf(self)
    ERC20(steth_token).transfer(self.steth_vault, steth_amount)

    ust_amount: uint256 = (steth_amount * self.ust_per_steth) / 10**18
    ERC20(self.ust_token).transfer(ust_recipient, ust_amount)

    return ust_amount