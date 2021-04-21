// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract MockChainlinkAggregator {
    uint256 public mock_price;
    uint8 public mock_decimals;

    constructor(uint256 _mock_price, uint8 _decimals){
        mock_price = _mock_price;
        mock_decimals = _decimals;
    }

    function decimals() external view returns (uint8) {
        return mock_decimals;
    }

    function latestRoundData() external view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId =0;
        answer = mock_price;
        startedAt = 0;
        updatedAt=0;
        answeredInRound=0;
    }

    function setLatestPrice(uint256 _mock_price) public {
        mock_price = _mock_price;
    }

    function setDecimals(uint8 _decimals) public {
        mock_decimals = _decimals;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
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