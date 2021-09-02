/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract HelloWorld {
    string public message;
    
    constructor() {
        message = "Hello World";
    }
    
    function hello() public view returns (string memory) {
        return message;
    }
}