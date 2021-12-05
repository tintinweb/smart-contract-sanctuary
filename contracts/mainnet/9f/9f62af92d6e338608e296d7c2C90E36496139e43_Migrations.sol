/// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

contract Migrations {
    address public owner = msg.sender;

    /// A function with the signature `last_completed_migration()`, returning a uint, is required.
    uint256 public lastCompletedMigration;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    /// A function with the signature `setCompleted(uint)` is required.
    function setCompleted(uint256 completed) external restricted {
        lastCompletedMigration = completed;
    }
}