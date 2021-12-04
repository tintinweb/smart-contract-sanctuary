/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
  pragma solidity 0.8.10;

  contract Store {
      uint storedData;
      function setDataX(uint x) public {
          storedData = x;
      }
      function getDataX() public view returns (uint) {
          return storedData;
      }
  }