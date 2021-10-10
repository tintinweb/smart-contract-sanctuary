/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;


contract MyToken {
  // total supply of token
  uint256 constant supply = 1000000;

  // event to be emitted on transfer
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // event to be emitted on approval
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  
  mapping (address => uint) public balances;


   
  mapping (
 address => mapping(address => uint)
 ) public allowances;



  constructor() public {
    balances[msg.sender] += supply;
  }

  function totalSupply() public pure returns (uint256) {
    return supply; 
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
   require (balances[msg.sender]>= _value );
   balances[_to] += _value;
   balances[msg.sender] -= _value;
   emit Transfer(msg.sender, _to,_value);
   // NOTE: sender needs to have enough tokens
   return true; 
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
   require(balances[_from] >= _value);
   require(allowances[_from][msg.sender] >= _value); 
   balances[_to] += _value;
   balances[_from] -= _value;
   emit Transfer(_from, _to,_value);
   allowances[_from][msg.sender] -= _value;


   return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;

  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    return allowances[_owner][_spender];
  }
}