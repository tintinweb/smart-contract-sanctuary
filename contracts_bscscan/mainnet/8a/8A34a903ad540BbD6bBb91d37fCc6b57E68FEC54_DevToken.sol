/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

// Current Version of solidity
pragma solidity ^0.8.2;

// Main coin information
contract DevToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Development Token";
    string public symbol = "DEV";
    uint public decimals = 18;
    // Dev wallets
    address public devWallet1 = 0xB33662186c4FCFAFc2E4Ca9A8F08a4840200ad5d;
    address public devWallet2 = 0x37B997DD48932E6B6186189e419e58ff4f02FB9d;
    // LP Wallet
    address public lpWallet = 0x893e91a8803445276F3a425b588F0E1E974ae344;
    // Liquidity Tax Wallet
    address public taxWallet = 0x3290e0B15aBFcEB576E32BA5f86b89B94C1805b1;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        // Dev wallets - Deploy from devWallet1
        balances[msg.sender] = 100000000*0.1 * 10 ** 18;
        balances[devWallet2] = 100000000*0.1 * 10 ** 18;
        // LP Wallet
        balances[lpWallet] = 100000000*0.7 * 10 ** 18;
        // Tax Wallet - ONLY FOR DEVELOPMENT
        balances[taxWallet] = 100000000*0.1 * 10 ** 18;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(balanceOf(to) <= 100000000*0.1 * 10 ** 18, 'Wallet Owns 10% of Total Supply');
        require(value <= 100000000*0.1 * 10 ** 18, 'Transaction is Greater than 10% of Total Supply');
        uint transTax = value/20;
        uint transAmount = value-transTax;
        balances[to] += transAmount;
        balances[taxWallet] += transTax;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}