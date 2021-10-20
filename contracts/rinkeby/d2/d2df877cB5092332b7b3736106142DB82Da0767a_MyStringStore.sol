/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity ^0.5.0;

contract MyStringStore {
  string public myString = "This is a test";

  function set(string memory x) public {
    myString = x;
  }
}