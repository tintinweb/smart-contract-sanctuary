/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract TokenNew 
{
    address owner;
    string public constant name = "FirstSecondThird";
    string public constant symbol = "FST";
    uint8 public constant decimals = 8;
    uint public totalSupply;
    
    mapping (address => uint) balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _from, address indexed _to, uint _value);
    
    constructor()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
    require(owner == msg.sender);
    _;
    }
    
    function mint(address _to, uint _value) onlyOwner public payable
    {
        require(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        totalSupply += _value;
    }
    
    function balanceOf(address _owner) public view returns(uint)
    {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public payable
    {
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable
    {
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }
    
    function approve(address _spender, uint _value) public payable
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns(uint)
    {
        return allowed[_owner][_spender];
    }
}