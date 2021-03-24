// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorageV2 {
    uint storedData;
    mapping(address => uint) userData;

    event Change(string message, uint newVal);
    event ChangeV2(string message, address user, uint newVal);

    function getName() view public returns (string memory) {
        return "SimpleStorageV2";
    }

    function set(uint x) public {
        emit Change("set", x);
        storedData = x;
    }

    function get() view public returns (uint retVal) {
        return storedData;
    }

    function setForSender(uint x) public {
        emit ChangeV2("set", msg.sender, x);
        userData[msg.sender] = x;
    }

    function getForSender() view public returns (uint) {
        return userData[msg.sender];
    }

    function getForUser(address _user) view public returns (uint) {
        return userData[_user];
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}