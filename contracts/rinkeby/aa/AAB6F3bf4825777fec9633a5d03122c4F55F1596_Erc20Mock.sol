// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "ERC20.sol";

contract Erc20Mock is ERC20 {
  constructor() ERC20("renFIL", "renFIL") {
    _setupDecimals(18);
  }

  function mint(address account_, uint256 amount_) external {
    _mint(account_, amount_);
  }
}