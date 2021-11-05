/*
 * @MicroBrain Engineering Team
 * for Rabiit Coin Tokenization
 * Visit Us: www.RabiitCoin.com
 *
 */
 
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract RabiitCoin is ERC20 {
    
    constructor ()  ERC20("Rabiit Coin", "RBTC"){
        
        _mint(msg.sender, 7000000000 * (10 ** uint256(decimals())));
        
    }
}