/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.8.0;

contract SimpleStorage {
  uint myVariable;

  function set(uint x) public {
	myVariable = x;
 }

  function get() view public returns (uint) {
    return myVariable;
  }
}