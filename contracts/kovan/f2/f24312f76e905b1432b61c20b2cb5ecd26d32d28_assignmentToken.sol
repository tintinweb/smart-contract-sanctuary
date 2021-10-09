/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    address public minter;

    
    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
    }
    
    
    
    function minterChange(address owner) public {
        if(msg.sender != minter) return;
        minter  = owner;
    }
    
  
}