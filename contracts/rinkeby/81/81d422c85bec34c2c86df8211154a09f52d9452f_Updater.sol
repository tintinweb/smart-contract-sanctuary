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
contract Updater {
   function updateBalance() public returns (uint,uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      ledgerBalance.updateBalance(10);
      ledgerBalance.updateBalanceArray(100,address(this));
      return (ledgerBalance.balances(address(this)),ledgerBalance.balancesArray(address(this),address(ledgerBalance)));
   }
}