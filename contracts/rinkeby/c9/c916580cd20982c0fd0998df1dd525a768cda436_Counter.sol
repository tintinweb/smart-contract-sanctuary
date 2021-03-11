/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.7.0;

contract Counter {
  uint256 public value;

  function increaseOne() public {
    value = value + 1;
  }
}