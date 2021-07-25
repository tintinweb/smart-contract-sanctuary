/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TopUpRewards {

  function execute() external {

    address rewardDistribution = 0x0fD91A3F5F3D79AfC95bf756Fea351b1F51A668c;
    address masterPool         = 0x3220269e3CfA62270F4d0e5c4245D7b6a0079777;

    IERC20 wild = IERC20(0x08A75dbC7167714CeaC1a8e43a8d643A4EDd625a);

    wild.transfer(rewardDistribution, 50_000e18);
    wild.transfer(masterPool, 500_000e18);
  }
}