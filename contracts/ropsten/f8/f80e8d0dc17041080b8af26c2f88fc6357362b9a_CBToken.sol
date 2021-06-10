/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract CBToken {

    string public name;
    uint8 public decimals;
    string public symbol;  
    uint public totalSupply;
    
	mapping (address => uint256) balanceOf;
    mapping (address => mapping (address => uint256)) allowed;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "CabbageCoin";                   
        symbol = "CBT";
        decimals = 3; 
        totalSupply = 20000;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function balanceOfCount(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
       
        require(_to!=address(0));
        require(balanceOf[msg.sender] >= _value ); 
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_to!=address(0));
        require(balanceOf[_from] >= _value); 
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[ _to] + _value >= balanceOf[ _to]);
        
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}