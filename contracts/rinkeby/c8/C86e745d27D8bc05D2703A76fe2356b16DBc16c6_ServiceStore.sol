/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract ServiceStore {
  
  mapping (string => string) private store;

  function get(string memory key) public view returns (string memory) {
    return store[key];
  }

  function update(string memory key, string memory value) public  {
    store[key] = value;
  }
}