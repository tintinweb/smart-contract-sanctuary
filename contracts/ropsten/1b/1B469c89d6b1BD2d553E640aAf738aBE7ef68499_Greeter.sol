/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Author: chenronglin
// Email: [email protected]

contract Greeter {
    string private greeting;

    constructor() {
        greeting = "Hello";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}