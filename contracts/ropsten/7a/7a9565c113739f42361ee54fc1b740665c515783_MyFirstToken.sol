/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract MyFirstToken
{
    string public constant name = "MyFirstToken";
    string public constant symbol = "MFT";
    uint8 public constant decimals = 3;
    uint public totalSupply = 0;
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address _from, address _to, uint _value);
    event Approval(address _from, address _spender, uint value);
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "You shell not pass!");
        _;
    }
    
    modifier canTransact(address _from, address _to, uint _value)
    {
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to]);
        _;
    }
    
    constructor()
    {
        owner = msg.sender;
    }
    
    function mint(address _to, uint _value) public onlyOwner payable
    {
        require(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        totalSupply += _value;
        balances[_to] += _value;
    }
    
    function balanceOf(address _owner) public view returns(uint)
    {
        return balances[_owner];
    }
    
    function balanceOf() public view returns(uint)
    {
        return balances[msg.sender];
    }
    
    function transfer(address _to, uint _value) public canTransact(msg.sender, _to, _value) payable
    {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public canTransact(_from, _to, _value) payable
    {
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, _value);
    }
    
    function approve(address _spender, uint _value) public payable
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _from, address _spender) public view returns(uint)
    {
        return allowed[_from][_spender];
    }
}