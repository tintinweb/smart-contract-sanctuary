// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;



contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {

        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {

        greeting = _greeting;
    }
}

{
  "optimizer": {
    "enabled": false,
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