/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.15;

contract VANC {
  // Create a table so that we can map addresses
  // to the balances associated with them
  mapping(address => uint256) balances;
  // Create a table so that we can map
  // the addresses of contract owners to
  // those who are allowed to utilize the owner&#39;s contract
  mapping(address => mapping (address => uint256)) allowed;
  // In this case, the total supply
  // of MyERCToken is fixed, but
  // it can very much be changed
  uint256 _totalSupply = 100000000;
  // Owner of this contract
  address public owner;
  
  function totalSupply() constant returns (uint256 theTotalSupply) {
    // Because our function signature
    // states that the returning variable
    // is "theTotalSupply", we&#39;ll just set that variable
    // to the value of the instance variable "_totalSupply"
    // and return it
    theTotalSupply = _totalSupply;
    return theTotalSupply;
  }
  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    // Fire the event "Approval" to execute any logic
    // that was listening to it
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  // Note: This function returns a boolean value
  //       indicating whether the transfer was successful
  function transfer(address _to, uint256 _amount) returns (bool success) {
    // If the sender has sufficient funds to send
    // and the amount is not zero, then send to
    // the given address
    if (balances[msg.sender] >= _amount 
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      // Fire a transfer event for any
      // logic that&#39;s listening
      Transfer(msg.sender, _to, _amount);
        return true;
      } else {
        return false;
      }
   }
   
   function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
      && allowed[_from][msg.sender] >= _amount
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
    balances[_from] -= _amount;
    balances[_to] += _amount;
    Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}