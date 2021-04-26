/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.8.2;

contract MPT1 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 39000000 * 10 ** 18;
    string public name = "My Pocket Token 1";
    string public symbol = "MPT1";
    uint public decimals = 18;
   
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public  view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public payable returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transfreFrom(address from, address to, uint value) public payable returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
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
    //SPDX-License-Identifier: <SPDX- UNLICENSE
}