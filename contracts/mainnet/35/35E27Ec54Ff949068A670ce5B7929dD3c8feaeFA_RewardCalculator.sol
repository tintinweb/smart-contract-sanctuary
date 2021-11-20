// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IRewardCalculator {
    function rewardPerBlock() external view returns (uint256);
}

contract RewardCalculator is IRewardCalculator {
    function rewardPerBlock() external pure override returns (uint256) {
        return 0;
    }
}