// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract GetSet {
    mapping(address => mapping(string => string)) _userData;
    
    function setUserData (string memory key, string memory value) public {
        _userData[msg.sender][key] = value;
    }
    
    function getUserData (address userAddress, string memory key) public view returns (string memory) {
        return _userData[userAddress][key];
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