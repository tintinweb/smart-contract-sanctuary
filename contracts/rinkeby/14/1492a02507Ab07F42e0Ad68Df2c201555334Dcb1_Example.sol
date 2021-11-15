pragma solidity ^0.5.16;

contract Example {
  string public message;

  function changeMsg(string calldata _message) external {
    message = _message;
  }
}

