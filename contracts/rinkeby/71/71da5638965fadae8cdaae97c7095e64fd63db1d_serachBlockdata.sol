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
    bytes32 public blockParentHash;
    address public minerAddress;
    uint public difficulty;
    uint public gasPrice;
    
    function buy() public payable{
        senderAddress = msg.sender;
        blockNumber = block.number;
        sendValue = msg.value;
        timestamp = block.timestamp;
        blockParentHash = blockhash(blockNumber-1);
        minerAddress = block.coinbase;
        difficulty = block.difficulty;
        gasPrice = tx.gasprice;
    }
}