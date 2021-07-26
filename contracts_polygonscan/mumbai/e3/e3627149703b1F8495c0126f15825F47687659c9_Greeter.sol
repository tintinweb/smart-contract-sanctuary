/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

contract Greeter {
    string public greeting;

    constructor(string memory initGreeting) {
        greeting = initGreeting;
    }

    function greet() external view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory newGreeting) external {
        greeting = newGreeting;
    }
}