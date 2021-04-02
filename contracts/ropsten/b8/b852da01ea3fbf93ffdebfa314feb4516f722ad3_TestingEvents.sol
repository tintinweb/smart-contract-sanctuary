/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

/**
 * @title TestStatistics
 * @dev Test contract to emit events
 */

contract TestingEvents {
  event FirstEvent(uint256 order);
  event SecondEvent(uint256 order);

    /**
     * @dev Emit test event based on params
     */
    function triggerEvents() public {
        emit FirstEvent(1);
        emit SecondEvent(2);
    }
}