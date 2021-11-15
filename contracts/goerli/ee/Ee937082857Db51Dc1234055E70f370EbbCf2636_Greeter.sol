// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

error GreeterError();

contract Greeter {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function throwError() external pure {
        revert GreeterError();
    }
}

