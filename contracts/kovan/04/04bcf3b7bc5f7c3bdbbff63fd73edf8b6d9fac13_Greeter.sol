/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    constructor() {
        greeting = "Hello Guys";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}