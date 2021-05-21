/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// File: contracts/EthLock.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract EthLock {
    
    struct record {
        uint256 amount;
        uint256 blockNumber;
    }
    
    uint256 private lockDuration = 5;
    
    mapping(address => record) public Records;
   
    event recordAdded(address user, uint256 amount, uint256 blockNumber);
    
    function lock() payable public {
        require(msg.value > 0, "drop some ether");
        require(Records[msg.sender].amount == 0, "already locked");
        uint256 currentBlock = block.number;
        Records[msg.sender].amount = msg.value;
        Records[msg.sender].blockNumber = currentBlock;
        
        emit recordAdded(msg.sender, msg.value, currentBlock);
    }

    function unlock(address payable user) public {
        require(Records[user].amount != 0, "not exists");
        require(Records[user].blockNumber + lockDuration < block.number, "blocks duration not completed");
        user.transfer(Records[user].amount);
        delete Records[user];
    }
    
    function setLockDuration(uint256 value) public{
        require(value > 0, "invalid value");
        lockDuration = value;
    }

}