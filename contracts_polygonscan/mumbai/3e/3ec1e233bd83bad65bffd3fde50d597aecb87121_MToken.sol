// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC20} from './ERC20.sol';

contract MToken is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  function mint(uint256 value) public returns (bool) {
    _mint(_msgSender(), value);
    return true;
  }
}