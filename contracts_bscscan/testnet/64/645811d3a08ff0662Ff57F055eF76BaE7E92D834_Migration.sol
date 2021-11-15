// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Migration {
  address public owner = msg.sender;
  address public instance;

  modifier restricted() {
    require(msg.sender == owner, "Owner only");
    _;
  }

  function setCompleted(address _instance) public restricted {
    instance = _instance;
  }
}

