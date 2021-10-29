/**
 *Submitted for verification at arbiscan.io on 2021-10-29
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

contract Contract {
    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }
}