// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.6.6;

import "./UniswapV2Router02.sol";

contract JanUniswapV2Router02 is UniswapV2Router02 {

  constructor() public UniswapV2Router02(0xFc3584267A202D09e80B8b88Fdbb47298776B2f7, 0xc778417E063141139Fce010982780140Aa0cD5Ab) {

  }
}