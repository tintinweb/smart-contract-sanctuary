/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract CustomErrorTest {
    error HelloError(address sender);

    function noChance() external view {
        if (msg.sender != address(0)) revert HelloError(msg.sender);
    }

}