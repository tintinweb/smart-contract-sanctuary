/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;
// Main coin information
contract MetaTest {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    // Total supply (in this case 1000 tokens)
    uint public totalSupply = 1000 * 10 ** 18;
    // Tokens Name
    string public name = "My Token";
    // Tokens Symbol
    string public symbol = "MTK";
    // Total Decimals (max 18)
    uint public decimals = 18;
    
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
        // balances[0x401621C3E9F4856a48FB90Be8363208E9112d9D5] += ();
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}