# @version 0.2.4
"""
@title Vesting Escrow
@author Curve Finance
@license MIT
@notice Vests `ERC20CRV` tokens for multiple addresses over multiple vesting periods
"""


from vyper.interfaces import ERC20

event Fund:
    recipient: indexed(address)
    amount: uint256

event Claim:
    recipient: indexed(address)
    claimed: uint256

event ToggleDisable:
    recipient: address
    disabled: bool

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address


token: public(address)
start_time: public(uint256)
end_time: public(uint256)
initial_locked: public(HashMap[address, uint256])
total_claimed: public(HashMap[address, uint256])

initial_locked_supply: public(uint256)
unallocated_supply: public(uint256)

can_disable: public(bool)
disabled_at: public(HashMap[address, uint256])

admin: public(address)
future_admin: public(address)

fund_admins_enabled: public(bool)
fund_admins: public(HashMap[address, bool])


@external
def __init__(
    _token: address,
    _start_time: uint256,
    _end_time: uint256,
    _can_disable: bool,
    _fund_admins: address[4]
):
    """
    @param _token Address of the ERC20 token being distributed
    @param _start_time Timestamp at which the distribution starts. Should be in
        the future, so that we have enough time to VoteLock everyone
    @param _end_time Time until everything should be vested
    @param _can_disable Whether admin can disable accounts in this deployment
    @param _fund_admins Temporary admin accounts used only for funding
    """
    assert _start_time >= block.timestamp
    assert _end_time > _start_time

    self.token = _token
    self.admin = msg.sender
    self.start_time = _start_time
    self.end_time = _end_time
    self.can_disable = _can_disable

    _fund_admins_enabled: bool = False
    for addr in _fund_admins:
        if addr != ZERO_ADDRESS:
            self.fund_admins[addr] = True
            if not _fund_admins_enabled:
                _fund_admins_enabled = True
                self.fund_admins_enabled = True



@external
def add_tokens(_amount: uint256):
    """
    @notice Transfer vestable tokens into the contract
    @dev Handled separate from `fund` to reduce transaction count when using funding admins
    @param _amount Number of tokens to transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    assert ERC20(self.token).transferFrom(msg.sender, self, _amount)  # dev: transfer failed
    self.unallocated_supply += _amount


@external
@nonreentrant('lock')
def fund(_recipients: address[100], _amounts: uint256[100]):
    """
    @notice Vest tokens for multiple recipients
    @param _recipients List of addresses to fund
    @param _amounts Amount of vested tokens for each address
    """
    if msg.sender != self.admin:
        assert self.fund_admins[msg.sender]  # dev: admin only
        assert self.fund_admins_enabled  # dev: fund admins disabled

    _total_amount: uint256 = 0
    for i in range(100):
        amount: uint256 = _amounts[i]
        recipient: address = _recipients[i]
        if recipient == ZERO_ADDRESS:
            break
        _total_amount += amount
        self.initial_locked[recipient] += amount
        log Fund(recipient, amount)

    self.initial_locked_supply += _total_amount
    self.unallocated_supply -= _total_amount


@external
def toggle_disable(_recipient: address):
    """
    @notice Disable or re-enable a vested address's ability to claim tokens
    @dev When disabled, the address is only unable to claim tokens which are still
         locked at the time of this call. It is not possible to block the claim
         of tokens which have already vested.
    @param _recipient Address to disable or enable
    """
    assert msg.sender == self.admin  # dev: admin only
    assert self.can_disable, "Cannot disable"

    is_disabled: bool = self.disabled_at[_recipient] == 0
    if is_disabled:
        self.disabled_at[_recipient] = block.timestamp
    else:
        self.disabled_at[_recipient] = 0

    log ToggleDisable(_recipient, is_disabled)


@external
def disable_can_disable():
    """
    @notice Disable the ability to call `toggle_disable`
    """
    assert msg.sender == self.admin  # dev: admin only
    self.can_disable = False


@external
def disable_fund_admins():
    """
    @notice Disable the funding admin accounts
    """
    assert msg.sender == self.admin  # dev: admin only
    self.fund_admins_enabled = False


@internal
@view
def _total_vested_of(_recipient: address, _time: uint256 = block.timestamp) -> uint256:
    start: uint256 = self.start_time
    end: uint256 = self.end_time
    locked: uint256 = self.initial_locked[_recipient]
    if _time < start:
        return 0
    return min(locked * (_time - start) / (end - start), locked)


@internal
@view
def _total_vested() -> uint256:
    start: uint256 = self.start_time
    end: uint256 = self.end_time
    locked: uint256 = self.initial_locked_supply
    if block.timestamp < start:
        return 0
    return min(locked * (block.timestamp - start) / (end - start), locked)


@external
@view
def vestedSupply() -> uint256:
    """
    @notice Get the total number of tokens which have vested, that are held
            by this contract
    """
    return self._total_vested()


@external
@view
def lockedSupply() -> uint256:
    """
    @notice Get the total number of tokens which are still locked
            (have not yet vested)
    """
    return self.initial_locked_supply - self._total_vested()


@external
@view
def vestedOf(_recipient: address) -> uint256:
    """
    @notice Get the number of tokens which have vested for a given address
    @param _recipient address to check
    """
    return self._total_vested_of(_recipient)


@external
@view
def balanceOf(_recipient: address) -> uint256:
    """
    @notice Get the number of unclaimed, vested tokens for a given address
    @param _recipient address to check
    """
    return self._total_vested_of(_recipient) - self.total_claimed[_recipient]


@external
@view
def lockedOf(_recipient: address) -> uint256:
    """
    @notice Get the number of locked tokens for a given address
    @param _recipient address to check
    """
    return self.initial_locked[_recipient] - self._total_vested_of(_recipient)


@external
@nonreentrant('lock')
def claim(addr: address = msg.sender):
    """
    @notice Claim tokens which have vested
    @param addr Address to claim tokens for
    """
    t: uint256 = self.disabled_at[addr]
    if t == 0:
        t = block.timestamp
    claimable: uint256 = self._total_vested_of(addr, t) - self.total_claimed[addr]
    self.total_claimed[addr] += claimable
    assert ERC20(self.token).transfer(addr, claimable)

    log Claim(addr, claimable)


@external
def commit_transfer_ownership(addr: address) -> bool:
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_admin = addr
    log CommitOwnership(addr)

    return True


@external
def apply_transfer_ownership() -> bool:
    """
    @notice Apply pending ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _admin: address = self.future_admin
    assert _admin != ZERO_ADDRESS  # dev: admin not set
    self.admin = _admin
    log ApplyOwnership(_admin)

    return True