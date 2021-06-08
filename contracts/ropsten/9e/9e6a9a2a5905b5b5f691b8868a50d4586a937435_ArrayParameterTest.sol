/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ArrayParameterTest {
    function addNumbers(uint256[] calldata numbers) external pure returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        return sum;
    }
}