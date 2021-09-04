// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


/**
 * @title AggregatorV3Interface
 * @dev Taken from https://www.npmjs.com/package/@chainlink/contracts to benchmark gas costs
 * The solidity version was bumped up to match our codebases
 */
interface AggregatorV3Interface {

  function decimals()
  external
  view
  returns (
    uint8
  );

  function description()
  external
  view
  returns (
    string memory
  );

  function version()
  external
  view
  returns (
    uint256
  );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
  external
  view
  returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

  function latestRoundData()
  external
  view
  returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../mocks/AggregatorV3Interface.sol";

/**
 * @title SampleChainlink
 * @dev An example of a contract that uses the most popular Chainlink Reference Data
 * It is used for benchmarking gas costs
 */
contract SampleChainlink {

  AggregatorV3Interface internal priceFeed;

  /**
   * Network: Kovan
   * Aggregator: ETH/USD
   * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
   */
  constructor() public {
    priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
  }

  /**
   * Returns the latest price
   */
  function executeWithPrice(uint val) public returns(uint256) {
    (, int price, , ,) = priceFeed.latestRoundData();
    return uint256(price);
  }
  
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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