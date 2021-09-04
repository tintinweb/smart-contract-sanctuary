// SPDX-License-Identifier: MIT



pragma solidity ^0.8.4;

import "./ISLAMICOIN.sol";

contract IslamiCompaniesTokenLock {
    
    ISLAMICOIN public ISLAMI;

  address public beneficiary;
  uint256 public releaseTime;   

  constructor(ISLAMICOIN _token, address _beneficiary, uint256 _releaseTime) {
    require(_releaseTime > block.timestamp);
    ISLAMI = _token;
    beneficiary = _beneficiary;
    releaseTime = 1788479999;        //Thursday, September 3, 2026 11:59:59 PM /  Epoch timestamp: 1788479999
  }

  function release() public {
    require(block.timestamp >= releaseTime, "Release time is not yet, Thursday, September 3, 2026 11:59:59 PM");

    uint256 amount = ISLAMI.balanceOf(address(this));
    require(amount > 0);

    ISLAMI.transfer(beneficiary, amount);
  }

}