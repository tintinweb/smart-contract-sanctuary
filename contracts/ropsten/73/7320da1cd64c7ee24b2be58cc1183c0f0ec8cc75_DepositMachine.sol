/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

/**
 * @title TestStatistics
 * @dev Test contract to emit events
 */

contract DepositMachine {
  event Deposit(address depositor, uint256 amount, address referral);

  /**
   * @dev Emit test event based on params
   */
  function deposit(address depositor, uint256 amount, address referral) public {
      emit Deposit(depositor, amount, referral);
  }
}