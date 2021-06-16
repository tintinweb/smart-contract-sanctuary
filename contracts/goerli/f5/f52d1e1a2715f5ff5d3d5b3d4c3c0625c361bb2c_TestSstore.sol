/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

contract TestSstore {
    uint256 private val;
    function setTo0() external payable {
        val = 0;
    }
    function setTo1() external payable {
        val = 1;
    }
    function setTo2() external payable {
        val = 2;
    }

}