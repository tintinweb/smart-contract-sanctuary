// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Test {

  uint256 a;
  constructor(uint256 _a) public {
      a = _a;
  }

  function add(uint256 _b) public {
      a += _b;
  }
}

