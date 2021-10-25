// SPDX-License-Identifier: MIT


// sets the version we're running
pragma solidity >= 0.7.3;


contract HelloWorld {
  // when event is broadcast everyone will be able to see that the message has been updated
  event UpdatedMessages(string oldStr, string newStr);

  // define the state that we want the contract to keep track of
  string public message;

  // when the contract is deployed require argument to be passed in it as well called initMessage
  constructor (string memory initMessage) {
    // set state variable to initMessage
    message = initMessage;
  }

  // update state variable in the contract
  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, newMessage);
  }
}