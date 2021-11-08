/**
 *Submitted for verification at Etherscan.io on 2021-11-07
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

  // TODO: create mapping for balances
      mapping(address => uint) public balances; // This is 
      
   // TODO: create mapping for allowances
      mapping (
        address => mapping(address => uint)
      ) public allowances;

  constructor() public {
    // This is a function which sets the balances of the sender to be equal to the total supply
    // Args:
    //         No input.
    // Output:
    //         No output
    balances[msg.sender]=supply; 
  }

  function totalSupply() public pure returns (uint256) {
    // This function returns the total supply
    // Args: 
    //         No input
    // Output:
    //         supply - The total supply 
      return supply; 
  }

  function balanceOf(address _owner) public view returns (uint256) {
    // This function takes as input the address of an address owner and outputs the balance of the owner's address
    // Args:
    //         _owner - This is the address of the owner 
    // Output:
    //         balances[_owner] - This returns how much balance the owner has
    return balances[_owner];  // This function
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens
    require(_value <= balances[msg.sender]);
    balances[_to] += _value;
    balances[msg.sender] -= _value;
    emit Transfer(msg.sender,  _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    // This function transfer some value from one address to another
    
    // Args:
    //         _from - The address which the tokens will be sent from i.e., the sender
    //         _to - The address which the tokens will be sent to
    //         _value - The amount of tokens which the address "_from" will send to address "_to"
    // Output:
    //         True of False - True if the transfer is sent
    
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    
    require(_value <= balances[msg.sender]);
    require(allowances[_from][msg.sender] >= _value);
    balances[_from]-= _value;
    balances[_to] += _value;
    allowances[_from][msg.sender] -= _value;
    emit Transfer(_from,  _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    // This function approves whether the value which the `_spender` is allowed to spend is equal to his allowance
    // and then returns True if approved
    // NOTE: if an allowance already exists, it should be overwritten

    // Args:
    //         _spender - The adress of the spender.
    //         _value - The amount of tokens which we check for.
    // Output:
    //         True - If the value is equal to the allowances.
    allowances[msg.sender][_spender] = _value; // Here we're assigning the allowance of the _spender
    emit Approval(msg.sender, _spender, _value);  // Here we're checking if the allowance is OKAY
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // This function returns how much a `_spender` is allowed to spend on behalf of an `_owner`

    // - _spender and _owner are the names of some parameters of certain functions. The ERC-20 standard allow an address (_owner) to give 
    // an allowance to another address (_spender) to be able to retrieve tokens from it; in other words, _spender can spend some tokens that 
    // are in _owner’s balance. This is useful, for example, for contracts that act as sellers. Contracts cannot monitor for events, so if a 
    // buyer were to transfer tokens to the seller contract directly that contract wouldn't know it was paid. Instead, the buyer permits the 
    // seller contract to spend a certain amount, and the seller transfers that amount. This is done through a function the seller contract 
    // calls (the function approve), so the seller contract can know if it was successful.

    // Args:
    //         _owner - The address of the owner.
    //         _spender - The adress of the spender.
    // Output:
    //         _allowances[_owner][_spender] - This is the amount of money which the _spender is allowed to spend on behalf of the _owner
    return allowances[_owner][_spender];
  }
}