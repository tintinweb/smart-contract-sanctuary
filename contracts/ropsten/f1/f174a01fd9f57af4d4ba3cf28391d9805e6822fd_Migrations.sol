pragma solidity 0.4.24;

// File: contracts/Migrations.sol

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner)
      _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address _newAddress) public restricted {
    Migrations upgraded = Migrations(_newAddress);
    upgraded.setCompleted(last_completed_migration);
  }
}