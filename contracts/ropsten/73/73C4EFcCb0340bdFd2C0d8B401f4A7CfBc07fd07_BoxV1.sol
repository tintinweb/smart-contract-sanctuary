pragma solidity ^0.8.2;

contract BoxV1 {
  uint public val;

  // constructor(uint _val) {
  //   val= _val;
  // }

  function initialize(uint _val) external {
    val = _val;
  }
}