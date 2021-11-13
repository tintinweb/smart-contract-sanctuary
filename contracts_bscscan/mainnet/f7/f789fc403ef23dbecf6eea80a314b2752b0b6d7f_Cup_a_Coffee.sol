/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: GPL-3.0
/* 
Show some gratitude for someone who's helped you with a Coffee. 

Send them some CFEx to show them how grateful you are.

This token was created to help you show some gratitude and recognition for volunteers who work around us for us r for others.

Buy them a coffee.

Say a big THANKS YOU!

*/

pragma solidity ^0.8.2;

contract Cup_a_Coffee {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000*10**9*10**9;
    string public name = "Cup_a_Coffee";
    string public symbol = "CFEx";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'You do not have anough CFEx');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'You do not have anough CFEx');
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