// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;


contract Time {
    uint public counter;

    function foo(uint threshold) external {
        require(counter < threshold, "Counter is too big");
        ++counter;
    }

    function getTime() external view returns (uint) {
        return block.timestamp;
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