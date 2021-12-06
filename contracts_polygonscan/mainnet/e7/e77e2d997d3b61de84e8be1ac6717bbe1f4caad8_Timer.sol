/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Timer {
    function getTime() external view returns(uint256) {
        return block.timestamp;
    }
}