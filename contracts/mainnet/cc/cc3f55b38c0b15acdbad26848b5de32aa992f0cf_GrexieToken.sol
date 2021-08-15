// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

import './Token.sol';

/**
 * @title Grexie Token
 * @dev Simple ERC20 Token with standard token functions.
 */
contract GrexieToken is Token {
  string public constant NAME = 'Grexie';
  string public constant SYMBOL = 'GREX';
  uint256 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 10**15 * 10**18;

  /**
   * Grexie Token Constructor
   * @dev Create and issue tokens to msg.sender.
   */
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}