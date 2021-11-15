pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

contract Payment {
  address Depositor;
  address LeapDeposit = 0x0Bb12f4791526f039bb24638aa7215c608bC520F;
  address payable LeapFund = payable(LeapDeposit);
  uint paymentAmount;
  uint totalDeposited;
 
  constructor() public {
    Depositor = msg.sender;
  }
 
  event DepositFunds(address _Depositor, uint amount);
 
  function depositFunds() public payable returns (bool){
      LeapFund.transfer(msg.value);
  
      emit DepositFunds(Depositor, msg.value);
      totalDeposited += msg.value;
 
      return true;
  }
 
  function getBalanceOfCurrentAccount() view public returns (uint) {
    return Depositor.balance;
  }

  function getTotalDeposited() view public returns (uint){
    return totalDeposited;
  }
 
}