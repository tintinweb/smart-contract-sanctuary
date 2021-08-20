//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.0;

import './BridgeBase.sol';

contract BridgeBSC is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}