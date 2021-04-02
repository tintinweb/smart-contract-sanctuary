// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./StakingRewards.sol";
import "./IEmergency.sol";

contract StakingRewardsFactory is Ownable, IEmergency {
    // immutables
    address public emergencyRecipient;
    address public rewardsToken;
    uint256 public stakingRewardsGenesis;
    uint256 public rewardsDuration;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint256 rewardAmount;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _owner,
        address _emergencyRecipient,
        address _rewardsToken,
        uint256 _stakingRewardsGenesis,
        uint256 _rewardsDuration
    ) Ownable(_owner) {
        require(_stakingRewardsGenesis >= block.timestamp, "genesis too soon");
        require(_rewardsDuration > 0, "rewards duration is zero");

        emergencyRecipient = _emergencyRecipient;

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
        rewardsDuration = _rewardsDuration;
    }

    function emergencyWithdraw(IERC20 token) external override {
      require(address(token) != address(rewardsToken), "forbidden token");

      token.transfer(emergencyRecipient, token.balanceOf(address(this)));
    }

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() external {
        require(stakingTokens.length > 0, "called before any deploys");
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, "not ready");

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), "not deployed");

        if (info.rewardAmount > 0) {
            uint256 rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                "transfer failed"
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        }
    }

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, uint256 rewardAmount) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), "already deployed");

        info.stakingRewards = address(new StakingRewards(emergencyRecipient, /*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken, rewardsDuration));
        info.rewardAmount = rewardAmount;
        stakingTokens.push(stakingToken);

        emit StakingRewardsDeployed(info.stakingRewards, stakingToken, rewardAmount);
    }

    event StakingRewardsDeployed(address indexed stakingRewards, address indexed stakingToken, uint256 rewardAmount);
}