// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

import './Token.sol';
import './SupportsInterface.sol';

/**
 * @title Grexie Token
 * @dev Simple ERC20 Token with standard token functions.
 */
contract GrexieToken is Token, SupportsInterface {
  string private constant NAME = 'Grexie';
  string private constant SYMBOL = 'GREX';
  uint8 private constant DECIMALS = 18;

  uint256 private constant TOTAL_SUPPLY = 10**15 * 10**18;

  /**
   * Grexie Token Constructor
   * @dev Create and issue tokens to msg.sender.
   */
  constructor() public {
    balances[msg.sender] = TOTAL_SUPPLY;
    supportedInterfaces[0x36372b07] = true; // ERC20
    supportedInterfaces[0x06fdde03] = true; // ERC20 name
    supportedInterfaces[0x95d89b41] = true; // ERC20 symbol
    supportedInterfaces[0x313ce567] = true; // ERC20 decimals
  }

  function name() external view returns (string memory _name) {
    return NAME;
  }

  function symbol() external view returns (string memory _symbol) {
    return SYMBOL;
  }

  function decimals() external view returns (uint8 _decimals) {
    return DECIMALS;
  }

  function totalSupply() external view returns (uint256 _totalSupply) {
    return TOTAL_SUPPLY;
  }
}