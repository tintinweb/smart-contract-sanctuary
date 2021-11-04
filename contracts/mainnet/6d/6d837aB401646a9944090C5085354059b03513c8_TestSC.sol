// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TestSC {
  string private mes;

  function set(string memory _mes) public {
    mes = _mes;
  }

  function get() public view returns (string memory) {
    return mes;
  }
}