// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Struct {
  struct Profile {
    string username;
    uint256 age;
    address payable txAddress;
  }

  mapping(string => Profile) public map;
  mapping(string => bool) public usernameRegister;

  function createProfile(string memory username, uint256 age) external {
    require(usernameRegister[username] == false, "Cannot duplicate username");
    map[username] = Profile(username, age, payable(msg.sender));
    usernameRegister[username] = true;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}