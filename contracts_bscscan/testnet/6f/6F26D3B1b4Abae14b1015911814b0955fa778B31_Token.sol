/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
    
contract Token {
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public decimals = 18;
    uint public totalSupply = 10000 * 10 ** decimals;
    string public name = "zakah";
    string public symbol = "ZKH";
    address public owner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);    

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }   

    function transfer(address to, uint value) public returns(bool) {
        if(balanceOf(msg.sender) < value) {
            revert("Balance is too low");
        }

        balances[to] += value;
        balances[msg.sender] -= value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        if(balanceOf(from) < value) {
            revert("Balance too low");
        }
        if(allowance[from][msg.sender] < value) {
            revert("Allowance too low");
        }

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

    function burn(address from, uint value) public {
        if(from == address(0)) {
            revert("Cant burn from a dead wallet");
        }

        if(msg.sender != owner) {
            revert("You are not the owner");
        }

        if(balances[from] < value) {
            revert("Burn amount exceeds balance");
        }


        balances[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }

    function mint(address from, uint value) public {
        if(from == address(0)) {
            revert("Cant burn from a dead wallet");
        }

        if(msg.sender != owner) {
            revert("You are not the owner");
        }

        totalSupply += value;
        balances[from] += value;

        emit Transfer(address(0), from, value);
    }

    function transferOwnership(address to) public {
        if(msg.sender != owner) {
            revert("You are not the owner");
        }

        owner = to;
    }
}