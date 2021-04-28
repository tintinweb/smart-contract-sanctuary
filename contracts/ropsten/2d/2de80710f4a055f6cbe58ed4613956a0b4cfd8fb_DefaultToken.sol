pragma solidity ^0.7.4;

// SPDX-License-Identifier: UNLICENSED

/**
 * Version 0.7
 * Date 01/22/2021
 * LOG: Default contract
*/

import "./BurnableToken.sol";

contract DefaultToken is BurnableToken {

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = 'H0.6';       

    constructor(uint256 _totalSupply, address _owner, string memory _name, uint8 _decimals, string memory _symbol) {
        totalSupply = _totalSupply;         // Total supply 
        balances[_owner] = totalSupply;     // Give the creator all initial tokens
        name = _name;                       // Name for display purposes
        decimals = _decimals;               // Amount of decimals for display purposes
        symbol = _symbol;                   // Symbol for display purposes
    }
}