/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number=type(uint256).max;

    function div(uint256 n) public view returns (uint256) {
        return number/n;
    }
}