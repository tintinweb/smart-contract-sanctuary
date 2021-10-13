pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT





contract Greeter {
    string private greeting;
    string public greetingFromSolpp;

    constructor(string memory _greeting) {

        greeting = _greeting;
        greetingFromSolpp = "Greeting from rinkeby";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {

        greeting = _greeting;
    }
}