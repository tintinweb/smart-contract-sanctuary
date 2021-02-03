// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "./StakingRewards.sol";

contract USDTLPStakingRewards is StakingRewards {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public StakingRewards(_owner, _rewardsDistribution, _rewardsToken, _stakingToken) {}
}

contract ETHLPStakingRewards is StakingRewards {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public StakingRewards(_owner, _rewardsDistribution, _rewardsToken, _stakingToken) {}
}

contract COTIETHStakingRewards is StakingRewards {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public StakingRewards(_owner, _rewardsDistribution, _rewardsToken, _stakingToken) {}
}

contract GOVIETHStakingRewards is StakingRewards {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public StakingRewards(_owner, _rewardsDistribution, _rewardsToken, _stakingToken) {}
}