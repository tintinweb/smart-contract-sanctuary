/**
 *Submitted for verification at FtmScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BlocktimeTracker {
    uint8 public constant PRECISION = 6;
    uint256 public startBlockNumber;
    uint256 public startBlockTimestamp;

    constructor() {
        startBlockNumber = currentBlock();
        startBlockTimestamp = currentTimestamp();
    }

    function divide(uint256 a, uint256 b, uint8 precision) internal pure returns (uint256) {
        return a * (10**precision) / b;
    }

    function average() public view returns (uint256) {
        return divide((currentBlock() - startBlockNumber), (currentTimestamp() - startBlockTimestamp), PRECISION);
    }

    function currentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }
}