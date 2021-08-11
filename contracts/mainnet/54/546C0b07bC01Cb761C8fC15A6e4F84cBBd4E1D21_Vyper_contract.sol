# @version 0.2.12

"""
@title Unagii ZapEth 0.1.1
@author stakewith.us
@license AGPL-3.0-or-later
"""


from vyper.interfaces import ERC20


interface EthVaultV1:
    def token() -> address: view
    def withdraw(shares: uint256, _min: uint256): nonpayable
    # VaultV1 is ERC20
    def transferFrom(_from: address, _to: address, amount: uint256) -> bool: nonpayable


interface EthVaultV2:
    def token() -> address: view
    def uToken() -> address: view
    # BUG: amount fixed
    def deposit(amount: uint256, _min: uint256) -> uint256: payable


v1: public(EthVaultV1)
v2: public(EthVaultV2)
ETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
uToken: public(ERC20)


@external
def __init__(v1: address, v2: address, uToken: address):
    self.v1 = EthVaultV1(v1)
    self.v2 = EthVaultV1(v2)

    assert self.v1.token() == ETH, "v1 token != ETH"
    assert self.v2.token() == ETH, "v2 token != ETH"

    assert uToken == self.v2.uToken(), "uToken != v2 uToken"
    self.uToken = ERC20(self.v2.uToken())


@external
def __default__():
    # only allow ETH from v1 vault
    assert msg.sender == self.v1.address, "!v1 vault"


@external
def zap(shares: uint256, _min: uint256, _minV2Shares: uint256):
    assert self.v1.transferFrom(msg.sender, self, shares), "transfer failed"
    self.v1.withdraw(shares, _min)

    uShares: uint256 = self.v2.deposit(self.balance, _minV2Shares, value=self.balance)
    self.uToken.transfer(msg.sender, uShares)