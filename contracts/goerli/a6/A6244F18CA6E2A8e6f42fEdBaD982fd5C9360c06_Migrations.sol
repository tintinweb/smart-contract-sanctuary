/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// File: contracts/Migrations.sol

pragma solidity ^0.5.12;

contract Migrations {
    address public owner;
    uint256 public lastCompletedMigration;

    modifier restricted() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor() public {
        owner = msg.sender;
    }

    function setCompleted(uint256 completed) public restricted {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) public restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}