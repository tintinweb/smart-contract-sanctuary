/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public blockNumber;
        uint public msgvalue;
        uint public time;
        
        function buy() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
            msgvalue = msg.value;
            time = block.timestamp;
        }
}