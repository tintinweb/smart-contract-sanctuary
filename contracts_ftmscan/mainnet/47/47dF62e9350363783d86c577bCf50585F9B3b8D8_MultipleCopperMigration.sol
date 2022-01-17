/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.10;

interface ICopperMigration {
    function withdrawal(uint8 roleIndex, uint tokenID) external;
}

contract MultipleCopperMigration {
    ICopperMigration constant cm = ICopperMigration(0x1cEfFB110456106fdcd4f5Db0137c350fEbF8A81);

    function multipleWithdrawal(uint8 roleIndex, uint256[] calldata tokenIDs) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            cm.withdrawal(roleIndex, tokenIDs[i]);
        }
    }
}