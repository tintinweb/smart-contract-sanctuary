/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract TestToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 2300000000000 * 10 ** 7;
    string public name = "TestToken";
    string public symbol = "TKN";
    uint public decimals = 7;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}