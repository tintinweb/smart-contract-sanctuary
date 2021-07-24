// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Counter {
  uint256 public count;
  uint256 public lastExecuted;

  function increaseCount(uint256 amount) external {
    require(
      ((block.timestamp - lastExecuted) > 180),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
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