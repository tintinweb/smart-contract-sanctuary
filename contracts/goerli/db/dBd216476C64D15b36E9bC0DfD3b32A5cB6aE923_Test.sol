// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * This is a test contract with the sole purpose of testing hardhat
 * deploy features.
 */
contract Test {
  string private _message;

  /**
   * Signals that `_message` of the contract has been updated.
   * Intended to fire every time `setMessage` is called
   */
  event NewMessage(address creator, string oldMessage, string newMessage);

  constructor(string memory __message) {
    _message = __message;
  }

  /**
   * Sets the `_message` private variable
   * Emits the NewMessage event
   */
  function setMessage(string memory __message) external {
    string memory oldMessage = _message;
    _message = __message;
    emit NewMessage(tx.origin, oldMessage, __message);
  }

  /**
   * Returns the current value of the `_message` variable
   */
  function getMessage() external view returns (string memory) {
    return _message;
  }
}