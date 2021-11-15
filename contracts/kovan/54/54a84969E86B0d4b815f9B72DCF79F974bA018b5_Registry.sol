//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Registry {
  
  mapping (address => string) public names;
  mapping (string => address) public owners;

  event Registered(address indexed who, string name);

  function register(string memory name) external {
    require(owners[name] == address(0), "That name is already taken");
    address owner = msg.sender;
    owners[name] = owner;
    names[owner] = name;
    emit Registered(owner, name);
  }
}

