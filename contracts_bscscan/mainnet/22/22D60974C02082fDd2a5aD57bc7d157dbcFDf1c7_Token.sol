/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

/* Test coin, will be taken seriously if there's traffic
*/
pragma solidity ^0.8.11;
// SPDX-License-Identifier: UNLICENSED

contract Token {
    mapping(address => uint) public balances;
    mapping(address =>mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000 * 10 **1;
    string public name = "Math Homework";
    string public symbol = "MATH";
    uint public decimals = 1;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'insufficient balance');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve (address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}