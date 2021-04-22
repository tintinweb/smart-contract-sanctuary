/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
contract operation{
    int public sum=0;
    int public product=1;
    uint public value;
    address public sender;
    function add(int x)public payable{
        for(int i=1 ; i<=x ; i++){
            sum = sum + i;
        }
        sender = msg.sender;
        value = msg.value;
    }
    function mul(int y)public payable{
        for(int j=1 ; j<=y ; j++){
            product = product * j;
        }
    }
}