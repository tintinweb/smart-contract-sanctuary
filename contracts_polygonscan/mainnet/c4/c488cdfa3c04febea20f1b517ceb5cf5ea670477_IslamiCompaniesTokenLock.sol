// SPDX-License-Identifier: MIT


// ISLAMICOIN Companies locked tokens Official smart contract / Date: 5th of September 2021

// Locked for 5 Years

// Tokens are locked until: Thursday, September 5, 2026 11:59:59 PM

pragma solidity ^0.8.4;

import "./ISLAMICOIN.sol";

contract IslamiCompaniesTokenLock {
    
    ISLAMICOIN public ISLAMI;

  address public beneficiary;
  uint256 public releaseTime;   

  constructor(ISLAMICOIN _token, address _beneficiary, uint256 _releasetime) {
    require(_releasetime > block.timestamp);
    ISLAMI = _token;
    beneficiary = _beneficiary;
    releaseTime = 1788652799;        //Thursday, September 5, 2026 11:59:59 PM /  Epoch timestamp: 1788652799
  }

  function release() public {
    require(block.timestamp >= releaseTime, "Release time is not yet, Thursday, September 5, 2026 11:59:59 PM");

    uint256 amount = ISLAMI.balanceOf(address(this));
    require(amount > 0);

    ISLAMI.transfer(beneficiary, amount);
  }

}