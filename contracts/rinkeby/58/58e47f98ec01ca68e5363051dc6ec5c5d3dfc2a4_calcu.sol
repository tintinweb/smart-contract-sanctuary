/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract calcu{
    uint public value;
    address public sender;
    
    int public pro=1;
    function calculate(int x)public payable{
        for(int i=1; i<=x; i++)
        {
            pro = pro * i;
        }
        sender = msg.sender;
        value = msg.value;
    }
}