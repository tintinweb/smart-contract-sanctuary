// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
  function goTo(uint _floor) external;
}

contract Building {
  address owner;
  uint top;

  constructor ()
    {
      owner = msg.sender;
    }

  function callElevator(address _elevator, uint _floor) public {
    require(owner == msg.sender, "only owner");
    Elevator(_elevator).goTo(_floor);
  }

  function isLastFloor(uint _currentFloor) external returns (bool) {
    bool isTop;

    if (_currentFloor != top) {
      top = _currentFloor;
      isTop = false;
    } else
    if (_currentFloor == top) {
      isTop = true;
    }
    return isTop;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}