// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BASEFEE_LOGIC {
    function RETURN_BASEFEE() external view returns (uint256) {
        return block.basefee;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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