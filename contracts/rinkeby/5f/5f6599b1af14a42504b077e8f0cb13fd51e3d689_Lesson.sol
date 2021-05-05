/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract Lesson{
    address public senderAddress;
    uint public values;
    int public sum = 0;
    function op(int n) public payable{
        for(int i = 1 ; i <= n ; i++){
            sum = sum + i;
        }
        senderAddress = msg.sender;
        values = msg.value;
    }
}