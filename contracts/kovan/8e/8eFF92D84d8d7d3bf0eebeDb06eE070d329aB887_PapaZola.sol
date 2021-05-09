/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

/*
SPDX-License-Identifier: GPL-2.0-only OR MIT
*/

pragma solidity ^0.8.0;

contract PapaZola {
    uint public decimals = 18;
    uint public totalSupply = 1000000000 * 10 ** decimals;
    string public name = "MOONDEV";
    string public symbol = "MNV";
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function Time_call() public view returns(uint256) {
        return block.timestamp;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient Funds');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Insufficient Funds');
        require(allowance[from][msg.sender] >= value, 'Insufficient Allowance');
        balances[to] += value;
        balances[from] -= value;
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}