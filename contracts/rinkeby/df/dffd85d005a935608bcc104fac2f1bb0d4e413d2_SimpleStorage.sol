/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity >=0.8.0;

contract SimpleStorage {
  uint storedData;

  constructor() payable {
    storedData = 123;
  }

  function set(uint x) public payable {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}