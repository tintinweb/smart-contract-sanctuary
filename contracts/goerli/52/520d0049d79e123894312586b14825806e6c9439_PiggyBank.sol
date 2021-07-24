/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PiggyBank {
  uint public goal;
  address public owner;

  constructor(uint _goal) {
    goal = _goal;
    owner = msg.sender;
  }

  receive() external payable{}

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdraw() public {
    if (getBalance() > goal) {
      selfdestruct(payable(owner));
    }
  }
}