pragma solidity ^0.8.0;

contract HelloWorld {

  string public message;

  constructor(string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    message = newMessage;
  }
}