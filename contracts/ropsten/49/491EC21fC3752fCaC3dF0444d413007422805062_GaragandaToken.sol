/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract GaragandaToken
{
    string constant public name = "Garaganda";
    string constant public symbol = "GRG";
    uint8 constant public decimals = 5;

    uint public totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address immutable owner;

    event Transfer(address _from, address _to, uint value);
    event Approval(address _from, address _to, uint value);

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier enoughTokens(address addr, uint value)
    {
        require(balances[addr] >= value);
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    function mint(address receiver, uint value) public onlyOwner
    {
        totalSupply += value;
        balances[receiver] += value;
    }

    function balanceOf(address addr) public view returns(uint)
    {
        return balances[addr];
    }

    function balanceOf() public view returns(uint)
    {
        return balanceOf(msg.sender);
    }

    function transfer(address _to, uint value) public enoughTokens(msg.sender, value)
    {
        balances[msg.sender] -= value;
        balances[_to] += value;
        emit Transfer(msg.sender, _to, value);
    }

    function transferFrom(address _from, address _to, uint value) public enoughTokens(_from, value)
    {
        require(allowance(_from, _to) >= value);
        balances[_from] -= value;
        balances[_to] += value;
        allowed[_from][_to] -= value;
        emit Transfer(_from, _to, value);
        emit Approval(_from, _to, allowance(_from, _to));
    }

    function approve(address _spender, uint value) public
    {
        allowed[msg.sender][_spender] += value;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    }

    function allowance(address _from, address _spender) public view returns(uint)
    {
        return allowed[_from][_spender];
    }
}