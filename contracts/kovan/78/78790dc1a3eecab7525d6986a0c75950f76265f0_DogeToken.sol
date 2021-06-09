/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
contract DogeToken{
   //name of the Token
   string public name = "DogeToken";
   //Symbol
   string public symbol = "DOT";
   //decimal
   uint256 public decimal = 18;
   //Total suply
   uint256 public totalSupply;
    // Define a event for Transfer function that will notify clients and  mapping which maps balance of an account
    event Transfer(address indexed sender,address indexed to,uint256 amount);
    mapping (address => uint256) public balanceOf;
    
    //Defining a mapping for allowance
    mapping(address => mapping(address => uint256)) public allowance;
   // allowance[msg.sender][_spender] = amount;
   
   //event 
   event Approval(address indexed From , address indexed spender, uint256 amount);
    
    constructor(uint256 _totalsupply){
        totalSupply = _totalsupply;
        balanceOf[msg.sender] = _totalsupply;
    }
    
    
    
    
    // transfer function
   function transfer(address _to, uint256 _amount) public returns(bool success) {
       //the sender must have sufficent balance in their account
       require(balanceOf[msg.sender] >= _amount, 'Not sufficent balance');
       //subtract the amount of sender
       balanceOf[msg.sender] -= _amount;
       //add the amount to the transfered user
       balanceOf[_to] += _amount;
       emit Transfer(msg.sender, _to, _amount);
       return true;
   }
   
   
   
   // approval function
   function approve(address _spender, uint256 _amount) public returns(bool success){
       //address and allowance
        allowance[msg.sender][_spender] += _amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
   }
      
   //TransferFrom function
  function transferFrom(address _from,address _to,uint256 _amount) public returns(bool success){
  // check the balance of from user
  require(balanceOf[_from] >= _amount,'doesnt have enough balance');
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