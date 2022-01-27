/**
 *Submitted for verification at BscScan.com on 2022-01-17
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Box {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}