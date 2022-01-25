/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{
  //Variable

  /*
  โครงสร้างการนิยามตัวแปร 
  type access_modifier name;
  */

  //Private
  //bool _status;
  string _name;
  //int _amount=0;
  uint _balance; //ค่าบวกเท่านั้น

  constructor(string memory name,uint balance){
      require(balance>=500,"balance greater and equal 500");
      _name = name;
      _balance = balance;
  }

  function getBalance() public view returns(uint balance){
      return _balance;
  }

  /*function deposite(uint amount) public{
      _balance+=amount;
  }*/
}