/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity >=0.4.21 <0.7.0;


contract Migrations {
    address public owner;
    // solhint-disable-next-line var-name-mixedcase
    uint256 public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}