/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

contract test {
     
     string[] public dataStore;
     
     function add(string memory vars) public {
         dataStore.push(vars);
     }
     
     function len() public view returns (uint256) {
      return dataStore.length;
     } 
}