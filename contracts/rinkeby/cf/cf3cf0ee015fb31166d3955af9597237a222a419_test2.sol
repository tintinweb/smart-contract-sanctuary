/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract test2 {
    uint public value;
    address public sender;
    
    
    int public pro=1;
    function ad(int n)public payable{
        for(int i =1;i<=n;i++){
            pro=pro*i;
        }
        sender=msg.sender;
        value=msg.value;
    }
    
}