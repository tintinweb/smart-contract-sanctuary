// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';

contract HOC is ERC20 {
  constructor () public ERC20("houseofcards.finance","HOC") {
    _mint(msg.sender, 200 * 1e18);
  }
}