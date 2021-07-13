/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

//SPDX-License-Identifier: none
pragma solidity ^0.8.4;
contract erc20
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(address _owner)
    {
        balances[_owner] = 100000000000000000;
        emit Transfer(address(0), _owner, 100000000000000000);
    }
    
    function name() public pure returns (string memory)
    {
        return "nameToken";
    }
    
    function symbol() public pure returns (string memory)
    {
        return "symbolToken";
    }
    
    function decimals() public pure returns (uint8)
    {
        return 8;
    }
    
    function totalSupply() public pure returns (uint256)
    {
        return 100000000000000000;
    }

    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        if(balances[msg.sender] < _value)
            return false;
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        if(balances[_from] < _value || allowed[_from][msg.sender] < _value)
            return false;
            
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[msg.sender] += _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}