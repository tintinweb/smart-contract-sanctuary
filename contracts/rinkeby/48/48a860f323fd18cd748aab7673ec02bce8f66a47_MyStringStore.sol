/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.5.16;

contract MyStringStore {
  string public myString = "Hello World";

  function set(string memory x) public {
    myString = x;
  }
}