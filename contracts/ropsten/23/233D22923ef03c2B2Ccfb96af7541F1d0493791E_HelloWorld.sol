/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

contract HelloWorld {
    string private greeting;
    uint256 number;

    constructor() {
        greeting = "Hello World!";
    }

    function getGreeting() public view returns(string memory) {
        return greeting;
    }

    function getName() public pure returns(string memory) {
        return "Dammit!";
    }

    function setGreeting(string memory message) public {
        greeting = message;
    }

    function setNumber(uint256 num) public {
        number = num;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}