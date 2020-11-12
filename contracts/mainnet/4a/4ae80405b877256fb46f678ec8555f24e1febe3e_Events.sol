// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface Events {
  /**
   * Emitted when the washout mechanism has been called.
   * Signifies that all tokens have been burned and all further token transfers are blocked, unless the recipient
   * is the contract owner.
   */
  event Washout();

  /**
   * Emitted when a new address is appended to the list of addresses in the contract.
   */
  event NewAddressAppended(address newAddress);
}
