/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity ^0.7.6;
pragma abicoder v2;
// SPDX-License-Identifier: RANDOM_TEXT

contract GasWaster  {
    
    event info1(uint a1);
    event isContract(bool a1);

    constructor() {
      value = 0;
    }

    uint256 value;

    // 0xab144f5c
    function waste1(uint256 loops) public returns (uint256) {
      for (uint i = 0; i < loops; i++) {
        value = block.number;
        emit info1(i);
      }
      return value;
    }

    // 0xee24c3d5
    function waste2(uint256 loops) public returns (uint256) {
      for (uint i = 0; i < loops; i++) {
        value = block.number;
        emit info1(i);
      }
      return value;
    }

}