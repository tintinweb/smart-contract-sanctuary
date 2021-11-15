//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract BasicToken{

  address public Owner;
  uint public totalSupply = 1000000;
  string public name = "MHToken";
  mapping(address => uint) balance;

   constructor (){

     Owner = msg.sender;
     balance[msg.sender] = totalSupply;


   }


   function transfer(address to, uint _amt) public{
      require(_amt != 0, "amount should not be 0");
      require(to != address(0), "zero address not allowed");

      balance[msg.sender] -= _amt;
      balance[to] += _amt;

   }

   function _balance(address to) public view returns(uint){
     require(to != address(0), "zero address not allowed");
     return balance[to];

   }

}

