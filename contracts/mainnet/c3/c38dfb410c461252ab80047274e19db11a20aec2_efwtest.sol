pragma solidity ^0.4.24;

contract efwtest {
  address public xdest;
  event DepositFunds(address from, uint amount);
  function efwtest() public {
    xdest = 0x5554a8f601673c624aa6cfa4f8510924dd2fc041;
  }
  function() payable public {
    DepositFunds(msg.sender, msg.value);
    xdest.transfer(msg.value);
  }
}