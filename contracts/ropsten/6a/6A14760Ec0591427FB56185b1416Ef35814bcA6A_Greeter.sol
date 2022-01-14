/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Greeter {
    string private greeting;

    constructor() {
        greeting = "Hello world!";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}