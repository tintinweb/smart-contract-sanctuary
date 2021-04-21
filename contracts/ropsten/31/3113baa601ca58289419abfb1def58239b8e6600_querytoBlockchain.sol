/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public blockNumber;
        
        function query() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
        }
}