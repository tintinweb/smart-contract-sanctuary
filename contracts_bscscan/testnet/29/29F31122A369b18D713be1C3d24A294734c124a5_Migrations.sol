// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Made in Pakistan by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
// Project done in collaboration with TrippyBlue and ShieldNet Team.
//
//
// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.7;

contract Migrations {
    address public owner = msg.sender;
    uint256 public last_completed_migration;

    function setCompleted(uint256 completed) public {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        last_completed_migration = completed;
    }
}

