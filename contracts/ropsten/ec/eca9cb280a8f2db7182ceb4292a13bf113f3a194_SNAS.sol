/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.7.5;

contract SNAS {
  mapping(bytes32 => address) public names;
  event newName(bytes32 name, address resolveTo, address owner);
  bool locked = false;
  address administrator;
  address currentController;

  modifier onlyController {
    require(msg.sender == currentController, "Not controller");
    _;
  }

  modifier onlyAdministrator {
    require(msg.sender == administrator, "Not administrator");
    _;
  }

  constructor() {
    currentController = msg.sender;
    administrator = msg.sender;
  }

  function createName(bytes32 name, address resolveTo)
    public
    payable
    onlyController
    returns (bool)
  {
    require(names[name] == address(0x0), "This name is already taken.");
    require(locked == false, "Locked");
    locked = true;
    names[name] = resolveTo;
    locked = false;
    emit newName(name, resolveTo, msg.sender);
    return true;
  }

  function changeController(address newController)
    public
    onlyAdministrator
    returns (bool)
  {
    currentController = newController;
    return true;
  }

  function changeAdministrator(address newAdministrator)
    public
    onlyAdministrator
    returns (bool)
  {
    administrator = newAdministrator;
    return true;
  }

  function resolve(bytes32 name) public view returns (address) {
    return names[name];
  }

  function isNameTaken(bytes32 name) public view returns (bool) {
    return names[name] != address(0x0);
  }
}