/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-2.0

pragma solidity >=0.7.0 <0.9.0;

contract Frog{
    string constant name = "Frog";
    string constant symbol = "FRG";
    mapping(address => uint) balances;
    address immutable owner;
    uint totalSupply;
    uint8 constant decimals = 69;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address sender, address recipient, uint amount);
    event Approval(address sender, address recipient, uint amount);
    modifier onlyOwner() {
        require (owner == msg.sender, "Permission denied");
        _;
    }

    modifier checkAllowance(address sender, uint amount) {
        require (allowed[sender][msg.sender] >= amount);
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function mint(address addr, uint amount) onlyOwner public {
        require (msg.sender == owner);
        balances[addr] += amount;
        totalSupply+= amount;
    }
    function balanceOf(address addr) public view returns (uint balance){
        return balances[addr];
    }
    function balanceOf() public view returns (uint balance){
        return balances[msg.sender];
    }
    function transfer(address recipient, uint amount) public {
        require (balances[msg.sender] >= amount);
        balances[recipient] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint amount) checkAllowance(sender, amount) public {
        require (balances[sender] >= amount);
        balances[recipient] += amount;
        balances[sender] -= amount;
        allowed[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        emit Approval(sender, msg.sender, allowed[sender][msg.sender]);
    }

    function approve (address user, uint amount) public {
        allowed[msg.sender][user] = amount;
        emit Approval(msg.sender, user, amount);
    }
    function getAllowance (address sender, address recipient) public view returns (uint) {
        return allowed[sender][recipient];
    }
}