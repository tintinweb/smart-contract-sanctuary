// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeMath.sol";

contract BrownRollToken {
    using SafeMath for uint256;
    
    string public constant name = "Brown Roll Token";
    string public constant symbol = "BRL";
    uint8 public constant decimals = 15;
    uint256 public constant totalSupply = 1000000000000000000000;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value, "unauthorized");
        require(balances[_from] >= _value, "insufficient balance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_to].sub(_value);
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}