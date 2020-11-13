// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';

contract Parody is ERC20 {
  constructor () public ERC20("parodytest.finance","PARODYTEST") {
    uint256 amount = 15000;
    _mint(_msgSender(),amount.mul(1e18));
  }
}