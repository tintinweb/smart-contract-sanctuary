/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TheToken {
    
    struct Tokens {
        uint8 balance;
        uint256 lastMint;
    }
    
    mapping (address => Tokens) public balances;
    
    event Eminted(address Eowner, uint8 Ebalance, uint256 ElastMint);
    
    function theMint() public {
        balances[msg.sender].balance = balances[msg.sender].balance + 1;
        balances[msg.sender].lastMint = block.timestamp;
        
        emit Eminted(msg.sender, balances[msg.sender].balance, balances[msg.sender].lastMint);
    }

}