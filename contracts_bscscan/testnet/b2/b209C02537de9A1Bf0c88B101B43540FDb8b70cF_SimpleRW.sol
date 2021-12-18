/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title SimpleRW
 * @dev Implement simple read and write operations - used for testing
 */
contract SimpleRW {
  uint256 public count;

  constructor(uint initCount) {
    count = initCount;
  }

  function increment(uint256 amount) public {
    require(amount < 10, "cannot add more than 10");
    count += amount;
  }

  function whoami() public view returns (address){
      return msg.sender;
  }
}