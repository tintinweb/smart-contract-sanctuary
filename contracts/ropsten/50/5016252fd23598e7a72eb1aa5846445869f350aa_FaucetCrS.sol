/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.9;

contract FaucetCrS {
  function getStuff(uint amount) public {
    require(amount <= 100000000000000000);
    payable(msg.sender).transfer(amount);
  }

  receive() external payable {}
}