// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Entropy GameTokenReactor Whitelist Batch Search Contract
contract ReactorBatchCheck {

  address public gameTokenReactor;

  constructor(address gameTokenReactr_) {
    gameTokenReactor = gameTokenReactr_;
  }

  function batchCheck(address[] memory addrs) external view returns (bool result) {
    result = true;
    for(uint i = 0; i < addrs.length; i++) {
      if (IGTR(gameTokenReactor).isUserWhitelisted(addrs[i]) == false) {
        result = false;
      }
    }
  }
}

interface IGTR {
  function isUserWhitelisted(address user) external view returns (bool);
}