/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract Giveaway {
    
    function selectWinner(address[] calldata users, uint256 salt) external view returns(address winner) {
        uint256 size = users.length;
        
        bytes32 hash = keccak256(abi.encode(address(this), block.number, block.timestamp, block.coinbase, block.gaslimit, block.difficulty, blockhash(block.number -5), size, salt));
        
        uint256 winnerIndex = uint256(hash) % size;
        
        return users[winnerIndex];
        
    
    }
    
}