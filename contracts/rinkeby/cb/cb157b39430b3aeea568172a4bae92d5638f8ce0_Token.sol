/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Token {
    uint public tokenCount = 1000;
    string public greeting = 'Hello World';

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}