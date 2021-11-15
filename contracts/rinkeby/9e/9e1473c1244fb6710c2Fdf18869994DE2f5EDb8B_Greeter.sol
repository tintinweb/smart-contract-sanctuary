pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-2.0

// Example taken from https://www.ethereum.org/greeter, also used in
// https://github.com/ethereum/go-ethereum/wiki/Contract-Tutorial#your-first-citizen-the-greeter

contract Greeter {
    /* define variable greeting of the type string */
    string greeting = "hi";

    /* this runs when the contract is executed */
    constructor() {}

    function newGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    /* main function */
    function greet() public view returns (string memory) {
        return greeting;
    }
}

