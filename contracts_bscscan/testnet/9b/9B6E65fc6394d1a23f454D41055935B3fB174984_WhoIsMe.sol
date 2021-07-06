/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Main coin information
contract WhoIsMe {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    // Total supply (in this case 1000 tokens)
    uint public totalSupply = 88888888;
    // Tokens Name
    string public name = "WhoIsMe";
    // Tokens Symbol
    string public symbol = "ISME";
    // Total Decimals (max 18)
    uint public decimals = 0;
    
    // Transfers
    event Transfer(address indexed from, address indexed to, uint value);
    
    // Event executed only ones uppon deploying the contract
    constructor() {
        // Give all created tokens to adress that deployed the contract
        balances[msg.sender] = totalSupply;
    }
    
    // Check balances
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    // Transfering coins function
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}