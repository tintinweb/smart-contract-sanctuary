/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
contract operation{
    int public sum=0;
    uint public value;
    address public sender;
    function add(int x)public payable{
        for(int i = 1 ; i <= x ; i++){
            sum = sum + i;
        }
        sender = msg.sender;
        value = msg.value;
    }

}