# @version 0.3.1
"""
@title Token Minter
@author Curve Finance
@license MIT
"""

interface LiquidityGauge:
    # Presumably, other gauges will provide the same interfaces
    def integrate_fraction(addr: address) -> uint256: view
    def user_checkpoint(addr: address) -> bool: nonpayable

interface ERC20:
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def balanceOf(account: address) -> uint256: nonpayable

interface GaugeController:
    def gauge_types(addr: address) -> int128: view

event Minted:
    recipient: indexed(address)
    gauge: address
    minted: uint256

event UpdateMiningParameters:
    time: uint256
    rate: uint256

event CommitNextEmission:
    rate: uint256

event CommitEmergencyReturn:
    admin: address

event ApplyEmergencyReturn:
    admin: address

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

# General constants
WEEK: constant(uint256) = 86400 * 7

# 250K RBN / WEEK
INITIAL_RATE: constant(uint256) = 250_000 * 10 ** 18 / WEEK
# Weekly
MAX_ABS_RATE: constant(uint256) = 10_000_000 * 10 ** 18
RATE_REDUCTION_TIME: constant(uint256) = WEEK * 2
INFLATION_DELAY: constant(uint256) = 86400

mining_epoch: public(int128)
start_epoch_time: public(uint256)
rate: public(uint256)
committed_rate: public(uint256)
is_start: public(bool)

token: public(address)
controller: public(address)

# user -> gauge -> value
minted: public(HashMap[address, HashMap[address, uint256]])

# minter -> user -> can mint?
allowed_to_mint_for: public(HashMap[address, HashMap[address, bool]])

future_emergency_return: public(address)
emergency_return: public(address)
admin: public(address)  # Can and will be a smart contract
future_admin: public(address)  # Can and will be a smart contract

@external
def __init__(_token: address, _controller: address, _emergency_return: address, _admin: address):
    self.token = _token
    self.controller = _controller
    self.emergency_return = _emergency_return
    self.admin = _admin

    self.start_epoch_time = block.timestamp + INFLATION_DELAY - RATE_REDUCTION_TIME
    self.mining_epoch = -1
    self.is_start = True
    self.committed_rate = MAX_UINT256


@internal
def _update_mining_parameters():
    """
    @dev Update mining rate and supply at the start of the epoch
         Any modifying mining call must also call this
    """
    _rate: uint256 = self.rate

    self.start_epoch_time += RATE_REDUCTION_TIME
    self.mining_epoch += 1

    if _rate == 0 and self.is_start:
        _rate = INITIAL_RATE
        self.is_start = False
    else:
        _committed_rate: uint256 = self.committed_rate
        if _committed_rate != MAX_UINT256:
          _rate = _committed_rate
          self.committed_rate = MAX_UINT256

    self.rate = _rate

    log UpdateMiningParameters(block.timestamp, _rate)

@external
def update_mining_parameters():
    """
    @notice Update mining rate and supply at the start of the epoch
    @dev Callable by any address, but only once per epoch
         Total supply becomes slightly larger if this function is called late
    """
    assert block.timestamp >= self.start_epoch_time + RATE_REDUCTION_TIME  # dev: too soon!
    self._update_mining_parameters()

@external
def start_epoch_time_write() -> uint256:
    """
    @notice Get timestamp of the current mining epoch start
            while simultaneously updating mining parameters
    @return Timestamp of the epoch
    """
    _start_epoch_time: uint256 = self.start_epoch_time
    if block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME:
        self._update_mining_parameters()
        return self.start_epoch_time
    else:
        return _start_epoch_time

@external
def future_epoch_time_write() -> uint256:
    """
    @notice Get timestamp of the next mining epoch start
            while simultaneously updating mining parameters
    @return Timestamp of the next epoch
    """
    _start_epoch_time: uint256 = self.start_epoch_time
    if block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME:
        self._update_mining_parameters()
        return self.start_epoch_time + RATE_REDUCTION_TIME
    else:
        return _start_epoch_time + RATE_REDUCTION_TIME

@internal
def _mint_for(gauge_addr: address, _for: address):
    assert GaugeController(self.controller).gauge_types(gauge_addr) >= 0  # dev: gauge is not added

    LiquidityGauge(gauge_addr).user_checkpoint(_for)
    total_mint: uint256 = LiquidityGauge(gauge_addr).integrate_fraction(_for)
    to_mint: uint256 = total_mint - self.minted[_for][gauge_addr]

    if to_mint != 0:
        ERC20(self.token).transfer(_for, to_mint)
        if block.timestamp >= self.start_epoch_time + RATE_REDUCTION_TIME:
          self._update_mining_parameters()
        self.minted[_for][gauge_addr] = total_mint

        log Minted(_for, gauge_addr, total_mint)


@external
@nonreentrant('lock')
def mint(gauge_addr: address):
    """
    @notice Mint everything which belongs to `msg.sender` and send to them
    @param gauge_addr `LiquidityGauge` address to get mintable amount from
    """
    self._mint_for(gauge_addr, msg.sender)


@external
@nonreentrant('lock')
def mint_many(gauge_addrs: address[8]):
    """
    @notice Mint everything which belongs to `msg.sender` across multiple gauges
    @param gauge_addrs List of `LiquidityGauge` addresses
    """
    for i in range(8):
        if gauge_addrs[i] == ZERO_ADDRESS:
            break
        self._mint_for(gauge_addrs[i], msg.sender)


@external
@nonreentrant('lock')
def mint_for(gauge_addr: address, _for: address):
    """
    @notice Mint tokens for `_for`
    @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
    @param gauge_addr `LiquidityGauge` address to get mintable amount from
    @param _for Address to mint to
    """
    if self.allowed_to_mint_for[msg.sender][_for]:
        self._mint_for(gauge_addr, _for)


@external
def toggle_approve_mint(minting_user: address):
    """
    @notice allow `minting_user` to mint for `msg.sender`
    @param minting_user Address to toggle permission for
    """
    self.allowed_to_mint_for[minting_user][msg.sender] = not self.allowed_to_mint_for[minting_user][msg.sender]

@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the emergency return address.
    @param _coin Token address
    @return bool success
    """
    assert msg.sender == self.admin # dev: admin only

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(self.emergency_return, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True

@external
def commit_next_emission(_rate_per_week: uint256):
  """
  @notice Commit a new rate for the following week (we update by weeks).
          _rate_per_week should have no decimals (ex: if we want to reward 600_000 RBN over the course of a week, we pass in 600_000 * 10 ** 18)
  """
  assert msg.sender == self.admin # dev: admin only
  assert _rate_per_week <= MAX_ABS_RATE # dev: preventing fatfinger
  new_rate: uint256 = _rate_per_week / WEEK
  self.committed_rate = new_rate
  log CommitNextEmission(new_rate)

@external
def commit_transfer_emergency_return(addr: address):
    """
    @notice Update emergency ret. of Minter to `addr`
    @param addr Address to have emergency ret. transferred to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_emergency_return = addr
    log CommitEmergencyReturn(addr)

@external
def apply_transfer_emergency_return():
    """
    @notice Apply pending emergency ret. update
    """
    assert msg.sender == self.admin  # dev: admin only
    _emergency_return: address = self.future_emergency_return
    assert _emergency_return != ZERO_ADDRESS  # dev: emergency return not set
    self.emergency_return = _emergency_return
    log ApplyEmergencyReturn(_emergency_return)

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
def apply_transfer_ownership():
    """
    @notice Apply pending ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _admin: address = self.future_admin
    assert _admin != ZERO_ADDRESS  # dev: admin not set
    self.admin = _admin
    log ApplyOwnership(_admin)