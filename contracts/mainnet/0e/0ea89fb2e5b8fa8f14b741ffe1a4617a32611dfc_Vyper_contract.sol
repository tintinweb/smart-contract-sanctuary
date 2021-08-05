# @version 0.2.15
"""
@title Boost Delegation
@author Curve Finance
@license MIT
@notice Allows delegation of ve- boost within gauges
"""

from vyper.interfaces import ERC20


event NewDelegation:
    delegator: indexed(address)
    gauge: indexed(address)
    receiver: indexed(address)
    pct: uint256
    cancel_time: uint256
    expire_time: uint256

event CancelledDelegation:
    delegator: indexed(address)
    gauge: indexed(address)
    receiver: indexed(address)
    cancelled_by: address


struct ReceivedBoost:
    length: uint256
    data: uint256[10]


admin: public(address)
future_admin: public(address)
is_killed: public(bool)

# user -> number of active boost delegations
delegation_count: public(HashMap[address, uint256])

# user -> gauge -> data on boosts delegated to user
# tightly packed as [address][uint16 pct][uint40 cancel time][uint40 expire time]
delegation_data: HashMap[address, HashMap[address, ReceivedBoost]]

# user -> gauge -> data about delegation user has made for this gauge
delegated_to: HashMap[address, HashMap[address, uint256]]

operator_of: public(HashMap[address, address])

VOTING_ESCROW: constant(address) = 0x4D0518C9136025903751209dDDdf6C67067357b1
MIN_VE: constant(uint256) = 2500 * 10**18


@external
def __init__(_admin: address):
    self.admin = _admin


@view
@external
def get_delegated_to(_delegator: address, _gauge: address) -> (address, uint256, uint256, uint256):
    """
    @notice Get data about an accounts's boost delegation
    @param _delegator Address to query delegation data for
    @param _gauge Gauge address to query. Use ZERO_ADDRESS for global delegation.
    @return address receiving the delegated boost
            delegated boost pct (out of 10000)
            cancellable timestamp
            expiry timestamp
    """
    data: uint256 = self.delegated_to[_delegator][_gauge]
    return (
        convert(shift(data, 96), address),
        shift(data, 80) % 2**16,
        shift(data, 40) % 2**40,
        data % 2**40
    )


@view
@external
def get_delegation_data(
    _receiver: address,
    _gauge: address,
    _idx: uint256
) -> (address, uint256, uint256, uint256):
    """
    @notice Get data delegation toward an account
    @param _receiver Address to query delegation data for
    @param _gauge Gauge address to query. Use ZERO_ADDRESS for global delegation.
    @param _idx Data index. Each account can receive a max of 10 delegations per pool.
    @return address of the delegator
            delegated boost pct (out of 10000)
            cancellable timestamp
            expiry timestamp
    """
    data: uint256 = self.delegation_data[_receiver][_gauge].data[_idx]
    return (
        convert(shift(data, 96), address),
        shift(data, 80) % 2**16,
        shift(data, 40) % 2**40,
        data % 2**40
    )


@external
def set_operator(_operator: address) -> bool:
    """
    @notice Set the authorized operator for an address
    @dev An operator can delegate boost, including creating delegations that
         cannot be cancelled. This permission should only be given to trusted
         3rd parties and smart contracts where the contract behavior is known
         to be not malicious.
    @param _operator Approved operator address. Set to `ZERO_ADDRESS` to revoke
                     the currently active approval.
    @return bool success
    """
    self.operator_of[msg.sender] = _operator
    return True


@internal
def _delete_delegation_data(_delegator: address, _gauge: address, _delegation_data: uint256):
    # delete record for the delegator
    self.delegated_to[_delegator][_gauge] = 0
    self.delegation_count[_delegator] -= 1

    receiver: address = convert(shift(_delegation_data, 96), address)
    length: uint256 = self.delegation_data[receiver][_gauge].length

    # delete record for the receiver
    for i in range(10):
        if i == length - 1:
            self.delegation_data[receiver][_gauge].data[i] = 0
            break
        if self.delegation_data[receiver][_gauge].data[i] == _delegation_data:
            self.delegation_data[receiver][_gauge].data[i] = self.delegation_data[receiver][_gauge].data[length-1]
            self.delegation_data[receiver][_gauge].data[length-1] = 0


