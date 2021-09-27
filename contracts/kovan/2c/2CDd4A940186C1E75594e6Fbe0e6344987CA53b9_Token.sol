/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}