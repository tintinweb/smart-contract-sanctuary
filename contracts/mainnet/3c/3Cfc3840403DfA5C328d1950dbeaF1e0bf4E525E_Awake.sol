// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';

contract Awake is ERC20 {
  constructor () public ERC20("AWAKETEST","AWAKETEST") {
    uint256 amount = 20000000;
    _mint(_msgSender(),amount.mul(1e18));
  }
}