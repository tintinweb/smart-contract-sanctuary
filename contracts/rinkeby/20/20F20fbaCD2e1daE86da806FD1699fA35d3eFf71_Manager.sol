// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Manager {
  mapping(address => bool) public admins;
  mapping(address => mapping(uint256 => bool)) public managers;

  constructor() {
    admins[msg.sender] = true;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender], "Must be Admin");
    _;
  }

  event AddedManager(address manager, uint256 _type);
  event RemovedManager(address manager, uint256 _type);
  event AddedAdmin(address admin);
  event RemovedAdmin(address admin);

  function isAdmin(address _addr) external view returns (bool) {
    return admins[_addr];
  }

  function isManager(address _addr, uint256 _type)
    external
    view
    returns (bool)
  {
    return managers[_addr][_type];
  }

  function addManager(address _addr, uint256 _type) external onlyAdmins {
    managers[_addr][_type] = true;

    emit AddedManager(_addr, _type);
  }

  function removeManager(address _addr, uint256 _type) external onlyAdmins {
    managers[_addr][_type] = false;

    emit RemovedManager(_addr, _type);
  }

  function addAdmin(address _addr) external onlyAdmins {
    admins[_addr] = true;

    emit AddedAdmin(_addr);
  }

  function removeAdmin(address _addr) external onlyAdmins {
    admins[_addr] = false;

    emit RemovedAdmin(_addr);
  }
}

