pragma solidity ^0.4.15;

// File: contracts/Migrations.sol

contract Migrations {
  address public owner;
  uint256 public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner)
      _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted public {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted public {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}