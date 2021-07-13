/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0

//https://google.com
pragma solidity ^0.8.2;

contract tester {
    
    address public owner;
    string public message;
    
    constructor(string memory _message){
        owner = msg.sender;
        message = _message;
    }
    
    function add(string[] memory name, uint8 _decimals, uint[] memory parameters, address[] memory addrs) pure public returns(string[] memory, uint8, uint[] memory, address[] memory){
        return (name, _decimals, parameters, addrs);
    }
    
}