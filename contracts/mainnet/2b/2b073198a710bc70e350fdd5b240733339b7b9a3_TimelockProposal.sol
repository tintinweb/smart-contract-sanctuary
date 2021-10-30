/**
 *Submitted for verification at Etherscan.io on 2021-10-29
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
    IRewardDistribution rewardDistribution = IRewardDistribution(0x0fD91A3F5F3D79AfC95bf756Fea351b1F51A668c);
    IMasterPool masterPool = IMasterPool(0x3220269e3CfA62270F4d0e5c4245D7b6a0079777);

    interestRateModel.setLowRate(4185690000000);
    rewardDistribution.setTotalRewardPerBlock(2701875000000000000);
    masterPool.setTotalRewardPerBlock(300208333330000000);
  }
}