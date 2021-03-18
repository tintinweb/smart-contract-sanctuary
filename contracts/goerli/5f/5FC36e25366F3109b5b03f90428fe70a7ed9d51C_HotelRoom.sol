//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract HotelRoom {
  address payable public owner;
  HotelStatus currentStatus;

  enum HotelStatus {
    Vacant,
    Occupied
  }

  event Occupy(address _occupy, uint _amount);

  constructor() {
    owner = msg.sender;
    currentStatus = HotelStatus.Vacant;
  }

  modifier onlyWhileVacant {
    require(currentStatus == HotelStatus.Vacant, "Currently Occupied.");
    _;
  }

  modifier costs(uint _amount) {
    // Check price
    require(msg.value >= _amount, "Not enough ether provided.");
    _;
  }

  receive() external payable onlyWhileVacant costs(2 ether) {
    currentStatus = HotelStatus.Occupied;
    owner.transfer(msg.value);
    emit Occupy(msg.sender, msg.value);
  }
}