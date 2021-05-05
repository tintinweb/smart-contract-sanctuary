/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public msgvalue;
        int public value=1;
        function count(int n) public payable{
            for(int i=1;i<=n;i++){
                value = value * i;
            }
            senderAddress = msg.sender;
            msgvalue = msg.value;
        }
}