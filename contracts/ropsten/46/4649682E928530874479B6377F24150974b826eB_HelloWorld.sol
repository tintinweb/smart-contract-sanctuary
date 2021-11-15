// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract HelloWorld {

  event UpdatedMessages(string oldStr, string newStr);

  string public message;

  // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
  constructor(string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, newMessage);
  }
}

