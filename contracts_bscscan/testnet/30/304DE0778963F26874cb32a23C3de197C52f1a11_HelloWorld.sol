// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld {
  string public words = "Hello World";

  constructor() {
    words = "Hi";
  }

  function setWords(string memory s) public {
    words = s;
  }
}