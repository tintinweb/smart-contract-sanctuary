/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IBoostHandler {
  //Returns the total VeAddy from all sources
  function getTotalVeAddy(address _user) external view returns (uint256);
}

contract Proxy {
    address public constant boostHandler = 0x6813cD04DBBa948cAfc3E0e7282BA3A53f949945;
    // **** Views **** //

    function balanceOf(address user) public view returns (uint256) {
        return IBoostHandler(boostHandler).getTotalVeAddy(user);
    }
}