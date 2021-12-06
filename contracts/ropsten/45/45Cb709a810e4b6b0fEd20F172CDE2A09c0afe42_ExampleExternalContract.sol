pragma solidity ^0.8.3;

contract ExampleExternalContract {

  bool public completed;

  constructor() public {}

  function complete() public payable {
    completed = true;
  }

}