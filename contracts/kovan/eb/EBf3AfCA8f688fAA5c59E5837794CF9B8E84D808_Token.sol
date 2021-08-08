/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    // mapping(from, mapping(spender, value))
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed  owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = 1000000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[msg.sender], 'invalid transfer amount');
        
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        
        emit Transfer(msg.sender, _to,_value );
        
        return true;
    }
    
    function transfer(address _from, address _to, uint256 _value) internal {
        
        require(_to != address(0));
        
        balanceOf[_from] = balanceOf[_from] - _value;
        
        balanceOf[_to] = balanceOf[_to] + _value;
        
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) external returns (bool success) {
        // spender must not be empty
        require( _spender != address(0));
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender,_value );
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[_from], " Not enough token to transfer");
        
        require(_value <= allowance[_from][msg.sender], "transfer value exceeds approved value!");
        
        require(_to != address(0), 'invalid transfer destination address');
        
        require(_from !=address(0), ' invalid transfer source address');
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        
        transfer(_from, _to, _value);
        
        return true;
    }
    
}