/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
contract HelloWorld {
  string public message;

  constructor(string memory initialiseMessage) {
    message = initialiseMessage;
  }

  function update(string memory newMessage) public {
    message = newMessage;
  }
}