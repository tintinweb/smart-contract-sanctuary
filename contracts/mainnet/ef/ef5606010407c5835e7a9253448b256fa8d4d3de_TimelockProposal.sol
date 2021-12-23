/**
 *Submitted for verification at Etherscan.io on 2021-12-23
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

    weth.transfer(wildDeployer, 38.174e18);

    // ** Gas expenses **

    // Amount: 1.314 ETH

    // Block range: 13830462 to 13862568
    // Last done at https://etherscan.io/address/0x3E8Eed7EA2FF2f7eAb34eb3047B21FA2B173439D#code


    // **** wBOND buyback & burn ****

    // Amount: 36.86 ETH

    // Buyback: https://etherscan.io/tx/0x2b69ba16abb30dbe859905b21d1254b14fcc8c3f136f99e0781d965f95adf8b2
    // Burn:    https://etherscan.io/tx/0x1f134b1cb6ae8a417c4ddbca4f37f18e6bf07d8ff1cdf9caf3622f393f5c583f


    // **** TOTAL: Gas + wBOND buyback ****

    // 1.314 + 36.86 = 38.174 ETH
  }
}