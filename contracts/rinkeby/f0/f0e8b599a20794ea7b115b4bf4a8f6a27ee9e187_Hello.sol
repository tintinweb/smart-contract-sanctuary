/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Hello{

    uint public Tong=8;
    address public owner;
    
    constructor(){
        Tong = Tong * 2;
        owner = msg.sender;
    }
    
}