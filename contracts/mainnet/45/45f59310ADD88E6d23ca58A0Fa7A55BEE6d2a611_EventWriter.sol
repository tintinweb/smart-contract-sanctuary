/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/// @title Write data to Ethereum event log
/// @author Eknir
/// @notice You can use this contract to write 512 bits (64 bytes) of data to Ethereum, which is persisted in the Ethereum eventLog
/// The Ethereum address of the caller, as well as the timestamp is persisted in the Ethereum transaction log
contract EventWriter {

  event Written(bytes32[2] storedData);

  /// @notice write writes 512 bits of data to Ethereum, where it is persisted in the storage of this contract
  /// @dev data is array of bytes 32 with a lenght of 2, totalling 512 bits (64 bytes), which can represent anything (e.g. a sha3-512 hash).
  /// The result can be read by observing the event log, taking note of the caller and the timestamp.
  /// @param data to write to Ethereum event log
  function write(bytes32[2] calldata data) public {
    emit Written(data);
  }
}