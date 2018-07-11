pragma solidity ^0.4.6;

contract Child {
  event ParentNumber(uint256 number);

  constructor(uint256 number) public {
      emit ParentNumber(number);
  }
}