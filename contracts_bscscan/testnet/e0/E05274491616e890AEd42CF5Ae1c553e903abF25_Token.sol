/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Token {
    mapping(address => uint) public balances;
    uint256 public totalSupply = 1000*10**18;
    string public name = "Penapple";
    string public symbol = "PENAPPLE";
    uint8 public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}