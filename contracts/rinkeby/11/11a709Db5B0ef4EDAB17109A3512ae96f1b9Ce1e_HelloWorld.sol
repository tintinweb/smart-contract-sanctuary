// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
  event UpdatedMessages(string oldStr, string newStr);

  string public message;

  //run only once when the contract is deployed
  constructor (string memory initMessage) {
    message = initMessage;
  }

  //memory?? public (access permission of the contract)
  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, message);
  }
}