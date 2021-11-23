/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract MyToken {
    uint public test = 3;
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    
    function getTest() public view returns(uint){
        return test;
    }
}