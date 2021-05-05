/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;                 
contract Lesson{                        
    
    uint public value;
    address public sender;
    int public ans = 0;
    
    function cul(int x)public payable{
        ans=0;
        for(int i = 1;i<x+1;i++){
            ans=ans+i;
        }
        sender = msg.sender;
        value = msg.value;
    }
}