/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.5.0;

contract LedgerBalance {
   mapping(address => uint) public balances;
   mapping(address => mapping(address => uint)) public balancesArray;

   function updateBalance(uint newBalance) public {
      balances[msg.sender] = newBalance;
   }
   function updateBalanceArray(uint newBalance, address to) public{
       balancesArray[msg.sender][to] = newBalance;
   }
}