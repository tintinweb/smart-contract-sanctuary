/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Store {
  event ItemSet(string key, string value);

  string public version;
  mapping (string => string) public items;

  constructor(string memory _version) {
    version = _version;
  }

  function setItem(string memory key, string memory value) external {
    items[key] = value;
    emit ItemSet(key, value);
  }
}