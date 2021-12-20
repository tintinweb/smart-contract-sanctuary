/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract HelloWorld {
//  function HelloWorld(){
//
//  }

  function displayMessage() public pure returns (string memory) {
    return 'Hello from smart contract';
  }
}