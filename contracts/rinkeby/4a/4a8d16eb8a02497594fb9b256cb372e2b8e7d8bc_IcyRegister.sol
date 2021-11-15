// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

contract IcyRegister {
  address private owner;

  uint256 private registerPrice;
  mapping(address => bool) private userToRegistered;

  constructor() {
    owner = msg.sender;
    registerPrice = 0.05 ether;
  }

  //////////
  // Getters

  function getRegisterPrice() external view returns (uint256) {
    return (registerPrice);
  }

  function getOwner() external view returns (address) {
    return (owner);
  }

  function isAddressRegistered(address _account) external view returns (bool) {
    return (userToRegistered[_account]);
  }

  //////////
  // Setters
  function setOwner(address _owner) external {
    require(msg.sender == owner, "Function only callable by owner!");

    owner = _owner;
  }

  function setRegisterPrice(uint256 _registerPrice) external {
    require(msg.sender == owner, "Function only callable by owner!");

    registerPrice = _registerPrice;
  }

  /////////////////////
  // Register functions
  receive() external payable {
    register();
  }

  function register() public payable {
    require(!userToRegistered[msg.sender], "Address already registered!");
    require(msg.value >= registerPrice);

    userToRegistered[msg.sender] = true;
  }

  function registerBetaUser(address _user) external {
    require(!userToRegistered[_user], "Address already registered!");
    require(msg.sender == owner, "Function only callable by owner!");

    userToRegistered[_user] = true;
  }

  /////////////////
  // Withdraw Ether
  function withdraw(uint256 _amount, address _receiver) external {
    require(msg.sender == owner, "Function only callable by owner!");

    payable(_receiver).transfer(_amount);
  }
}

