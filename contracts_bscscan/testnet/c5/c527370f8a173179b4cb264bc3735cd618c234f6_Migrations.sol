// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
    address public owner = msg.sender;
    uint256 public last_completed_migration;
    uint16 public constant _viewCount = 50;
    string hello = "Hello World";
    
    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function sayHello(uint256 x, uint256 y) public pure returns (uint256) {
        return x + y;
    }
}

