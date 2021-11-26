// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SnakeCurrency.sol";

contract Snakeskin is SnakeCurrency {
  constructor() SnakeCurrency("Snakeskin", "SKIN") {}
}