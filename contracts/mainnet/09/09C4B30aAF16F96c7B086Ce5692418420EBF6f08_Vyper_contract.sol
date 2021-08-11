# @version 0.2.12

"""
@title Unagii Zap 0.1.1
@author stakewith.us
@license AGPL-3.0-or-later
"""

from vyper.interfaces import ERC20


interface VaultV1:
    def token() -> address: view
    def withdraw(shares: uint256, _min: uint256): nonpayable
    # VaultV1 is ERC20
    def transferFrom(_from: address, _to: address, amount: uint256) -> bool: nonpayable


interface VaultV2:
    def token() -> address: view
    def uToken() -> address: view
    def deposit(amount: uint256, _min: uint256) -> uint256: nonpayable


v1: public(VaultV1)
v2: public(VaultV2)
token: public(ERC20)
uToken: public(ERC20)


@external
def __init__(v1: address, v2: address, uToken: address):
    self.v1 = VaultV1(v1)
    self.v2 = VaultV1(v2)

    assert self.v1.token() == self.v2.token(), "v1 token != v2 token"
    self.token = ERC20(self.v1.token())

    assert uToken == self.v2.uToken(), "uToken != v2 uToken"
    self.uToken = ERC20(self.v2.uToken())


@internal
def _safeApprove(token: address, spender: address, amount: uint256):
    res: Bytes[32] = raw_call(
        token,
        concat(
            method_id("approve(address,uint256)"),
            convert(spender, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(res) > 0:
        assert convert(res, bool), "approve failed"


@external
def zap(shares: uint256, _min: uint256, _minV2Shares: uint256):
    assert self.v1.transferFrom(msg.sender, self, shares), "transfer failed"
    self.v1.withdraw(shares, _min)

    bal: uint256 = self.token.balanceOf(self)
    # use _safeApprove, USDT does not return bool
    self._safeApprove(self.token.address, self.v2.address, bal)
    uShares: uint256 = self.v2.deposit(bal, _minV2Shares)
    self.uToken.transfer(msg.sender, uShares)