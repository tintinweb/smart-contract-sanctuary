/**
 *Submitted for verification at FtmScan.com on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract GasLimit {
    function getGasLimit() public view returns (uint256) {
        return block.gaslimit;
    }
}