/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// This is an example of a condition which will pass at first, but can be changed to make unlockTokens(bool) fail.
// Initially this condition can be used to create a lock as it returns 1 which can be a bool, once the lock is made, 
// this can be set to for example 122 (no longer a boolish repsponse, and the locks withdraw function will fail as
// premature unlock conditions need to be checked first in order to get a withdrawable amount from a lock.
// for this reason premature unlocking conditions can be revoked.

pragma solidity ^0.8.0;

interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

contract FailingCondition {
  uint256 UNLOCK_TOKENS = 1;
  address owner;
  
  constructor () {
    owner = msg.sender;
  }
  
  /**
   * @notice set the conditon to for example 122, now unlockTokens will fail in TokenVesting
   */
  function setCondition(uint256 _state) public {
    require(msg.sender == owner);
    UNLOCK_TOKENS = _state;
  }
  
  function unlockTokens() external view returns (uint256) {
      return UNLOCK_TOKENS;
  }
}