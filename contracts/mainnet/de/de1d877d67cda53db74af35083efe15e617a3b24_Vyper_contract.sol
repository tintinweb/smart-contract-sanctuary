# @version 0.2.12
"""
@title Root-Chain Gauge
@author Curve Finance
@license MIT
@notice Calculates total allocated weekly CRV emission
        mints and sends across a sidechain bridge
"""

from vyper.interfaces import ERC20


interface CRV20:
    def future_epoch_time_write() -> uint256: nonpayable
    def rate() -> uint256: view

interface Controller:
    def period() -> int128: view
    def period_write() -> int128: nonpayable
    def period_timestamp(p: int128) -> uint256: view
    def gauge_relative_weight(addr: address, time: uint256) -> uint256: view
    def voting_escrow() -> address: view
    def checkpoint(): nonpayable
    def checkpoint_gauge(addr: address): nonpayable

interface Minter:
    def token() -> address: view
    def controller() -> address: view
    def minted(user: address, gauge: address) -> uint256: view
    def mint(gauge: address): nonpayable


event Deposit:
    provider: indexed(address)
    value: uint256

event Withdraw:
    provider: indexed(address)
    value: uint256

event UpdateLiquidityLimit:
    user: address
    original_balance: uint256
    original_supply: uint256
    working_balance: uint256
    working_supply: uint256

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256


WEEK: constant(uint256) = 604800

minter: public(address)
crv_token: public(address)
controller: public(address)
future_epoch_time: public(uint256)

period: public(uint256)
emissions: public(uint256)
inflation_rate: public(uint256)

admin: public(address)
future_admin: public(address)  # Can and will be a smart contract
is_killed: public(bool)

checkpoint_admin: public(address)
anyswap_bridge: public(address)


@external
def __init__(_minter: address, _admin: address, _anyswap_bridge: address):
    """
    @notice Contract constructor
    @param _minter Minter contract address
    @param _admin Admin who can kill the gauge
    @param _anyswap_bridge Address of the AnySwap bridge where CRV is transferred
    """

    crv_token: address = Minter(_minter).token()
    controller: address = Minter(_minter).controller()

    self.minter = _minter
    self.admin = _admin
    self.crv_token = crv_token
    self.controller = controller
    self.anyswap_bridge = _anyswap_bridge

    self.period = block.timestamp / WEEK
    self.inflation_rate = CRV20(crv_token).rate()
    self.future_epoch_time = CRV20(crv_token).future_epoch_time_write()



@external
def checkpoint() -> bool:
    """
    @notice Mint all allocated CRV emissions and transfer across the bridge
    @dev Should be called once per week, after the new epoch period has begun
    """
    assert self.checkpoint_admin in [ZERO_ADDRESS, msg.sender]
    rate: uint256 = self.inflation_rate
    new_rate: uint256 = rate
    prev_future_epoch: uint256 = self.future_epoch_time
    token: address = self.crv_token
    if prev_future_epoch < block.timestamp:
        self.future_epoch_time = CRV20(token).future_epoch_time_write()
        new_rate = CRV20(token).rate()
        self.inflation_rate = new_rate

    last_period: uint256 = self.period
    current_period: uint256 = block.timestamp / WEEK

    if last_period < current_period:
        controller: address = self.controller
        Controller(controller).checkpoint_gauge(self)

        emissions: uint256 = 0
        last_period += 1
        for i in range(last_period, last_period+255):
            if i > current_period:
                break
            week_time: uint256 = i * WEEK
            gauge_weight: uint256 = Controller(controller).gauge_relative_weight(self, i * WEEK)
            emissions += gauge_weight * rate * WEEK / 10**18

            if prev_future_epoch < week_time:
                # If we went across one or multiple epochs, apply the rate
                # of the first epoch until it ends, and then the rate of
                # the last epoch.
                # If more than one epoch is crossed - the gauge gets less,
                # but that'd meen it wasn't called for more than 1 year
                rate = new_rate
                prev_future_epoch = MAX_UINT256

        self.period = current_period
        self.emissions += emissions
        if emissions > 0 and not self.is_killed:
            Minter(self.minter).mint(self)
            ERC20(token).transfer(self.anyswap_bridge, emissions)

    return True


@view
@external
def user_checkpoint(addr: address) -> bool:
    return True


@view
@external
def integrate_fraction(addr: address) -> uint256:
    assert addr == self, "Gauge can only mint for itself"
    return self.emissions


@external
def set_killed(_is_killed: bool):
    """
    @notice Set the killed status for this contract
    @dev When killed, the gauge always yields a rate of 0 and so cannot mint CRV
    @param _is_killed Killed status to set
    """
    assert msg.sender == self.admin  # dev: admin only

    self.is_killed = _is_killed


@external
def commit_transfer_ownership(addr: address):
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = addr
    log CommitOwnership(addr)


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
def set_checkpoint_admin(_admin: address):
    """
    @notice Set the checkpoint admin address
    @dev Setting to ZERO_ADDRESS allows anyone to call `checkpoint`
    @param _admin Address of the checkpoint admin
    """
    assert msg.sender == self.admin  # dev: admin only

    self.checkpoint_admin = _admin