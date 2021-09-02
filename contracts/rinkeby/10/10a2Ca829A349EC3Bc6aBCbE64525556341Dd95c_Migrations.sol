/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;


// 
contract Migrations {
  address public owner;
  uint public lastCompletedMigration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  /**
   * @notice set lastCompletedMigration variable
   * @param completed - id of the desired migration level
   */
  function setCompleted(uint completed) external restricted {
    lastCompletedMigration = completed;
  }
}