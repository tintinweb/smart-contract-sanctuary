/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Token
{
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) balances;
    address owner;
    event Transfer(address source, address target, uint amount);
    event Approval(address source, address spender, uint amount);
    string public constant name = "Catcoin";
    string public constant symbol = "CAT";
    uint totalSupply;
    uint8 public constant decimals = 8;

    constructor()
    {
        owner = msg.sender;
    }

    function mint(address target, uint amount) public
    {
        require(msg.sender == owner, "You are not the owner");

        totalSupply += amount;
        balances[target] += amount;
    }

    function balanceOf() public view returns(uint balance)
    {
        return balances[msg.sender];
    }

    function balanceOf(address target) public view returns(uint balance)
    {
        return balances[target];
    }

    function transfer(address target, uint amount) public
    {
        require(balances[msg.sender] >= amount, "You do not have enough coins");

        balances[msg.sender] -= amount;
        balances[target] += amount;

        emit Transfer(msg.sender, target, amount);
    }

    function transferFrom(address source, address target, uint amount) public
    {
        require(allowed[source][msg.sender] >= amount, "You have no rights to transfer coins");
        require(balances[source] >= amount, "You do not have enough coins");

        allowed[source][msg.sender] -= amount;
        balances[source] -= amount;
        balances[target] += amount;

        emit Transfer(source, target, amount);
        emit Approval(source, msg.sender, allowed[source][msg.sender]);
    }

    function approve(address spender, uint amount) public
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function allowance(address source, address spender) public view returns(uint amount)
    {
        return allowed[source][spender];
    }
}