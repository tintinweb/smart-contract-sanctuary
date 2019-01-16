pragma solidity ^0.4.24;

contract MyStringStore {
  string public myString = "Hello World";

  function set(string x) public {
    myString = x;
  }
}