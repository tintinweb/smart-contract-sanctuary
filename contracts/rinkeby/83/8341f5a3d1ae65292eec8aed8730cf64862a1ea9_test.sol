/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract test{
    
    uint public value;
    address public senderaddress;
    
    int public temp = 1;
    function calculate(int n) public payable{
        for(int i = 1 ; i<=n ;i++){
            temp = temp * i;
        }
        
        senderaddress = msg.sender;
        value = msg.value;
    }
}