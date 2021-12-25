/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT
// Author: LufyCZ

pragma solidity ^0.8.0;

interface IMasterChef {
  function updatePool(uint256 _pid) external;
}

contract MasterChefUpdater {
  IMasterChef constant masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

  function updatePools(uint16[] calldata _pids) public {
    for(uint16 i = 0; i < _pids.length; i++) {
      masterChef.updatePool(_pids[i]);
    }
  }
}