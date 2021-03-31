/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

/**
 * @title TestStatistics
 * @dev Test contract to emit events
 */

contract DepositMachine {
  event Deposit(address depositor, uint256 amount, address referral);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emit test event based on params
   */
  function deposit(address depositor, uint256 amount, address referral) public {
      emit Deposit(depositor, amount, referral);
  }

  /**
   * @dev Emit test event based on params
   */
  function transfer(address from, address to, uint256 value) public {
      emit Transfer(from, to, value);
  }
}