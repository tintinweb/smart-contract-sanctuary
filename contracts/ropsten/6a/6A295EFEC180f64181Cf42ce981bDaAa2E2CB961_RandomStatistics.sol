/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

/**
 * @title TestStatistics
 * @dev Test contract to emit events
 */

contract RandomStatistics {
  event ProfitDeclared(bool profit, uint256 amount, uint256 timestamp, uint256 totalAmountInPool, uint256 totalSharesInPool, uint256 performanceFeeTotal, uint256 baseFeeTotal);

  /**
   * @dev Emit test event based on params
   */
  function declareProfit(bool profit, uint256 amount, uint256 timestamp, uint256 totalAmountInPool, uint256 totalSharesInPool, uint256 performanceFeeTotal, uint256 baseFeeTotal) public {
      emit ProfitDeclared(profit, amount, timestamp, totalAmountInPool, totalSharesInPool, performanceFeeTotal, baseFeeTotal);
  }
}