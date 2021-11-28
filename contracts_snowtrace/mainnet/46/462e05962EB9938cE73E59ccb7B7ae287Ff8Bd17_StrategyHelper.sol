// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IStrategy {
  function checkReward() external view returns (uint256);
  function totalDeposits() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function REINVEST_REWARD_BIPS() external view returns (uint256);
}

contract StrategyHelper {

  struct StrategyInfo {
    uint totalSupply;
    uint totalDeposits;
    uint reward;
    uint reinvestRewardBips;
  }

  constructor() {}

  function strategyInfo(address strategyAddress) public view returns (StrategyInfo memory) {
    IStrategy strategy = IStrategy(strategyAddress);
    StrategyInfo memory info;
    info.totalSupply = strategy.totalSupply();
    info.totalDeposits = strategy.totalDeposits();
    info.reward = strategy.checkReward();
    info.reinvestRewardBips = strategy.REINVEST_REWARD_BIPS();
    return info;
  }
}