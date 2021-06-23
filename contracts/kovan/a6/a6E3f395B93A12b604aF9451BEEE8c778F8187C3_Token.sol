// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IPoke {

    function poke() external;

    event NewBlockDataPoint(uint256 value, uint256 blocknumber);
    event NewTimeSeriesDataPoint(uint256 value, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "./IPoke.sol";

contract Token is IPoke {

    function fireEvent(uint256 value) public {
        emit NewBlockDataPoint(value, block.number);
        emit NewTimeSeriesDataPoint(value, block.timestamp);
    }

    function poke() override external {
        fireEvent(42);
    }

    event NewBlockDataPoint(int256 value, uint256 blocknumber);
    event NewTimeSeriesDataPoint(int256 value, uint256 timestamp);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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