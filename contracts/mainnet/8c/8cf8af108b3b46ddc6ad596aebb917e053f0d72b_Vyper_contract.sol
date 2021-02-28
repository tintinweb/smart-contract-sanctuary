# @version 0.2.8
"""
@title Curve StableSwap Owner Proxy
@author Curve Finance
@license MIT
@notice Allows DAO ownership of `Factory` and it's deployed pools
"""

interface Curve:
    def ramp_A(_future_A: uint256, _future_time: uint256): nonpayable
    def stop_ramp_A(): nonpayable

interface Factory:
    def add_base_pool(
        _base_pool: address,
        _metapool_implementation: address,
        _fee_receiver: address,
    ): nonpayable
    def set_fee_receiver(_base_pool: address, _fee_receiver: address): nonpayable
    def commit_transfer_ownership(addr: address): nonpayable
    def accept_transfer_ownership(): nonpayable


event CommitAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

ownership_admin: public(address)
parameter_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_parameter_admin: public(address)
future_emergency_admin: public(address)


@external
def __init__(
    _ownership_admin: address,
    _parameter_admin: address,
    _emergency_admin: address
):
    self.ownership_admin = _ownership_admin
    self.parameter_admin = _parameter_admin
    self.emergency_admin = _emergency_admin


@external
def commit_set_admins(_o_admin: address, _p_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _p_admin Parameter admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_parameter_admin = _p_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _p_admin, _e_admin)


@external
def apply_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    _o_admin: address = self.future_ownership_admin
    _p_admin: address = self.future_parameter_admin
    _e_admin: address = self.future_emergency_admin
    self.ownership_admin = _o_admin
    self.parameter_admin = _p_admin
    self.emergency_admin = _e_admin

    log ApplyAdmins(_o_admin, _p_admin, _e_admin)


@external
@nonreentrant('lock')
def ramp_A(_pool: address, _future_A: uint256, _future_time: uint256):
    """
    @notice Start gradually increasing A of `_pool` reaching `_future_A` at `_future_time` time
    @param _pool Pool address
    @param _future_A Future A
    @param _future_time Future time
    """
    assert msg.sender == self.parameter_admin, "Access denied"
    Curve(_pool).ramp_A(_future_A, _future_time)


@external
@nonreentrant('lock')
def stop_ramp_A(_pool: address):
    """
    @notice Stop gradually increasing A of `_pool`
    @param _pool Pool address
    """
    assert msg.sender in [self.parameter_admin, self.emergency_admin], "Access denied"
    Curve(_pool).stop_ramp_A()


@external
def add_base_pool(
    _target: address,
    _base_pool: address,
    _metapool_implementation: address,
    _fee_receiver: address
):
    assert msg.sender == self.parameter_admin

    Factory(_target).add_base_pool(_base_pool, _metapool_implementation, _fee_receiver)


@external
def set_fee_receiver(_target: address, _base_pool: address, _fee_receiver: address):
    Factory(_target).set_fee_receiver(_base_pool, _fee_receiver)


@external
def commit_transfer_ownership(_target: address, _new_admin: address):
    """
    @notice Transfer ownership of `_target` to `_new_admin`
    @param _target `Factory` deployment address
    @param _new_admin New admin address
    """
    assert msg.sender == self.parameter_admin  # dev: admin only

    Factory(_target).commit_transfer_ownership(_new_admin)


@external
def accept_transfer_ownership(_target: address):
    """
    @notice Accept a pending ownership transfer
    @param _target `Factory` deployment address
    """
    Factory(_target).accept_transfer_ownership()