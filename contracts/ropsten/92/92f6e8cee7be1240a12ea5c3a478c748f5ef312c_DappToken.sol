/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ERC20Interface{
    
    function transfer(address to, uint256 tokens) external returns (bool success);
    
    function approve(address spender, uint256 tokens) external returns (bool success);
    
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DappToken is ERC20Interface{
    string public name;
    string public symbol;
    uint256 public TotalSupply;
    
    mapping(address => uint256) public BalanceOf;
    mapping(address => mapping(address => uint256)) public Allowance;
    
    constructor(uint256 _initialSupply){
        name = "DEMO Token";
        symbol = "DEMO";
        BalanceOf[msg.sender] = _initialSupply;
        TotalSupply = _initialSupply;
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(BalanceOf[msg.sender] >= _value);
        
        BalanceOf[msg.sender] -= _value;
        BalanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success){
        Allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(_value <= BalanceOf[_from]);
        
        require(_value <= Allowance[_from][msg.sender]);
        
        Allowance[_from][msg.sender] -= _value;
        
        BalanceOf[_from] -= _value;
        BalanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
}