/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
    function Testtime() external view returns(uint256) {

        uint256 nowtime = block.timestamp;

        return nowtime;
    }
}