# @version 0.3.0
"""
@title Polygon Bridging Contract
@author Curve Finance
@license MIT
"""


interface BridgeToken:
    def withdraw(_amount: uint256): nonpayable
    def balanceOf(_user: address) -> uint256: view


event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event AssetBridged:
    token: address
    amount: uint256


admin: public(address)
future_admin: public(address)


@external
def __init__(_admin: address):
    """
    @param _admin Contract owner. Should be the `PoolProxy` contract
                  used to handle fee burns.
    """
    self.admin = _admin


@external
def bridge(_token: address) -> bool:
    """
    @notice Transfer a token to the root chain via Anyswap.
    """
    assert msg.sender == self.admin

    amount: uint256 = BridgeToken(_token).balanceOf(self)
    BridgeToken(_token).withdraw(amount)

    log AssetBridged(_token, amount)
    return True


@external
def commit_transfer_ownership(_addr: address):
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param _addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = _addr
    log CommitOwnership(_addr)


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    log ApplyOwnership(_admin)