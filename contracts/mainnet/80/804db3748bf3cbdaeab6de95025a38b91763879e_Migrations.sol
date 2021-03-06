/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity >=0.4.22 <0.8.0;


// SPDX-License-Identifier: MIT
contract Migrations {
  address public owner = msg.sender;
  uint256 public last_completed_migration;

  modifier restricted() {
    require(msg.sender == owner, "This function is restricted to the contract's owner");
    _;
  }

  function setCompleted(uint256 completed) public restricted {
    last_completed_migration = completed;
  }
}