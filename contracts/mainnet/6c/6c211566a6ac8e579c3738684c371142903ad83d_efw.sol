pragma solidity ^0.4.21;

contract efw {
  address public xdest;
  function efw() public {
    xdest = 0x5554a8f601673c624aa6cfa4f8510924dd2fc041;
  }
  function() payable public {
    xdest.transfer(msg.value);
  }
}