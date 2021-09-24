// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library RedeemLib {
    function calculateRedeemable(address token, uint256 amount)
        external
        pure
        returns (uint256 redeemable)
    {
        redeemable = amount;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "metadata": {
    "bytecodeHash": "none"
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