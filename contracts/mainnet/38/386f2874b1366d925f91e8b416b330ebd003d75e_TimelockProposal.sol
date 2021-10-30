/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IInterestRateModel {
  function setLowRate(uint _value) external;
}

interface IRewardDistribution {
  function setTotalRewardPerBlock(uint _value) external;
}

interface IMasterPool {
  function setTotalRewardPerBlock(uint _value) external;
}

contract TimelockProposal {

  function execute() external {

    IInterestRateModel interestRateModel = IInterestRateModel(0x1FfD9e1c038773d1C61dFeB0CDb5aFd2D8F28C97);
    interestRateModel.setLowRate(10e18);
  }
}