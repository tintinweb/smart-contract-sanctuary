/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// This contract has been optimised for cheap gas deployment, and only allows the creator to set the state, you can create your
// own unlockTokens() condition returning a bool, or use it as is as a manual unlocking trigger.

pragma solidity ^0.8.0;

interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

contract ConditionLight is IUnlockCondition {
  bool UNLOCK_TOKENS = true;
  address owner;
  
  constructor () {
    owner = msg.sender;
  }
  
  /**
   * @notice set the conditon
   */
  function setCondition(bool _state) public {
    require(msg.sender == owner);
    UNLOCK_TOKENS = _state;
  }
  
  // Add your conditional unlock logic here
  // for example:
  // - when price reaches x
  // - when presale state is complete
  // - if governance reaches consensus to unlock tokens prematurely
  // - you can alternatively use this contract as is as a manual trigger
  function unlockTokens() override external view returns (bool) {
      return UNLOCK_TOKENS;
  }
}