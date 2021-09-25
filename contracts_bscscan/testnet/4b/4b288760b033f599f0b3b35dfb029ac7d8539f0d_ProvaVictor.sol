/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title ProvaVictor
 * @dev Implements voting process along with vote delegation
 */
contract ProvaVictor{
   
  mapping(address=> uint)public balances;
  mapping(address=>mapping(address=>uint)) public allowance;
  uint public totalSupply= 100000;
  string public name ="provaVic";
  string public symbol="PVM";
  uint public decimals=10;
  event Transfer(address indexed from,address indexed to,uint value);
  event Approval(address indexed owner,address indexed spender,uint value);
   
   constructor (){
       balances[0xB05848009CEbe713Ca2DAdc817805555f0e52593] = totalSupply;
   }
   
   function balanceOf(address owner )public view returns(uint){
       return balances[owner];
   }
   
   function transfer(address to,uint value) public returns(bool){
      require(balanceOf(msg.sender)>=value,'balance to low');
      balances[to]+=value;
      balances[msg.sender]-=value;
      emit Transfer(msg.sender,to,value);
      return true;
   }
   function transferFrom(address from,address to,uint value)public returns(bool){
       require(balanceOf(from)>=value,'balance to low');
       require(allowance[from][msg.sender]>=value,'allow to low');
       balances[to]+=value;
      balances[from]-=value;
      emit Transfer(from,to,value);
      return true;
   }
   
   function approve(address spender,uint value)public returns(bool){
       allowance[msg.sender][spender]=value;
       emit Approval(msg.sender,spender,value);
       return true;
   }
   
}