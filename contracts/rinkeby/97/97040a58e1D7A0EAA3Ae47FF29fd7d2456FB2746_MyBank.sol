/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyBank{
      mapping(address => uint) _balances;
      
      function deposit(uint amount) public{
        // _balance += amount;
        _balances[msg.sender] += amount;
    }
      function withdraw(uint amount) public{
        // _balance -= amount;
        _balances[msg.sender] -= amount;
    }
    
      function check_balance() public view returns(uint bal) {
          return _balances[msg.sender];
     }
}