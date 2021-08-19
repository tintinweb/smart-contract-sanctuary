/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.8.4;


contract Token {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    // Total supply (in this case 1000 tokens)
    uint public totalSupply = 1000 * 10 ** 18;
    // Tokens Name
    string public name = "MyToken";
    // Tokens Symbol
    string public symbol = "MTK";
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
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}