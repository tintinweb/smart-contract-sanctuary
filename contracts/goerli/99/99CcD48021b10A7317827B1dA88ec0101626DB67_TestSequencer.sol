// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract TestSequencer {
  bytes32 public master;

  event MasterSet(bytes32 indexed network);

  function setMaster(bytes32 network) external {
    master = network;
    emit MasterSet(network);
  }

  function isMaster(bytes32 network) external view returns (bool) {
    return master == network;
  }
}