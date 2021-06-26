/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.8.0;
 
contract SomeContract
{
    string public constant name = "Gunpowder";
    string public constant symbol = "GUN";
    uint8 public constant decimals = 3;
    uint public totalSupply = 0;
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address _from, address _to, uint _value);
    event Approval(address _from, address _spender, uint _value);
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "You shell not pass!!!");
        _;
    }
    
    modifier canTransact(address _addressX, address _addressY, uint _tokens)
    {
        require(balances[_addressX] >= _tokens && balances[_addressY] + _tokens >= balances[_addressY]);
        _;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function mint(address _address, uint _coins) public onlyOwner payable
    {
        require(totalSupply + _coins >= totalSupply && balances[_address] + _coins >= balances[_address]);
        totalSupply += _coins;
        balances[_address] += _coins;
    }
    
    function balanceOf(address _address) public view returns(uint)
    {
        return balances[_address];
    }
    
    function balanceOf() public view returns(uint)
    {
        return balances[msg.sender];
    }
    
    function transfer(address _address, uint _tokens) public canTransact(msg.sender, _address, _tokens) payable
    {
        require(balances[msg.sender] >= _tokens && balances[_address] + _tokens >= balances[_address]);
        balances[msg.sender]-=_tokens;
        balances[_address]+=_tokens;
        emit Transfer(msg.sender, _address, _tokens);
    }
    
    function transferFrom(address _addressX, address _addressY, uint _tokens) public canTransact(_addressX, _addressY, _tokens) payable
    {
        
        balances[_addressX]-=_tokens;
        balances[_addressY]+=_tokens;
        emit Transfer(_addressX, _addressY, _tokens);
        emit Approval(_addressX, msg.sender, _tokens);
    }
    
    function approve(address _address, uint _tokens) public payable
    {
        allowed[msg.sender][_address] = _tokens;
        emit Approval(msg.sender, _address, _tokens);
    }
    
    function allowance(address _addressX, address _addressY) public view returns(uint)
    {
        return allowed[_addressX][_addressY];
    }
}