/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract DevToken{
  // name
  string public name = "Dev Token";
  // Symbol or Ticker
  string public symbol = "DEV";
  // decimal 
  uint256 public decimals = 18;
  // totalsupply
  uint256 public totalSupply;
  
  // transfer event
  event Transfer(address indexed sender,address indexed to,uint256 amount);

  // Approval
  event Approval(address indexed From , address indexed spender, uint256 amount);
  
 // balance mapping  
  mapping (address => uint256) public balanceOf;
  
  // allowance mapping
  mapping(address => mapping(address => uint256)) public allowance;
//   allowance[msg.sender][_spender] = amount
//  a[msg.sender][_spenderaddres ] = 1000;
  
  constructor(uint256 _totalsupply)  {
      totalSupply = _totalsupply; 
      balanceOf[msg.sender] = _totalsupply;
  }
  
  // transfer function
  function transfer(address _to,uint256 _amount) public returns(bool success){
  // the user that is transferring must have suffiecent balance
  require(balanceOf[msg.sender] >= _amount , 'you have not enough balance');
  // subtracnt the amount from sender
  balanceOf[msg.sender] -= _amount;
  // add the amount to the user transfered
  balanceOf[_to] += _amount;
  emit Transfer(msg.sender,_to,_amount);
  return true;
  }

  // approve function
  function approve(address _spender,uint256 _amount) public returns(bool success){
  // increase allownce
  allowance[msg.sender][_spender] += _amount;
  // emit allownce event
  emit Approval(msg.sender,_spender,_amount);
  return true;
  }
  
  // transferFrom function
  function transferFrom(address _from,address _to,uint256 _amount) public returns(bool success){
  // check the balance of from user
  require(balanceOf[_from] >= _amount,'the user from which money has to deducted doesnt have enough balance');
  // check the allownce of the msg.sender
  require(allowance[_from][msg.sender] >= _amount,'the spender doest have required allownce');
  // subtract the amount from user
  balanceOf[_from] -= _amount;
  // add the amount to user
  balanceOf[_to] += _amount;
  // decrese the allownce
  allowance[_from][msg.sender] -= _amount;
  // emit transfer
  emit Transfer(_from,_to,_amount);
  return true;
  }
 
  
}