// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract StatelessLogger {
  event Message(address indexed from, bytes32 indexed bloom, bytes data);

  function log(bytes32 bloom, bytes memory transition) public {
    emit Message(msg.sender, bloom, transition);
  }

  function logMultiple(bytes32[] memory blooms, bytes[] memory transitions) public {
      for (uint i = 0; i < blooms.length; i++) {
        emit Message(msg.sender, blooms[i], transitions[i]);
      }
  }

  function callDataOnly(bytes32 bloom, bytes memory) public {
    emit Message(msg.sender, bloom, "");
  }

}