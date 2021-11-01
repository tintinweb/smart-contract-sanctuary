// SPDX-License-Identifier: MIT

// Contract address 0x21a80558B60D26400F1C04bDA5546953C85a9BBB

pragma solidity >= 0.7.3;

contract HelloWorld {
  event UpdatedMessages(string oldStr, string newStr);

  string public message;

  constructor (string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    string memory oldMessage = message;

    message = newMessage;
    emit UpdatedMessages(oldMessage, newMessage);
  }
}