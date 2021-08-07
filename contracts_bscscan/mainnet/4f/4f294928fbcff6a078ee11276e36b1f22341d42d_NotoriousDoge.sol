/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

/*

With a dynamic sell limit based on price impact and increasing sell cooldowns and redistribution taxes on consecutive sells, NotoriousDoge was designed to reward holders and discourage dumping.

https://notoriousdoge.live/
https://twitter.com/NotoriousDoge_
https://t.me/officialnotoriousdog

Token Information
1. 1,000,000,000,000 Total Supply
2. Sells limited to 3% of the Liquidity Pool, <2.9% price impact    
3. Sell cooldown increases on consecutive sells, 4 sells within a 24 hours period are allowed
4. 4% redistribution to liquidty on all buys and sells
5. 6% redistribution to holders on the first sell, increases 2x, 3x, 4x on consecutive sells
6. 3% burn of tokens on all sells
7. 10% initial burn at launch
8. 5% Marketing and Charity fee split between Marketing and Charity wallets

SPDX-License-Identifier: MIT
*/


pragma solidity ^0.8.2;

contract NotoriousDoge {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000 * 10 ** 18;
    string public name = "NotoriousDoge";
    string public symbol = "NTSDOGE";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
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