/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface migrator {
    function migrateRewardsFor(address address_) external;
}

contract migratorHelper {
    constructor(){}
    
    migrator public Plasma = migrator(0xC3aF7Bb38999e8A1db7849e30706Efbf8FFd57Fa);

    function migrateMany(address[] calldata addresses_) external {
        for (uint256 i = 0; i < addresses_.length; i++) {
            Plasma.migrateRewardsFor(addresses_[i]);
        }
    }
}