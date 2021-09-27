/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract Greeter{
    string public greeting;
    
    constructor() public {
        greeting = 'Hello';
    }
    function setGreeting(string _greeting) public{
        greeting = _greeting;
    }
    
    function greet() view public returns (string memory) {
        return greeting;
        
    }
}