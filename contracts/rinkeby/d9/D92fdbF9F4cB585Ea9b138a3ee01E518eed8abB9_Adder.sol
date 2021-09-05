/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

contract Adder {
    function add(uint256 x, uint256 y) external pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }
}