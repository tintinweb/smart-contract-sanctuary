pragma solidity ^0.7.4;

// SPDX-License-Identifier: UNLICENSED

/**
 * Version 0.6
 * Date 11/15/2020
 * LOG: Deploy Mainnet
*/

import "./BurnableToken.sol";

contract BrokerstToken is BurnableToken {

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = 'H0.6';       

    constructor() {
        totalSupply = 25000000000;          // Total supply 
        balances[msg.sender] = totalSupply; // Give the creator all initial tokens
        name = "Brokerst Coin";             // Name for display purposes
        decimals = 2;                       // Amount of decimals for display purposes
        symbol = "BKT";                     // Symbol for display purposes
    }
}