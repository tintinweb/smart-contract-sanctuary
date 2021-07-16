pragma solidity ^0.8.3;

import './LERC20.sol';

// SPDX-License-Identifier: MIT

contract YellowBeer is LERC20 {
  constructor() LERC20('Yellow Beer Token', 'YellowBeer') {
    _mint(msg.sender, 10000000000000000000000000000000); //suply
  }
}