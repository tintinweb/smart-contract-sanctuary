// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract StorageV1 {

    uint256 private _value;

    event ValueUpdated(uint256 value);
    
    function set(uint256 value) external {
        _value = value;
        emit ValueUpdated(_value);
    }

    function get() external view returns(uint256) {
        return _value;
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