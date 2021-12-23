/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract HelloWorld {
  string public message;

  constructor(string memory initialMessage) {
    message = initialMessage;
  }

  function updateMessage(string memory newMessage) public {
    message = newMessage;
  }
}