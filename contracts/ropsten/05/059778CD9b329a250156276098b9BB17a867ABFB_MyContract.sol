// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyContract {
  bytes32 name = "tristan";

  function getName() view external returns (bytes32) {
    return name;
  }
}