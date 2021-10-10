/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MiniToken {
    
    struct Tokens {
        address owner;
        uint256 mintDate;
    }
    
    mapping (uint8 => Tokens) public tokens;
    
    uint8 private id = 0;
    
    event Eminted(address Eowner, uint8 EtokenId, uint256 ElastMint);
    
    function theMint() public {
        tokens[id].owner = msg.sender;
        tokens[id].mintDate = block.timestamp;
        
        emit Eminted(msg.sender, id, tokens[id].mintDate);
        id++;
    }

}