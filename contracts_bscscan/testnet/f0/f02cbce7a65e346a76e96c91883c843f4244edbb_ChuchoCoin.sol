// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract ChuchoCoin is ERC20 {
  constructor() ERC20("ChuchoCoin", "CCOIN") {
    _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
  }
}