@external
def delegate_boost(
    _delegator: address,
    _gauge: address,
    _receiver: address,
    _pct: uint256,
    _cancel_time: uint256,
    _expire_time: uint256
) -> bool:
    """
    @notice Delegate per-gauge or global boost to another account
    @param _delegator Address of the user delegating boost. The caller must be the
                      delegator or the approved operator of the delegator.
    @param _gauge Address of the gauge to delegate for. Set as ZERO_ADDRESS for
                  global delegation. Global delegation is not possible if there is
                  also one or more active per-gauge delegations.
    @param _receiver Address to delegate boost to.
    @param _pct Percentage of boost to delegate. 100% is expressed as 10000.
    @param _cancel_time Delegation cannot be cancelled before this time.
    @param _expire_time Delegation automatically expires at this time.
    @return bool success
    """
    assert not self.is_killed, "Is killed"
    assert msg.sender in [_delegator, self.operator_of[_delegator]], "Only owner or operator"

    assert _delegator != _receiver, "Cannot delegate to self"
    assert _pct >= 100, "Percent too low"
    assert _pct <= 10000, "Percent too high"
    assert _expire_time < 2**40, "Expiry time too high"
    assert _expire_time > block.timestamp, "Already expired"
    assert _cancel_time <= _expire_time, "Cancel time after expiry time"

    # check for minimum ve- balance, used to prevent 0 ve- delegation spam
    assert ERC20(VOTING_ESCROW).balanceOf(_delegator) >= MIN_VE, "Insufficient ve- to delegate"

    # check for an existing, expired delegation
    data: uint256 = self.delegated_to[_delegator][_gauge]
    if data != 0:
        assert data % 2**40 <= block.timestamp, "Existing delegation has not expired"
        self._delete_delegation_data(_delegator, _gauge, data)

    if _gauge == ZERO_ADDRESS:
        assert self.delegation_count[_delegator] == 0, "Cannot delegate globally while per-gauge is active"
    else:
        assert self.delegated_to[_delegator][ZERO_ADDRESS] == 0, "Cannot delegate per-gauge while global is active"

    # tightly pack the delegation data
    # [address][uint16 pct][uint40 cancel time][uint40 expire time]
    data = shift(_pct, -80) + shift(_cancel_time, -40) + _expire_time
    idx: uint256 = self.delegation_data[_receiver][_gauge].length

    self.delegation_data[_receiver][_gauge].data[idx] = data + shift(convert(_delegator, uint256), -96)
    self.delegated_to[_delegator][_gauge] = data + shift(convert(_receiver, uint256), -96)
    self.delegation_data[_receiver][_gauge].length = idx + 1

    log NewDelegation(_delegator, _gauge, _receiver, _pct, _cancel_time, _expire_time)
    return True


@external
def cancel_delegation(_delegator: address, _gauge: address) -> bool:
    """
    @notice Cancel an existing boost delegation
    @param _delegator Address of the user delegating boost. The caller can be the
                      delegator, the receiver, the approved operator of the delegator
                      or receiver. The delegator can cancel after the cancel time
                      has passed, the receiver can cancel at any time.
    @param _gauge Address of the gauge to cancel delegattion for. Set as ZERO_ADDRESS
                  for global delegation.
    @return bool success
    """
    data: uint256 = self.delegated_to[_delegator][_gauge]
    assert data != 0, "No delegation for this pool"

    receiver: address = convert(shift(data, 96), address)
    if msg.sender not in [receiver, self.operator_of[receiver]]:
        assert msg.sender in [receiver, self.operator_of[receiver]], "Only owner or operator"
        assert shift(data, 40) % 2**40 <= block.timestamp, "Not yet cancellable"

    self._delete_delegation_data(_delegator, _gauge, data)

    log CancelledDelegation(_delegator, _gauge, receiver, msg.sender)
    return True


