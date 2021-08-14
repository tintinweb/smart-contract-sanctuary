//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Greeter {
    string greeting;
    address sender;

    event GreetingChanged(address indexed sender, string indexed greet);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function getSender() public view returns (address _sender) {
        _sender = sender;
    }

    function setSender() public {
        sender = msg.sender;
    }

    function getGreeting() public view returns (string memory _greeting) {
        _greeting = greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit GreetingChanged(msg.sender, greeting);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}