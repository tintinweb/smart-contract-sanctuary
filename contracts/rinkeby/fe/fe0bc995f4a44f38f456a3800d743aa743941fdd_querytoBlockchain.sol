/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public value;
        int public y=0;
        int public ans;
        
        function addition(int x) public payable {
            senderAddress = msg.sender;
            value = msg.value;
            y=0;
            for (int i = 1; i < x+1; i++) 
            {
                y=y+i;
            }
            ans = y;
            
        }
}