@view
@external
def get_adjusted_ve_balance(_user: address, _gauge: address) -> uint256:
    """
    @notice Get the adjusted ve- balance of an account after delegation
    @param _user Address to query a ve- balance for
    @param _gauge Gauge address
    @return Adjusted ve- balance after delegation
    """
    # query the initial ve balance for `_user`
    voting_balance: uint256 = ERC20(VOTING_ESCROW).balanceOf(_user)

    # if the contract has been killed, return ve- without applying any delegation
    if self.is_killed:
        return voting_balance

    # check if the user has delegated any ve and reduce the voting balance
    delegation_count: uint256 = self.delegation_count[_user]
    if delegation_count != 0:
        is_global: bool = False
        # apply global delegation
        if delegation_count == 1:
            data: uint256 = self.delegated_to[_user][ZERO_ADDRESS]
            if data % 2**40 > block.timestamp:
                voting_balance = voting_balance * (10000 - shift(data, 80) % 2**16) / 10000
                is_global = True
        # apply pool-specific delegation
        if not is_global:
            data: uint256 = self.delegated_to[_user][_gauge]
            if data % 2**40 > block.timestamp:
                voting_balance = voting_balance * (10000 - shift(data, 80) % 2**16) / 10000

    # check for other ve delegated to `_user` and increase the voting balance
    for target in [_gauge, ZERO_ADDRESS]:
        length: uint256 = self.delegation_data[_user][target].length
        if length > 0:
            for i in range(10):
                if i == length:
                    break
                data: uint256 = self.delegation_data[_user][target].data[i]
                if data % 2**40 > block.timestamp:
                    delegator: address = convert(shift(data, 96), address)
                    delegator_balance: uint256 = ERC20(VOTING_ESCROW).balanceOf(delegator)
                    voting_balance += delegator_balance * (shift(data, 80) % 2**16) / 10000

    return voting_balance


@external
def update_delegation_records(_user: address, _gauge: address) -> bool:
    """
    @notice Remove data about any expired delegations for a user.
    @dev Reduces gas costs when calling `get_adjusted_ve_balance` on
         an address with expired delegations.
    @param _user Address to update records for.
    @param _gauge Gauge address. Use `ZERO_ADDRESS` for global delegations.
    """
    length: uint256 = self.delegation_data[_user][_gauge].length - 1
    adjusted_length: uint256 = length

    # iterate in reverse over `delegation_data` and remove expired records
    for i in range(10):
        if i > length:
            break
        idx: uint256 = length - i
        data: uint256 = self.delegation_data[_user][_gauge].data[idx]
        if data % 2**40 <= block.timestamp:
            # delete record for the delegator
            delegator: address = convert(shift(data, 96), address)
            self.delegated_to[delegator][_gauge] = 0
            self.delegation_count[delegator] -= 1

            # delete record for the receiver
            if idx == adjusted_length:
                self.delegation_data[_user][_gauge].data[idx] = 0
            else:
                self.delegation_data[_user][_gauge].data[idx] = self.delegation_data[_user][_gauge].data[adjusted_length]
            adjusted_length -= 1

    return True


@external
def set_killed(_is_killed: bool):
    """
    @notice Set the killed status for this contract
    @dev When killed, all delegation is disabled
    @param _is_killed Killed status to set
    """
    assert msg.sender == self.admin  # dev: only owner

    self.is_killed = _is_killed


@external
def commit_transfer_ownership(_addr: address):
    """
    @notice Transfer ownership of this contract to `addr`
    @param _addr Address of the new owner
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = _addr


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    @dev Only callable by the new owner
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    self.future_admin = ZERO_ADDRESS