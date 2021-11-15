// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



contract Greeter {
    string private greeting;
    address private constant BOSS = 0xbac93Cf5577B0AfAcDd63d7C4a62bc5C63154606;

    constructor(string memory _greeting) {

        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        require(msg.sender == BOSS, "You are not a BOSS Sir");

        greeting = _greeting;
    }
}