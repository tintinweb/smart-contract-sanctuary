/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Token {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    string  public name = "Saleh Token";
    string  public symbol = "STN";
    uint8  public decimals = 18;
    uint256  public totalSupply = 10000000000000000;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    constructor (string memory _name , string memory _symbol , uint8 _decimals , uint256 _totalSupply) public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        
        balanceOf[msg.sender] += totalSupply;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        uint256 _allowance = allowed[_from][msg.sender];
        
        require(balanceOf[_from] >= _value && _allowance >= _value);
        
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }




}