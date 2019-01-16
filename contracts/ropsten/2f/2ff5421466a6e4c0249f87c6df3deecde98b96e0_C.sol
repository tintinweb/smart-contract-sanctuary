pragma solidity ^0.4.24;

library C {
  function add(uint256 a, uint256 b) pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}