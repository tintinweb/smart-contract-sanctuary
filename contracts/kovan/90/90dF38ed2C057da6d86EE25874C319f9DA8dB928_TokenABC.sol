// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract TokenABC is ERC20 {
    constructor() public ERC20("TokenABC", "ABC") {
      _mint(0xB75DFCccbfBD420A1D5c3a6C28459b817456Bf97, 1000000000000000000000);
      _mint(0x51481C3299473d10570b2280344FD327B4f99da1, 1000000000000000000000);
    }
}