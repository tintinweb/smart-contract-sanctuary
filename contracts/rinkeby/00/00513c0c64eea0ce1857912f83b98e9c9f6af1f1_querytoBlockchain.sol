/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public msgvalue;
        uint public x;
        
        function buy() public payable{
            senderAddress = msg.sender;
            msgvalue = msg.value;
            x = 1+2+3+4+5+6;
        }
}