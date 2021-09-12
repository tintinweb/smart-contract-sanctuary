/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) virtual public returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)virtual external returns (bool success);
    function approve(address _spender, uint256 _value) virtual external returns (bool success);
    function allowance(address _owner, address _spender) virtual external returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) override public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0){
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else{ 
        return false; 
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) override external returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else { 
        return false; 
      }
    }

    function balanceOf(address _owner)override public view returns (uint256){
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)override external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)override external returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;    
}