// SPDX-License-Identifier: MIT


// ISLAMICOIN First Investors locked tokens Official smart contract / Date: 5th of September 2021

// Locked for 3 Years

// Tokens are locked until: Tuesday, September 5, 2024 11:59:59 PM

pragma solidity ^0.8.4;

import "./ISLAMICOIN.sol";

contract IslamiFirstInvestorsTokenLock {
    
    ISLAMICOIN public ISLAMI;

  address public beneficiary;
  uint256 public releaseTime;
  
  

  constructor(ISLAMICOIN _token, address _beneficiary, uint256 _releasetime) {
    require(_releasetime > block.timestamp);
    ISLAMI = _token;
    beneficiary = _beneficiary;
    releaseTime = 1725580799;        //Tuesday, September 5, 2024 11:59:59 PM /  Epoch timestamp: 1725580799
  }
  
  

  function release() public {
    require(block.timestamp >= releaseTime, "Release time is not yet, Tuesday, September 5, 2024 11:59:59 PM");

    uint256 amount = ISLAMI.balanceOf(address(this));
    require(amount > 0);

    ISLAMI.transfer(beneficiary, amount);
  }

}