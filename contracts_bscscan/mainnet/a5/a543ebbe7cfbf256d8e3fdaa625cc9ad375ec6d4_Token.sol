/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Current Version of solidity
pragma solidity ^0.8.4;

//  __    __ 
// |  |__|  |
// |  |  |  | ██████  ██    ██  ██████   █████   ██████   █████  
// |  |  |  | ██   ██ ██    ██ ██       ██   ██ ██       ██   ██ 
// |  `  '  | ██████  ██    ██ ██   ███ ███████ ██   ███ ███████ 
//  \      /  ██   ██ ██    ██ ██    ██ ██   ██ ██    ██ ██   ██ 
//   \_/\_/   ██████   ██████   ██████  ██   ██  ██████  ██   ██ 

// Bugaga Token Information
contract Token {

    // Initialize addresses mapping
    mapping(address => uint) public balances;

    // Total supply (in this case 1400 tokens)
    uint public totalSupply = 1400 * 10 ** 6;

    // Tokens Name
    string public name = "wBugaga";

    // Tokens Symbol
    string public symbol = "wBUG";

    // Total Decimals (max 6)
    uint public decimals = 6;

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
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}