/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Upkeep {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;
  function setShouldPerformUpkeep(bool _should) public {
    shouldPerformUpkeep = _should;
  }
  function setBytesToSend(bytes memory _bytes) public {
    bytesToSend = _bytes;
  }
  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    return (shouldPerformUpkeep, bytesToSend);
  }
  function performUpkeep(bytes calldata data) external {
    shouldPerformUpkeep = false;
    receivedBytes = data;
  }
  function getLastBytesSent() external returns (bytes memory) {
    return bytesToSend;
  }
}