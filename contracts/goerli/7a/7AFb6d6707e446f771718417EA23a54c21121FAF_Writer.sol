/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/// @title Write data to Ethereum
/// @author Eknir
/// @notice You can use this contract to write 512 bits (64 bytes) of data to Ethereum, which is persisted in an array
/// The Ethereum address of the caller, as well as the timestamp is persisted in the Ethereum transaction log
contract Writer {

  event Written(uint256 index, bytes32[2] storedData);

  bytes32[2][] private data;

  /// @notice write writes 512 bits of data to Ethereum, where it is persisted in the storage of this contract
  /// @dev _data is array of bytes 32 with a lenght of 2, totalling 512 bits (64 bytes), which can represent anything (e.g. a sha3-512 hash).
  /// The result can be read by observing the transaction log, taking note of the caller and the timestamp. In the event log, you will find the index at which the data 
  /// is written in the contract storage and you can call `read` with this index to validate the result.
  /// @param _data to write to Ethereum
  function write(bytes32[2] calldata _data) public {
    data.push(_data);
    emit Written(data.length -1, _data);
  }

  /// @notice read what data is written to this contract at a specified index
  /// @param index at what index to read. Index can be read from the event log of this contract (event: Written)
  function read(uint256 index) public view returns(bytes32[2] memory) {
    return data[index];
  } 
}