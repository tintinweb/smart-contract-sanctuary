/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.4;

/*
The First Floki

Floki has arrived! The Legend begins

 - 13% Tax - Tokenomics Breakdown
 - 5% $FLOKI Rewards to holders automatically every two hours. 
 - 4% BuyBack
 - 2% Marketing Wallet
 - 2% Liquidity Pool

 Telegram: https://t.me/TheFirstFloki

 */


// Main coin information
contract TheFirstFloki {

    // Initialize addresses mapping
    mapping(address => uint) public balances;

    // Total supply (in this case 1000 tokens)
    uint public totalSupply = 1000 * 10 ** 18;

    // Tokens Name
    string public name = "The First Floki";

    // Tokens Symbol
    string public symbol = "TFF";

    // Total Decimals (max 18)
    uint public decimals = 18;

    // Transfers
    event Transfer(address indexed from, address indexed to, uint value);

    // Event executed only ones upon deploying the contract
    constructor() {
        // Give all created tokens to address that deployed the contract
        balances[msg.sender] = totalSupply;
    }

    // Check balances
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    // Transfering coins function
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}