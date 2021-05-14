// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./SourceMock.sol";


contract ChainlinkAggregatorV3Mock is SourceMock {
    int public price;   // Prices in Chainlink can be negative (!)
    uint public timestamp;

    function set(uint price_) external override {
        price = int(price_) / 1e10;          // Provide prices with 18 decimals, which will be scaled down to Chainlink's 8
        timestamp = block.timestamp;
    }

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, price, 0, timestamp, 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface SourceMock {
    function set(uint) external;
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
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}