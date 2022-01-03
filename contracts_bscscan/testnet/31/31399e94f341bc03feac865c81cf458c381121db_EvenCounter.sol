/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title EvenCounter
 * @dev Implement events - used for testing
 */
contract EvenCounter {
  uint256 public count;

  event Increment(address indexed _from, uint256 oldCount, uint256 newCount);
  constructor() {
    count = 0;
  }

  function increment() public {
    count += 1;
    emit Increment(msg.sender, count-1, count);
  }
}