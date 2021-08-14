//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Greeter {
    string greeting;

    event GreetingChanged(address indexed, string indexed);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory _greeting) {
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