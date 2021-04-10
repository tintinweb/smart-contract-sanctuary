// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.5.16;

import "./UniswapV2Factory.sol";

contract JanUniswapV2Factory is UniswapV2Factory {

  constructor() public UniswapV2Factory(msg.sender) {

  }
}