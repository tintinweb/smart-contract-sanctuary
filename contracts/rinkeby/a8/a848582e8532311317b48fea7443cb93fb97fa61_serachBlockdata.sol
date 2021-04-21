/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
contract serachBlockdata{
    address public senderAddress;
    uint public blockNumber;
    uint public sendValue;
    uint public timestamp;
    
    function buy() public payable{
        senderAddress = msg.sender;
        blockNumber = block.number;
        sendValue = msg.value;
        timestamp = block.timestamp;
    }
}