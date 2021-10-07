/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0 <0.9.0;

contract BigEater {
    fallback() external {
        while (gasleft() >= 1) {}
    }
}