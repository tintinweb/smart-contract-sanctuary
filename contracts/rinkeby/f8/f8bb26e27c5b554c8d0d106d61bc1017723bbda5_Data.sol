/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract Data{
    
    address public sender;
    uint public value;
    int public A=1;
    function count(int n)public payable{
        for(int i=1;i<=n;i++){
            A=A*i;
        }
        sender=msg.sender;
        value=msg.value;
    }
}