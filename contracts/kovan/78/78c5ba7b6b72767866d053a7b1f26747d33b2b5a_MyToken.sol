/**
 *Submitted for verification at Etherscan.io on 2021-11-04
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

  // mapping for balances
  mapping (address => uint) public balances;
   // mapping for allowances
  mapping (
    address => mapping(address => uint)
    ) public allowances;

  constructor() public {
    // set sender's balance to total supply
    balances[msg.sender] += supply;
    
  }

  function totalSupply() public pure returns (uint256) {
    // return total supply
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    // return the balance of _owner
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    // transfer `_value` tokens from sender to `_to`
    require(balances[msg.sender]>=_value);
    balances[msg.sender]-=_value;
    balances[_to]+=_value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    require(balances[_from]>=_value);
    require(allowances[_from][msg.sender]>=_value);
    balances[_from]-=_value;
    balances[_to]+=_value;
    allowances[_from][msg.sender]-=_value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // return how much `_spender` is allowed to spend on behalf of `_owner`
    return allowances[_owner][_spender];
  }
}