// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
  uint256 private state = 0;

  function getCurrentState() public view returns(uint256) {
    return state;
  }

  function updateState(uint256 _state) external {
    state = _state;
  }

  function num(uint256 _num) external pure returns(uint256) {
    return _num;
  }

  function str(string memory _name) external pure returns(string memory) {
    return string(abi.encodePacked("Hello, ", _name, "!"));
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
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