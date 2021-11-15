// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity >=0.8.6;

contract Migrations {
    address public owner = msg.sender;
    // solhint-disable-next-line
    uint256 public last_completed_migration;

    modifier restricted() {
        // solhint-disable-next-line
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}

