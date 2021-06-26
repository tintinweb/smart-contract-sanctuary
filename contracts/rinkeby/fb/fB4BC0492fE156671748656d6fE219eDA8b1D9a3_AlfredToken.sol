/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract AlfredToken{
    string public constant name = "AlfredThaddeusCranePennyworth";
    string public constant symbol = "ATCP";
    uint8 public constant decimals = 6;
    
    address owner;
    
    uint public totalSupply = 0; // 10 ATCP
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address sender, address getter, uint count);
    event approval(address allowed, address toSend, uint count);

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier canTransfer(address _from, address _to, uint _value)
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
    
    function transfer(address _to, uint _value) public canTransfer(msg.sender, _to, _value) payable
    {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from, _to, _value) payable
    {
        require(allowed[msg.sender][_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[msg.sender][_from] -= _value;
        emit Transfer(_from, _to, _value);
        emit approval(msg.sender, _from, allowed[msg.sender][_from]);
    }
    
    function approve(address _spender, uint _value) public payable
    {
        allowed[msg.sender][_spender] = _value;
        emit approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    }
    
    function allowance(address _owner, address _spender) public payable returns(uint)
    {
        return allowed[_owner][_spender];
    }
}