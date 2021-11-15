// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations#initial-migration
contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _; // Execute the body of the function
  }

  // A function with the signature `setCompleted(uint)` is required.
  // + Restrict this call to the owner of this Migration contract
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

}

