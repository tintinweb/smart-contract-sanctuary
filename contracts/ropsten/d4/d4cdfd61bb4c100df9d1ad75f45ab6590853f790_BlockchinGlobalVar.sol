/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


contract BlockchinGlobalVar {
    
    string hellostr;
    address owner;
    
    constructor() {
        hellostr = "Hello World";
        owner = msg.sender;
    }
    
    function getBlockDifficulty() public view returns(uint256) {
        return block.difficulty;
    }
    
    function getBlockTimestamp() public view returns(uint256) {
        return block.timestamp;
    }
    
    function getBlockNumber() public view returns(uint256) {
        return block.number;
    }
    
    function getBlockHash() public view returns(bytes32) {
        return blockhash(block.number + 1);
    }
  
}