// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract WarriorType {
  enum WarriorClass {
    NoClass,
    Soldier,
    Archer,
    Knight
  }
  mapping(address => WarriorClass) private classMap;

  event Fight(address _attacker, address _target, bool _win);

  function getClass() external view returns (WarriorClass) {
    return classMap[msg.sender];
  }

  function setClass(WarriorClass _class) external {
    classMap[msg.sender] = _class;
  }

  function fight(address _target) external {
    bool win = classMap[_target] < classMap[msg.sender];
    if (
      classMap[_target] == WarriorClass.Soldier &&
      classMap[msg.sender] == WarriorClass.Knight
    ) {
      win = false;
    }

    if (
      classMap[_target] == WarriorClass.Knight &&
      classMap[msg.sender] == WarriorClass.Soldier
    ) {
      win = true;
    }

    emit Fight(msg.sender, _target, win);
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