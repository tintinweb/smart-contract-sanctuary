# @version 0.2.12
"""
@title HND DAO Token proxy
@author Hundred Finanace
@license MIT
@notice configurable ERC20 with piecewise-linear mining supply.
@dev Based on the ERC-20 token standard as defined at
     https://eips.ethereum.org/EIPS/eip-20
"""

from vyper.interfaces import ERC20


event SetAdmin:
    admin: address

admin: public(address)

first_epoch_time: public(uint256)

epoch_length: public(uint256)

rewards: public(uint256[100000000000000000000000000000])


@external
def __init__(_epoch_length: uint256):
    """
    @notice Contract constructor
    """
    self.admin = msg.sender

    self.epoch_length = _epoch_length
    self.first_epoch_time = block.timestamp / _epoch_length * _epoch_length - _epoch_length


@internal
@view
def _epoch_at(_timestamp: uint256) -> uint256:
    """
    @notice gives epoch number for a given time (0 for first epoch)
    @return uint256 epoch number
    """
    if _timestamp < self.first_epoch_time:
        return 0

    return (_timestamp - self.first_epoch_time) / self.epoch_length


@internal
@view
def _current_epoch() -> uint256:
    """
    @notice gives current reward epoch number (0 for first epoch)
    @return uint256 epoch number
    """
    return self._epoch_at(block.timestamp)


@internal
@view
def _epoch_start_time() -> uint256:
    """
    @notice Get timestamp of the current mining epoch start
    @return Timestamp of the epoch
    """
    return self.first_epoch_time + self._current_epoch() * self.epoch_length


@external
@view
def epoch_at(_timestamp: uint256) -> uint256:
    """
    @notice gives epoch number for a given time (0 for first epoch)
    @return uint256 epoch number
    """
    return self._epoch_at(_timestamp)


@external
@view
def epoch_start_time(_epoch: uint256) -> uint256:
    """
    @notice gives epoch start time for a given epoch number
    @return uint256 epoch timestamp
    """
    return self.first_epoch_time + _epoch * self.epoch_length


@external
@view
def rate_at(_timestamp: uint256) -> uint256:
    """
    @notice give rewards emission rate for timestamp
    @return uint256 epoch rate
    """
    if _timestamp < self.first_epoch_time:
        return 0

    return self.rewards[self._epoch_at(_timestamp)] / self.epoch_length


@external
@view
def current_epoch() -> uint256:
    """
    @notice gives current reward epoch number (0 for first epoch)
    @return uint256 epoch number
    """
    return self._current_epoch()


@external
@view
def future_epoch_time() -> uint256:
    """
    @notice Get timestamp of the next mining epoch start
    @return Timestamp of the next epoch
    """
    return self._epoch_start_time() + self.epoch_length


@external
@view
def future_epoch_rate() -> uint256:
    """
    @notice Get reward rate of the next mining epoch
    @return reward rate
    """
    return self.rewards[self._current_epoch() + 1] / self.epoch_length


@external
def set_admin(_admin: address):
    """
    @notice Set the new admin
    @param _admin New admin address
    """
    assert msg.sender == self.admin  # dev: admin only
    self.admin = _admin
    log SetAdmin(_admin)


@external
def set_rewards_at(_epoch: uint256, _reward: uint256):
    """
    @notice set future epoch reward
    """
    assert msg.sender == self.admin  # dev: admin only
    assert _epoch > self._current_epoch()  # dev: can only modify future rates

    self.rewards[_epoch] = _reward


@external
def set_rewards_starting_at(_epoch: uint256, _rewards: uint256[10]):
    """
    @notice set future rewards starting at epoch _epoch
    """
    assert msg.sender == self.admin  # dev: admin only
    assert _epoch > self._current_epoch()  # dev: can only modify future rewards

    for index in range(10):
        self.rewards[_epoch + index] = _rewards[index]