// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Payable.sol";

contract TrillionToken is ERC20 {
  constructor() ERC20('Trillion', 'T') {
    _mint(msg.sender, 300000000 * 10 ** 18);
  }
}