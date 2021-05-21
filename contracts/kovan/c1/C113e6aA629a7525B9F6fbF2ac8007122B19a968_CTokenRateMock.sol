// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./ISourceMock.sol";


contract CTokenRateMock is ISourceMock {
    uint public borrowIndex;

    function set(uint rate) external override {
        borrowIndex = rate;          // I'm assuming Compound uses 18 decimals for the borrowing rate
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISourceMock {
    function set(uint) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 5000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}