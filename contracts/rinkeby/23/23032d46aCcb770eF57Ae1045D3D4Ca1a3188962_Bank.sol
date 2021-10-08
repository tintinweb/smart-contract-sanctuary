/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import library ต่างๆ


contract Bank{ //parcal case
   
   //uint balance; //private default
   //uint public balance;
   //uint _balance;
   
   mapping(address => uint) _balances;
   uint _totalSupply;
  
  function deposit() public payable { // modifiler ใน function
       //msg.value  	//ดึงค่าเงินจากกระเป๋า metamark
       _balances[msg.sender] += msg.value;
       _totalSupply += msg.value;
   }

  function withdraw(uint amount ) public {
	    require(amount <= _balances[msg.sender] , "Not Enough money");

    	payable(msg.sender).transfer(amount); // คือการ transfer จาก smartcontract bank ไปให้
       _balances[msg.sender] -= amount;
       _totalSupply -= amount;
   }
     
   function checkBalance() public view returns(uint balance) {
       //return _balance; 
       return _balances[msg.sender]; 
   }
   
   function checkTotalSupply() public view returns(uint totalSupply){
       return _totalSupply;
   }
   
}