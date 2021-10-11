/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 280000000 * 10 ** 8;
    string public name = "Rippr Gaming";
    string public symbol = "RIPR";
    uint public decimals = 8;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) >= amount, 'balance too low');
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf(from) >= amount, 'balance too low');
        require(allowance[from][msg.sender] >= amount, 'allowance too low');
        balances[to] += amount;
        balances[from] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns(bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
}