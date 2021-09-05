/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// import "hardhat/console.sol";

struct Room {
  uint256 id;
  uint256 index;
  uint256 companyId;
}

struct Company {
  uint256 id;
  uint256 index;
  string name;
}

struct Employee {
  address addr;
  string name;
  uint256 index;
  uint256 companyId;
}

struct Slot {
  bool booked;
  address bookedBy;
}

contract BlockCal {
  address public owner = msg.sender;
  uint256 public creationTime = block.timestamp;

  uint256 private nextCompanyId = 1;
  uint256 private nextRoomId = 1;

  mapping(uint256 => Company) public companies;
  uint256[] public companiesIds;

  mapping(address => Employee) public employees;
  address[] public employeesAddresses;

  mapping(uint256 => Room) public rooms;
  uint256[] public roomsIds;

  // slots 1 to 25
  // usage: `bookings[roomId][slotId]`
  mapping(uint256 => mapping(uint256 => Slot)) public bookings;

  function getCompanies() public view returns (uint256[] memory) {
    require(msg.sender == owner, "Only owner can see list of companies");
    return companiesIds;
  }

  function getRooms() public view returns (uint256[] memory) {
    require(
      employees[msg.sender].addr == msg.sender,
      "Only employees can see list of rooms"
    );
    return roomsIds;
  }

  function isRoomSlotBooked(uint256 roomId, uint256 slot)
    public
    view
    returns (bool isBooked)
  {
    return
      bookings[roomId][slot].bookedBy != address(0)
        ? bookings[roomId][slot].booked
        : false;
  }

  function addCompany(string memory companyName) public returns (bool success) {
    require(msg.sender == owner, "Only owner can create new company");

    for (uint256 index = 0; index < companiesIds.length; index++) {
      require(
        keccak256(bytes(companyName)) !=
          keccak256(bytes(companies[companiesIds[index]].name)),
        "Company with this name already exist"
      );
    }

    companiesIds.push(nextCompanyId);

    companies[nextCompanyId].id = nextCompanyId;
    companies[nextCompanyId].name = companyName;
    companies[nextCompanyId].index = companiesIds.length - 1;

    nextCompanyId = nextCompanyId + 1;

    return true;
  }

  function removeCompany(uint256 companyId) public returns (bool success) {
    require(msg.sender == owner, "Only owner can delete company");
    require(
      companies[companyId].id == companyId && companyId != 0,
      "Company does not exist"
    );

    for (uint256 index = 0; index < employeesAddresses.length; index++) {
      address employeeAddress = employeesAddresses[index];
      if (employees[employeeAddress].companyId == companyId) {
        this.removeEmployee(employeeAddress);
      }
    }

    for (uint256 index = 0; index < roomsIds.length; index++) {
      uint256 roomId = roomsIds[index];
      if (rooms[roomId].companyId == companyId) {
        this.removeRoom(roomId);
      }
    }

    uint256 rowToDelete = companies[companyId].index;
    uint256 keyToMove = companiesIds[companiesIds.length - 1];

    companiesIds[rowToDelete] = keyToMove;
    companies[keyToMove].index = rowToDelete;

    companiesIds.pop();
    delete companies[companyId];

    return true;
  }

  function addEmployee(
    address employeeAddress,
    uint256 companyId,
    string memory employeeName
  ) public returns (bool success) {
    require(msg.sender == owner, "Only owner can add employee");
    require(
      companies[companyId].id == companyId && companyId != 0,
      "Company does not exist"
    );
    require(
      employees[employeeAddress].addr != employeeAddress,
      "Employee already exist"
    );

    employeesAddresses.push(employeeAddress);

    employees[employeeAddress].addr = employeeAddress;
    employees[employeeAddress].companyId = companyId;
    employees[employeeAddress].name = employeeName;
    employees[employeeAddress].index = employeesAddresses.length - 1;

    return true;
  }

  function removeEmployee(address employeeAddress)
    public
    returns (bool success)
  {
    bool isOwner = msg.sender == owner || msg.sender == address(this);
    bool employeeExist = employees[employeeAddress].addr == employeeAddress;
    require(isOwner, "Only owner can remove employee");
    require(employeeExist, "Employee does not exist");

    uint256 rowToDelete = employees[employeeAddress].index;
    address keyToMove = employeesAddresses[employeesAddresses.length - 1];

    employeesAddresses[rowToDelete] = keyToMove;
    employees[keyToMove].index = rowToDelete;

    employeesAddresses.pop();
    delete employees[employeeAddress];

    return true;
  }

  function employeeInfos(address addr) public view returns (uint256 companyId) {
    if (employees[addr].addr == addr) {
      return employees[addr].companyId;
    }

    require(false, "Employee does not exist");
  }

  function addRoom(uint256 companyId) public returns (bool success) {
    bool isOwner = msg.sender == owner;
    bool companyExist = companies[companyId].id == companyId && companyId != 0;
    require(isOwner, "Only owner can add room");
    require(companyExist, "Company does not exist");

    roomsIds.push(nextRoomId);
    rooms[nextRoomId].id = nextRoomId;
    rooms[nextRoomId].companyId = companyId;
    rooms[nextRoomId].index = roomsIds.length - 1;

    nextRoomId = nextRoomId + 1;

    return true;
  }

  function removeRoom(uint256 roomId) public returns (bool success) {
    bool isOwner = msg.sender == owner || msg.sender == address(this);
    require(isOwner, "Only owner can remove room");
    require(rooms[roomId].id == roomId, "Room does not exist");

    // remove booked slots
    for (uint256 slot = 1; slot <= 25; slot++) {
      if (bookings[roomId][slot].bookedBy != address(0)) {
        delete bookings[roomId][slot];
      }
    }

    uint256 rowToDelete = rooms[roomId].index;
    uint256 keyToMove = roomsIds[roomsIds.length - 1];

    roomsIds[rowToDelete] = keyToMove;
    rooms[keyToMove].index = rowToDelete;

    roomsIds.pop();
    delete rooms[roomId];

    return true;
  }

  function bookSlot(uint256 roomId, uint256 slot)
    public
    returns (bool success)
  {
    require(slot > 0 && slot < 26, "Slot must be between 1 and 25");
    require(bookings[roomId][slot].booked != true, "Slot already booked");
    require(
      employees[msg.sender].addr == msg.sender,
      "Employee does not exist"
    );
    bookings[roomId][slot].booked = true;
    bookings[roomId][slot].bookedBy = msg.sender;
    return true;
  }

  function unbookSlot(uint256 roomId, uint256 slot)
    public
    returns (bool success)
  {
    require(bookings[roomId][slot].booked, "Slot is not booked");
    require(
      bookings[roomId][slot].bookedBy == msg.sender,
      "Only owner can unbook slot"
    );
    delete bookings[roomId][slot];
    return true;
  }
}