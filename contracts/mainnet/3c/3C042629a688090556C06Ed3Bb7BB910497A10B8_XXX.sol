// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';

contract XXX is ERC20 {
  constructor () public ERC20("XXX","XXX") {
    _mint(msg.sender, 1000000 * 1e18);
  }
}