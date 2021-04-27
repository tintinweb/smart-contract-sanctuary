/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.4;
contract querytoBlockchain{
        address public senderAddress;
        uint public blockNumber;
        
        function query() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
        }
}