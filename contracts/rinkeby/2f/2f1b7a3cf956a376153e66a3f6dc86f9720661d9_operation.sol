/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;
contract operation {
    
    address public sender;
    uint public value;
    
    int public pro = 1;
    function op(int n) public payable{
        for(int i = 1;i <= n;i++){
            pro = pro * i;
        }
    
    sender = msg.sender;
    value = msg.value;
    }
}