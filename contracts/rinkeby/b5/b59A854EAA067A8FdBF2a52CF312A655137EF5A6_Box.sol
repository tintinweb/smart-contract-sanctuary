// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
 
contract Box {
    uint256 private value;
    uint public freeMe;
    uint public freeMeAGain;
    uint public freeMeAGainAnother1111;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        freeMe = 5;
        freeMeAGain = 1;
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}

{
  "optimizer": {
    "enabled": true,
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