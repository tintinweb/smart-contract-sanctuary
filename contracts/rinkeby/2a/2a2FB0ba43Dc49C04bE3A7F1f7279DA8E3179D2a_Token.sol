/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL -3.0
pragma solidity ^0.8.6;

contract Token {
    string public name = "LCOIN";
    string public symbol = "LCN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000 ether;
    mapping(address => uint) private _balances;
    mapping (address => mapping (address => uint256)) public allowed;
    constructor(){
        _balances[msg.sender] = totalSupply;
    }
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _from, address indexed _to, uint _value);
    function balanceof(address _owner) public view returns (uint256 balance){
        
        balance = _balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool succes){
        require(_balances[msg.sender] >=_value,"Eroor");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    
        
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        require(_balances[_from] >= _value, "Eroor");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;    
        
    }
    
    function approve(address _spender, uint _value) public returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    function allowance(address _owner, address _spender ) public view returns(uint remaining){
        return allowed[_owner][_spender];
    }
    

}