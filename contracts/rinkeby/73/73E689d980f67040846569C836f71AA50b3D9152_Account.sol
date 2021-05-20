/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Account {
   
   int[] transactions;

   function getTransactions() public view returns (int[] memory) {
      return transactions;
   }
   
   function addTransaction(int _transaction) public {
      transactions.push(_transaction);
   }

   function getBalance() public view returns (int) {
      int balance = 0;

      for(uint i = 0; i < transactions.length; i++) {
         balance += transactions[i];
      }

      return balance;
   }
}