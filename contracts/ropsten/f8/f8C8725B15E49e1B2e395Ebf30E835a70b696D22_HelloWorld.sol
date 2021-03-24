/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

contract HelloWorld {
    string private greeting;

    constructor() {
        greeting = "Hello World!";
    }

    function getGreeting() public view returns(string memory) {
        return greeting;
    }

    function getName() public pure returns(string memory) {
        return "Dammit!";
    }
}