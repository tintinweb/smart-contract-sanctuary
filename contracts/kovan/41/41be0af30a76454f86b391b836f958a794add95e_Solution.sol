/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Solution {
    function difference(uint256 original) public pure returns (uint8 ret) {
        uint256 current_number = original;
        while (current_number > 10) {
            for (uint256 i = 0; (original / 10) * i > 0; i++) {
                current_number += ((original / 10) * i);
            }
        }
        ret = uint8(current_number);
    }
}