/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity >=0.4.25 <0.7.0;


// SPDX-License-Identifier: MIT
contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}