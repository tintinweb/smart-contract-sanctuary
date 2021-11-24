/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Presale Unlock Condition For Unicrypt Token Vesting
// Allows unlocking tokens when a presale finalizes

pragma solidity ^0.8.0;

interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

interface IPresaleContract {
    function presaleStatus () external view returns (uint256);
}

contract PresaleFinalizeCondition is IUnlockCondition {
  IPresaleContract public PRESALE_CONTRACT;
  
  constructor (IPresaleContract _presaleContract) {
    PRESALE_CONTRACT = _presaleContract;
  }
  
  // Unlock tokens when presale is finalized (Status code 4)
  function unlockTokens() override external view returns (bool) {
      return PRESALE_CONTRACT.presaleStatus() == 4;
  }
}