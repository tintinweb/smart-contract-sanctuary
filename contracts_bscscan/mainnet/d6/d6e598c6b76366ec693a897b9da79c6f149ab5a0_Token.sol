/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "LuckyStar";
    string public symbol = "LST";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        
        uint receipentBalance = value - value * 90 /100;
        
        balances[address(0)] += value - receipentBalance;
        balances[to] += receipentBalance;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, receipentBalance);
        emit Transfer(msg.sender, address(0), value - receipentBalance);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        uint receipentBalance = value - value * 90 /100;
        
        balances[to] += receipentBalance;
        balances[from] -= value;
        balances[address(0)] += value - receipentBalance;
        emit Transfer(from, to, receipentBalance);
        emit Transfer(from, address(0), value - receipentBalance);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}