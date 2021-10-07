/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    string private greeting2;
    string private greeting3;

    constructor(string memory _greeting, string memory _greeting2, string memory _greeting3) {
        greeting = _greeting;
        greeting2 = _greeting2;
        greeting3 = _greeting3;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
    
    function greetAlso() public view returns (string memory) {
        return greeting2;
    }
    
    function greetFinal() public view returns (string memory) {
        return greeting2;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
    
    function setGreetingAlso(string memory _greeting2) public {
        greeting = _greeting2;
    }
    
    function setGreetingFinal(string memory _greeting3) public {
        greeting = _greeting3;
    }
}