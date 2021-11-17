pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;

  // A function with the signature `last_completed_migration()`, returning a uint, is required.
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  // A function with the signature `setCompleted(uint)` is required.
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}