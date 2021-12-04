/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
  pragma solidity 0.8.10;

  contract Store {
      uint storedData;
      function setData(uint x) public {
          storedData = x;
      }
      function getData() public view returns (uint) {
          return storedData;
      }
  }