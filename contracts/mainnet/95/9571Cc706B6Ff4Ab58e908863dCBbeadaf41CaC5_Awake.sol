// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';

contract Awake is ERC20 {
  constructor () public ERC20("Awake","Awake") {
    _mint(msg.sender, 40000000 * 1e18);
  }
}