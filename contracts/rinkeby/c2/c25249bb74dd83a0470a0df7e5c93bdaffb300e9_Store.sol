/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.3 and less than 0.8.0
pragma solidity ^0.8.3;

contract Store {
  event ItemSet(bytes32 key, bytes32 value);
  event ItemChange(bytes32 key, bytes32 value);
  string public version;
  mapping (bytes32 => bytes32) public items;
  mapping (bytes32 => address) public owned;

  constructor(string memory _version) {
    version = _version;
  }

  function setItem(bytes32 key, bytes32 value) external {
    require(items[key] == 0);
    items[key] = value;
    owned[key] = msg.sender;
    emit ItemSet(key, value);
  }

  function changeItem(bytes32 key, bytes32 value) external {
    require(owned[key] == msg.sender);
    require(items[key] != 0);
    items[key] = value;
    emit ItemChange(key, value);
  }
}