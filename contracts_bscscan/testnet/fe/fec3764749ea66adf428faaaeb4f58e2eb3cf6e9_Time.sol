/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Time {
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}