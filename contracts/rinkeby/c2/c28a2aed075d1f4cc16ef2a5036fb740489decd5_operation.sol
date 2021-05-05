/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract operation{
        
    uint public value;
    address public sender;
    
    int public add=0;
    function calculator(int x )public payable{
        for(int i = 1 ;i<=x;i++){
        add = add + i;
        }
        sender = msg.sender;
        value = msg.value;
    }
}