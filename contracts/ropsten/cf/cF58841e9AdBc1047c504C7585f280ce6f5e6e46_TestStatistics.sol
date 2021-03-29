/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

/**
 * @title TestStatistics
 * @dev Test contract to emit events
 */

contract TestStatistics {
  event ProfitDeclared(bool profit, uint256 amount, uint256 timestamp, uint256 totalAmountInPool, uint256 totalSharesInPool);

    /**
     * @dev Emit test event based on params
     */
    function declareProfit(bool profit, uint256 amount, uint256 timestamp, uint256 totalAmountInPool, uint256 totalSharesInPool) public {
        emit ProfitDeclared(profit, amount, timestamp ,totalAmountInPool, totalSharesInPool);
    }
}