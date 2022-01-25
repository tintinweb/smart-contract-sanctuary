// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

contract SCoinToken is BEP20Detailed, BEP20 {
  constructor() BEP20Detailed("Snake Coin", "SCOIN", 18) {
    uint256 totalTokens = 1000000000 * 10 ** uint256(decimals());
    _mint(msg.sender, totalTokens);
  }
}