pragma solidity ^0.4.24;

contract Foo {
  uint256 private a;

  constructor () public {
    a = 8;
  }

  function foo() public {
    uint256 [] temp;
    temp.push(1);
    temp.push(2);
    temp.push(3);
  }

  function getA() public view returns (uint256) {
    return a;
  }
}