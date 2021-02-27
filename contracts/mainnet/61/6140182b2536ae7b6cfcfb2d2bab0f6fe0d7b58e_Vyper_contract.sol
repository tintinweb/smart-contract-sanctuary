# @version 0.2.8
# @notice A manager contract for the StakingRewards contract from Arcx.
# @author skozin, kadmil
# @license MIT
from vyper.interfaces import ERC20


interface StakingRewards:
    def collabPeriodFinish() -> uint256: view
    def notifyRewardAmount(reward: uint256, rewardToken: address): nonpayable
    def setcollabRewardsDistributor(_rewardsDistributor: address): nonpayable
    def recovercollab(amount: uint256): nonpayable


owner: public(address)
rewards_contract: public(address)
ldo_token: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32


@external
def __init__():
    self.owner = msg.sender


@external
@payable
def __default__():
    assert msg.value > 0 # dev: unexpected call


@view
@internal
def _is_rewards_period_finished(rewards_contract: address) -> bool:
    return block.timestamp >= StakingRewards(rewards_contract).collabPeriodFinish()


@internal
def _recover_erc20(_token: address, _token_amount: uint256):
    recipient: address = self.owner

    ERC20(_token).transfer(recipient, _token_amount)

    if self.balance != 0:
        send(recipient, self.balance)


@view
@external
def collab_rewards_period_finish() -> uint256:
    """
    @notice The timestamp of LDO reward period finish.
    """
    return StakingRewards(self.rewards_contract).collabPeriodFinish()


@view
@external
def is_rewards_period_finished() -> bool:
    """
    @notice Whether the current rewards period has finished.
    """
    return self._is_rewards_period_finished(self.rewards_contract)


@external
def transfer_ownership(_to: address):
    """
    @notice Changes the contract owner. Can only be called by the current owner.
    """
    assert msg.sender == self.owner, "not permitted"
    self.owner = _to


@external
def set_rewards_contract(_rewards_contract: address):
    """
    @notice Sets the StakingRewards contract. Can only be called by the owner.
    """
    assert msg.sender == self.owner, "not permitted"
    self.rewards_contract = _rewards_contract


@external
def start_next_rewards_period():
    """
    @notice
        Starts the next rewards period of duration `rewards_contract.rewardsDuration()`,
        distributing `ldo_token.balanceOf(self)` tokens throughout the period. The current
        rewards period must be finished by this time.
    """
    rewards_contract: address = self.rewards_contract
    amount: uint256 = ERC20(ldo_token).balanceOf(self)

    assert rewards_contract != ZERO_ADDRESS and amount != 0, "manager: rewards disabled"
    assert self._is_rewards_period_finished(rewards_contract), "manager: rewards period not finished"

    ERC20(ldo_token).transfer(rewards_contract, amount)
    StakingRewards(rewards_contract).notifyRewardAmount(amount, ldo_token)


@external
def recover_ldo_from_campaign(_amount: uint256):
    """
    @notice
        Recovers all extra LDO from rewards contract to the reward manager owner.
    """
    StakingRewards(self.rewards_contract).recovercollab(_amount)
    self._recover_erc20(ldo_token, _amount)


@external
def change_manager(_new_manager: address):
    """
    @notice Changes the LDO reward manager in the reward contract.
    """
    assert msg.sender == self.owner, "not permitted"

    rewards_contract: address = self.rewards_contract
    assert rewards_contract != ZERO_ADDRESS, "manager: no rewards contract"

    StakingRewards(self.rewards_contract).setcollabRewardsDistributor(_new_manager)


@external
def recover_erc20(_token: address, _token_amount: uint256):
    """
    @notice
        Transfers the the given ERC20 token and the whole
        ETH balance from self to the owner of self.
    """
    self._recover_erc20(_token, _token_amount)