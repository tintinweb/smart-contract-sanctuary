// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'ERC20Capped.sol';
import 'Ownable.sol';

contract Ana is ERC20Capped, Ownable {
  constructor() ERC20Capped(21000000 * 10 ** decimals()) ERC20("Ana coin", "ANA") {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}