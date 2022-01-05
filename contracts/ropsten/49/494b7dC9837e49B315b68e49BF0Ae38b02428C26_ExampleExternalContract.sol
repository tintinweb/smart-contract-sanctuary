pragma solidity ^0.8.3;

contract ExampleExternalContract {

  bool public completed;

  constructor() {}

  function complete() public payable {
    completed = true;
  }

}