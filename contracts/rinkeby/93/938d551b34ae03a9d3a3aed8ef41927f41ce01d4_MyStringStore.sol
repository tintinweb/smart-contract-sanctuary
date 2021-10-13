/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity >=0.4.22 <0.9.0;
//pragma solidity ^0.5.0;

contract MyStringStore {
  string public myString = "Hello! This is a default string set at the constructor";

  function set(string memory x) public {
    myString = x;
  }
}