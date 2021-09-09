/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: GPL-3.0-only


contract GMC {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public constant totalSupply =  10 ** 20;
    string public constant name = "Gamico";
    string public constant symbol = "GMC";
    uint public constant decimals = 8;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(to != address(0x0), 'use 0xdead instead');
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(to != address(0x0), 'use 0xdead instead');
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        require(spender != address(0x0), 'use 0xdead instead');
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}