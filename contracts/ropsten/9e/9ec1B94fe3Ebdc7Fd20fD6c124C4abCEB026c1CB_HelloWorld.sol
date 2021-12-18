/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract HelloWorld {
  string private message; 

  constructor(string memory _message) {
    message = _message;
  }

  function getMessage() public view returns(string memory) {
    return message;
  }

  function updateMessage(string memory _message) public {
    message = _message;
  }
}