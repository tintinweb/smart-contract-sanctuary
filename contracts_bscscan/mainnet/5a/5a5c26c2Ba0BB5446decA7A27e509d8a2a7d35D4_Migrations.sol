// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Migrations {
    address public immutable owner = msg.sender;
    /* solhint-disable var-name-mixedcase */
    uint256 public last_completed_migration;
    /* solhint-enable var-name-mixedcase */

    modifier restricted() {
        require(msg.sender == owner, "Migrations: caller is not the owner");
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}