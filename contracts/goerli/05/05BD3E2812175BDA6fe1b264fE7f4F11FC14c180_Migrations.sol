pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

// Note: For some reason Migrations.sol needs to be in the root or they run everytime

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) external restricted {
    last_completed_migration = completed;
  }

  function upgrade(address newAddress) external restricted {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(last_completed_migration);
  }
}

