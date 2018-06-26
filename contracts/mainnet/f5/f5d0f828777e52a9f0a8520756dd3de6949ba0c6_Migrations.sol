pragma solidity ^0.4.18;

// File: contracts/Migrations.sol

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner)
            _;
    }

    function Migrations() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) restricted public {
        last_completed_migration = completed;
    }

    function upgrade(address newAddress) restricted public {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
}