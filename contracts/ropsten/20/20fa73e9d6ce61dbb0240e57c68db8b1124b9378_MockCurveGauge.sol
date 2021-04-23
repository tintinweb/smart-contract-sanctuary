// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

contract MockCurveGauge {
    function minter() external pure returns (address) {
        return address(0);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
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