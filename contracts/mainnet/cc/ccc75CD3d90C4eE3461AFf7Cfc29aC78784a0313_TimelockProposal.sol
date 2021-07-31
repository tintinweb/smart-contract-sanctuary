/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address wildDeployer       = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;
    address rewardDistribution = 0x0fD91A3F5F3D79AfC95bf756Fea351b1F51A668c;
    address masterPool         = 0x3220269e3CfA62270F4d0e5c4245D7b6a0079777;

    IERC20 wild = IERC20(0x08A75dbC7167714CeaC1a8e43a8d643A4EDd625a);

    // a little over a week worth of rewards for the reward contracts
    wild.transfer(rewardDistribution, 500_000e18);
    wild.transfer(masterPool, 500_000e18);

    // Reimburse DAO expenses paid from the personal allocation up to this point
    uint reimburseAmount;

    // 100k send from a personal allocation to quickly top up rewards after the went dry
    // https://etherscan.io/tx/0x6f9fbdb97264c3fd9d9c5e35f2930f5f157d2cf9256abc13280a7d87c5489a23
    reimburseAmount += 100_000e18;

    // Reimbursing missed rewards of the LPs
    // https://discord.com/channels/823827013441552404/823827013441552407/870483283664855071
    // https://etherscan.io/tx/0x076fbde3e8490ff9db536c48e3fc3f866b46d110743dac97ed0fd079c441d613
    // https://etherscan.io/tx/0xc16fbcce6c594488858cf7210942ccb1b771c77f522ee7c79525c32ceb0f795c
    // https://etherscan.io/tx/0xfae3dd1ebb4572434f71c05fdebc0ad7adb5529ce396880ccbf88516f6d8f760
    reimburseAmount += 2_000e18 + 1_100e18 + 2_800e18;

    // 60,000 USD spent on an audit at the current spot price of WILD $0.2979
    // 60,000 / 0.2979 = ~ 201,400 WILD
    reimburseAmount += 201_400e18;

    // Gas expenses from block 12303612 to 12924751 for the deployer address
    // https://etherscan.io/address/0xd7b3b50977a5947774bfc46b760c0871e4018e97
    // 8.161 ETH which is 66,487 WILD at the current price
    reimburseAmount += 66_450e18;

    wild.transfer(wildDeployer, reimburseAmount);
  }
}