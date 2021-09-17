/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // 2nd audit & salaries from block 13008563 to 13240927 for the deployer address
    // https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48?a=0xd7b3b50977a5947774bfc46b760c0871e4018e97

    // 20 ETH (69,495 USDC @ 3,500 ETH price = ~ 20 ETH)
    weth.transfer(wildDeployer, 20e18);
  }
}