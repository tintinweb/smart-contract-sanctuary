// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.6.6;

import "./UniswapV2Router02.sol";

contract JanUniswapV2Router02 is UniswapV2Router02 {

  constructor() public UniswapV2Router02(0x1c1bd61708c13DDC33eBd61BC93d057ADd72FEc5, 0xc778417E063141139Fce010982780140Aa0cD5Ab) {

  }
}