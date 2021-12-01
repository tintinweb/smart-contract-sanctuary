# @version 0.3.0
"""
@title Anyswap Bridging Contract
@author Curve Finance
@license MIT
"""

interface AnyswapToken:
    def Swapout(_amount: uint256, _receiver: address) -> bool: nonpayable
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

root_receiver: public(address)


@external
def __init__(_admin: address, _receiver: address):
    """
    @param _admin Contract owner. Should be the `PoolProxy` contract
                  used to handle fee burns.
    @param _receiver Receiver address on the root chain.
    """
    self.admin = _admin
    self.root_receiver = _receiver


@external
def bridge(_token: address) -> bool:
    """
    @notice Transfer a token to the root chain via Anyswap.
    """
    assert msg.sender == self.admin

    amount: uint256 = AnyswapToken(_token).balanceOf(self)
    AnyswapToken(_token).Swapout(amount, self.root_receiver)

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


@external
def set_root_receiver(_receiver: address):
    """
    @notice Set the receiver address on the root chain.
    """
    assert msg.sender == self.admin, "Access denied"

    self.root_receiver = _receiver