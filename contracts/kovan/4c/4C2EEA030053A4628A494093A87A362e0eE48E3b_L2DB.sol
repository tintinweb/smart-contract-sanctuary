/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

// Global Enums and Structs



struct Transaction {
  address to;
  address from;
  uint96 value;
  uint32 gasLimit;
  bytes data;
  bytes signature;
}

// File: L2DB.sol

contract L2DB {
  event SetGasPrice(uint gasPrice);
  event Tx(Transaction tx);

  uint public gasPrice;

  constructor(uint _gasPrice) {
    gasPrice = _gasPrice;
    emit SetGasPrice(_gasPrice);
  }

  /// @dev Submits a new batch of transactions to the sidechain.
  function submit(Transaction[] calldata txs) external {
    uint count = txs.length;
    for (uint idx = 0; idx < count; idx++) {
      emit Tx(txs[idx]);
    }
  }

  /// @dev Sets the global sidechain gas price.
  function setGasPrice(uint _gasPrice) external {
    gasPrice = _gasPrice;
    emit SetGasPrice(_gasPrice);
  }
}