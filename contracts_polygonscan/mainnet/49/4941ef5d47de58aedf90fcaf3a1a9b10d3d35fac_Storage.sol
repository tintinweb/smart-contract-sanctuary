/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    int256 public number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function adjust(int256 num) public {
        number += num;
    }

    receive() external payable {
        number++;
    }
}