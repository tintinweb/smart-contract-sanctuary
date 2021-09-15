# @version 0.2.15
# @notice A manager contract for the FarmingRewards contract.
# @license MIT
from vyper.interfaces import ERC20


struct TokenReward:
    gift_token: address
    scale: uint256
    duration: uint256
    reward_distribution: address
    period_finish: uint256
    reward_rate: uint256
    last_update_time: uint256
    reward_per_token_stored: uint256


interface FarmingRewards:
    def tokenRewards(index: uint256) -> TokenReward: view
    def notifyRewardAmount(index: uint256, reward: uint256): nonpayable
    def setDuration(i: uint256, duration: uint256): nonpayable


event OwnershipTransferred: 
    previous_owner: indexed(address)
    new_owner: indexed(address)

event RewardsContractSet:
    rewards_contract: indexed(address)

event ERC20TokenRecovered:
    token: indexed(address)
    amount: uint256
    recipient: indexed(address)


owner: public(address)
GIFT_INDEX: constant(uint256) = 1
rewards_contract: public(address)
ldo_token: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
rewards_initializer: public(address)


@external
def __init__(_rewards_contract: address, _rewards_initializer: address):
    assert _rewards_contract != ZERO_ADDRESS, "rewards contract: zero address"
    assert _rewards_initializer != ZERO_ADDRESS, "rewards initializer: zero address"
    self.rewards_contract = _rewards_contract
    log RewardsContractSet(_rewards_contract)

    self.owner = msg.sender
    log OwnershipTransferred(ZERO_ADDRESS, msg.sender)

    self.rewards_initializer = _rewards_initializer


@external
def transfer_ownership(_to: address):
    """
    @notice
        Changes the contract owner.
        Can only be called by the current owner.
    """
    old_owner: address = self.owner
    assert msg.sender == old_owner, "not permitted"
    self.owner = _to

    log OwnershipTransferred(old_owner, _to)


@view
@internal
def _period_finish(rewards_contract: address) -> uint256:
    reward: TokenReward = FarmingRewards(rewards_contract).tokenRewards(GIFT_INDEX)
    return reward.period_finish


@view
@internal
def _is_rewards_period_finished(rewards_contract: address) -> bool:
    return block.timestamp >= self._period_finish(rewards_contract)


@view
@external
def is_rewards_period_finished() -> bool:
    """
    @notice Whether the current rewards period has finished.
    """
    return self._is_rewards_period_finished(self.rewards_contract)


@view
@external
def period_finish() -> uint256:
    return self._period_finish(self.rewards_contract)


@external
def start_next_rewards_period():
    """
    @notice
        Starts the next rewards via calling `FarmingRewards.notifyRewardAmount()`
        and transferring `ldo_token.balanceOf(self)` tokens to `FarmingRewards`.
        The `FarmingRewards` contract handles all the rest on its own.
        The current rewards period must be finished by this time.
        First period could be started only by `self.rewards_initializer`
    """
    rewards: address = self.rewards_contract

    assert self._period_finish(rewards) > 0 or self.rewards_initializer == msg.sender, "manager: not initialized"
    
    amount: uint256 = ERC20(ldo_token).balanceOf(self)

    assert amount != 0, "manager: rewards disabled"
    assert self._is_rewards_period_finished(rewards), "manager: rewards period not finished"

    assert ERC20(ldo_token).transfer(rewards, amount), "manager: unable to transfer reward tokens"

    FarmingRewards(rewards).notifyRewardAmount(GIFT_INDEX, amount)


@external
def set_rewards_period_duration(_duration: uint256):
    """
    @notice
        Updates period duration.  Can only be called by the owner.
    """
    assert msg.sender == self.owner, "manager: not permitted"

    FarmingRewards(self.rewards_contract).setDuration(GIFT_INDEX, _duration)


@external
def recover_erc20(_token: address, _amount: uint256, _recipient: address = msg.sender):
    """
    @notice
        Transfers the given _amount of the given ERC20 token from self
        to the recipient. Can only be called by the owner.
    """
    assert msg.sender == self.owner, "not permitted"

    if _amount != 0:
        assert ERC20(_token).transfer(_recipient, _amount), "token transfer failed"
        log ERC20TokenRecovered(_token, _amount, _recipient)