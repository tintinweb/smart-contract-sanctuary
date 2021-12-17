/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.8.2;
contract Token
{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000 * 10 ** 8;
    string public name = "MainHoonIndian";
    string public symbol = "MHI";
    uint public decimals = 8;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor()
    {
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address owner) public view returns(uint)
    {
        return balances[owner];
    }
    function transfer(address to, uint value) public returns(bool)
    {
        require(balanceOf(msg.sender) >= value, 'Low Balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool)
    {
        require(balanceOf(from) >= value, 'Low Balance');
        require(allowance[from][msg.sender] >= value, 'Low Allowance');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint value) public returns(bool)
    {
        allowance[msg.sender][spender] = value;
        emit  Approval(msg.sender, spender, value);
        return true;
    }
}