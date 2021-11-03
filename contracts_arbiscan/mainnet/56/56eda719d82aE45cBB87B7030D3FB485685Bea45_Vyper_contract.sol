# @version 0.2.12
"""
@title Child-Chain Streamer
@author Curve.Fi
@license MIT
@notice Evenly streams one or more reward tokens to a single recipient
"""

from vyper.interfaces import ERC20

struct RewardToken:
    distributor: address
    period_finish: uint256
    rate: uint256
    duration: uint256
    received: uint256
    paid: uint256


owner: public(address)
future_owner: public(address)

reward_receiver: public(address)
reward_tokens: public(address[8])
reward_count: public(uint256)
reward_data: public(HashMap[address, RewardToken])
last_update_time: public(uint256)


@external
def __init__(_owner: address, _receiver: address, _reward: address):
    self.owner = _owner
    self.reward_receiver = _receiver

    self.reward_tokens[0] = _reward
    self.reward_count = 1
    self.reward_data[_reward].distributor = _owner
    self.reward_data[_reward].duration = 86400 * 7


@external
def add_reward(_token: address, _distributor: address, _duration: uint256):
    """
    @notice Add a reward token
    @param _token Address of the reward token
    @param _distributor Address permitted to call `notify_reward_amount` for this token
    @param _duration Number of seconds that rewards of this token are streamed over
    """
    assert msg.sender == self.owner  # dev: owner only
    assert self.reward_data[_token].distributor == ZERO_ADDRESS, "Reward token already added"

    idx: uint256 = self.reward_count
    self.reward_tokens[idx] = _token
    self.reward_count = idx + 1
    self.reward_data[_token].distributor = _distributor
    self.reward_data[_token].duration = _duration


@external
def remove_reward(_token: address):
    """
    @notice Remove a reward token
    @dev Any remaining balance of the reward token is transferred to the owner
    @param _token Address of the reward token
    """
    assert msg.sender == self.owner  # dev: only owner
    assert self.reward_data[_token].distributor != ZERO_ADDRESS, "Reward token not added"

    self.reward_data[_token] = empty(RewardToken)
    amount: uint256 = ERC20(_token).balanceOf(self)
    response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(msg.sender, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    idx: uint256 = self.reward_count - 1
    for i in range(8):
        if self.reward_tokens[i] == _token:
            self.reward_tokens[i] = self.reward_tokens[idx]
            self.reward_tokens[idx] = ZERO_ADDRESS
            self.reward_count = idx
            return
    raise  # this should never be reached


@internal
def _update_reward(_token: address, _last_update: uint256):
    # update data about a reward and distribute any pending tokens to the receiver
    last_time: uint256 = min(block.timestamp, self.reward_data[_token].period_finish)
    if last_time > _last_update:
        amount: uint256 = (last_time - _last_update) * self.reward_data[_token].rate
        if amount > 0:
            self.reward_data[_token].paid += amount
            response: Bytes[32] = raw_call(
                _token,
                concat(
                    method_id("transfer(address,uint256)"),
                    convert(self.reward_receiver, bytes32),
                    convert(amount, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)


@external
def set_receiver(_receiver: address):
    """
    @notice Set the reward receiver
    @dev When the receiver is a smart contract, it must be capable of recognizing
         rewards that are directly pushed to it (without a call to `get_reward`)
    @param _receiver Address of the reward receiver
    """
    assert msg.sender == self.owner  # dev: only owner
    self.reward_receiver = _receiver


@external
def get_reward():
    """
    @notice Claim pending rewards for `reward_receiver`
    """
    last_update: uint256 = self.last_update_time
    for token in self.reward_tokens:
        if token == ZERO_ADDRESS:
            break
        self._update_reward(token, last_update)
    self.last_update_time = block.timestamp


@external
def notify_reward_amount(_token: address):
    """
    @notice Notify the contract of a newly received reward
    @dev Only callable by the distributor if there is an active reward period.
         The reward tokens must be transferred into the contract prior to calling
         this function. Rewards are distributed over `reward_duration` seconds.
         Updating the reward amount while an existing reward period is still active
         causes the remaining rewards to be evenly distributed over the new period.
    @param _token Address of the reward token
    """
    last_update: uint256 = self.last_update_time
    is_updated: bool = False
    for token in self.reward_tokens:
        if token == ZERO_ADDRESS:
            break

        self._update_reward(token, last_update)
        if token == _token:
            received: uint256 = self.reward_data[token].received
            expected_balance: uint256 = received - self.reward_data[token].paid
            actual_balance: uint256 = ERC20(token).balanceOf(self)

            if actual_balance > expected_balance:
                new_amount: uint256 = actual_balance - expected_balance
                duration: uint256 = self.reward_data[token].duration

                if block.timestamp >= self.reward_data[token].period_finish:
                    self.reward_data[token].rate = new_amount / duration
                else:
                    assert msg.sender == self.reward_data[_token].distributor, "Reward period still active"
                    remaining: uint256 = self.reward_data[token].period_finish - block.timestamp
                    leftover: uint256 = remaining * self.reward_data[token].rate
                    self.reward_data[token].rate = (new_amount + leftover) / duration

                self.reward_data[token].period_finish = block.timestamp + duration
                self.reward_data[token].received = received + new_amount
                is_updated = True

    assert is_updated, "Invalid token or no new reward"
    self.last_update_time = block.timestamp


@external
def set_reward_duration(_token: address, _duration: uint256):
    """
    @notice Modify the duration that rewards are distributed over
    @dev Only callable when there is not an active reward period
    @param _token Address of the reward token
    @param _duration Number of seconds to distribute rewards over
    """
    assert msg.sender == self.owner  # dev: only owner
    assert block.timestamp > self.reward_data[_token].period_finish, "Reward period still active"
    self.reward_data[_token].duration = _duration


@external
def set_reward_distributor(_token: address, _distributor: address):
    """
    @notice Modify the reward distributor
    @param _token Address of the reward token
    @param _distributor Reward distributor
    """
    assert msg.sender == self.owner  # dev: only owner
    self.reward_data[_token].distributor = _distributor


@external
def commit_transfer_ownership(_owner: address):
    """
    @notice Initiate ownership tansfer of the contract
    @param _owner Address to have ownership transferred to
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _owner


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    owner: address = self.future_owner
    assert msg.sender == owner  # dev: only new owner

    self.owner = owner