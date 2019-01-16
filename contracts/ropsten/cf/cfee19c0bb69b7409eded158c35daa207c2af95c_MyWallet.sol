pragma solidity ^0.4.25;

contract MyWallet {
  uint256 _balance;

  function setBalance(uint256 balance) returns (uint256) {
    _balance = balance;
  }

  
}