# @version 0.3.0
"""
@title Curve Factory Owner Proxy
@author Curve Finance
@license MIT
@notice Allows DAO ownership of `Factory` and it's deployed pools
"""

interface Curve:
    def ramp_A(_future_A: uint256, _future_time: uint256): nonpayable
    def stop_ramp_A(): nonpayable

interface Gauge:
    def set_killed(_is_killed: bool): nonpayable
    def add_reward(_reward_token: address, _distributor: address): nonpayable
    def set_reward_distributor(_reward_token: address, _distributor: address): nonpayable

interface Factory:
    def add_base_pool(
        _base_pool: address,
        _fee_receiver: address,
        _asset_type: uint256,
        _implementations: address[10],
    ): nonpayable
    def set_metapool_implementations(
        _base_pool: address,
        _implementations: address[10],
    ): nonpayable
    def set_plain_implementations(
        _n_coins: uint256,
        _implementations: address[10],
    ): nonpayable
    def set_gauge_implementation(_gauge_implementation: address): nonpayable
    def set_fee_receiver(_base_pool: address, _fee_receiver: address): nonpayable
    def commit_transfer_ownership(addr: address): nonpayable
    def accept_transfer_ownership(): nonpayable
    def set_manager(_manager: address): nonpayable


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

gauge_manager: public(address)


@external
def __init__(
    _ownership_admin: address,
    _parameter_admin: address,
    _emergency_admin: address,
    _gauge_manager: address
):
    self.ownership_admin = _ownership_admin
    self.parameter_admin = _parameter_admin
    self.emergency_admin = _emergency_admin
    self.gauge_manager = _gauge_manager


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
    _fee_receiver: address,
    _asset_type: uint256,
    _implementations: address[10],
):
    assert msg.sender == self.ownership_admin, "Access denied"

    Factory(_target).add_base_pool(_base_pool, _fee_receiver, _asset_type, _implementations)


@external
def set_metapool_implementations(
    _target: address,
    _base_pool: address,
    _implementations: address[10],
):
    """
    @notice Set implementation contracts for a metapool
    @dev Only callable by admin
    @param _base_pool Pool address to add
    @param _implementations Implementation address to use when deploying metapools
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_metapool_implementations(_base_pool, _implementations)


@external
def set_plain_implementations(
    _target: address,
    _n_coins: uint256,
    _implementations: address[10],
):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_plain_implementations(_n_coins, _implementations)


@external
def set_gauge_implementation(_target: address, _gauge_implementation: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_gauge_implementation(_gauge_implementation)


@external
def set_fee_receiver(_target: address, _base_pool: address, _fee_receiver: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_fee_receiver(_base_pool, _fee_receiver)


@external
def set_factory_manager(_target: address, _manager: address):
    assert msg.sender in [self.ownership_admin, self.emergency_admin], "Access denied"
    Factory(_target).set_manager(_manager)


@external
def set_gauge_manager(_manager: address):
    """
    @notice Set the manager
    @dev Callable by the admin or existing manager
    @param _manager Manager address
    """
    assert msg.sender in [self.ownership_admin, self.emergency_admin, self.gauge_manager], "Access denied"

    self.gauge_manager = _manager


@external
def commit_transfer_ownership(_target: address, _new_admin: address):
    """
    @notice Transfer ownership of `_target` to `_new_admin`
    @param _target `Factory` deployment address
    @param _new_admin New admin address
    """
    assert msg.sender == self.ownership_admin  # dev: admin only

    Factory(_target).commit_transfer_ownership(_new_admin)


@external
def accept_transfer_ownership(_target: address):
    """
    @notice Accept a pending ownership transfer
    @param _target `Factory` deployment address
    """
    Factory(_target).accept_transfer_ownership()


@external
def set_killed(_gauge: address, _is_killed: bool):
    assert msg.sender in [self.ownership_admin, self.emergency_admin]
    Gauge(_gauge).set_killed(_is_killed)


@external
def add_reward(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender in [self.ownership_admin, self.gauge_manager]
    Gauge(_gauge).add_reward(_reward_token, _distributor)


@external
def set_reward_distributor(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender in [self.ownership_admin, self.gauge_manager]
    Gauge(_gauge).set_reward_distributor(_reward_token, _distributor)