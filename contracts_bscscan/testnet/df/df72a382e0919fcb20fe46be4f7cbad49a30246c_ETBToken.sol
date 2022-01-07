// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./me.sol";

contract ETBToken is ERC20 {
  constructor() ERC20('Eat The Blocks Token', 'ETB') {
    _mint(msg.sender, 1000000 * 10 ** 18);
  }
}