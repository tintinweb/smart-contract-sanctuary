//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract HelloWorldWithEvents {
  string public message;

  event UpdatedMessages(string oldStr, string newStr);

  constructor(string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, newMessage);
  }
}