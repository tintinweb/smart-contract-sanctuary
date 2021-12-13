/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

pragma solidity >=0.5.0 <0.6.0;

contract company {
  int value;

  function add(int  a, int b) public {
    value = a + b;
  }

  function get() public view returns (int chickenId) {
    return value;
  }
}