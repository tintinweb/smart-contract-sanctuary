/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.3 and less than 0.8.0
pragma solidity ^0.8.3;

contract SayHello {
    string public greet = "Hello World!";
    
    function sayHello(string memory _name) public pure returns (string memory)  {
        string memory greeting = string(abi.encodePacked("Hello", _name));
        return greeting;
    }
}