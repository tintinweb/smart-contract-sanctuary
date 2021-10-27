// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Foo {
  uint public nonce3 = 57836;

  constructor (uint x) {
    nonce3 += x;
  }
}