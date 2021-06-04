/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

contract BasicStorage {
  event Expired(address,bytes32,bytes32);

  mapping (address => mapping (bytes32 => bytes32)) public data;
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function set(bytes32 _key, bytes32 _data) external returns (bytes32 prev) {
    prev = data[msg.sender][_key];
    data[msg.sender][_key] = _data;
    emit Expired(msg.sender, _key, prev);
  }

  function shine() external {
    require(msg.sender == owner);
    selfdestruct(payable(owner));
  }
  function lock() external {
    require(msg.sender == owner);
    owner = address(0);
  }
}