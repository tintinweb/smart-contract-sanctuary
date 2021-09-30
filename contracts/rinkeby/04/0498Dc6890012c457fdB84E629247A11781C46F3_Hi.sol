// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/AbstractExpensiveLines.sol";

contract Hi {
  function say() public pure returns (string memory) {
    return 'Hi';
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