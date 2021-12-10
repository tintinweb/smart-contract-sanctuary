/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// File: contracts/BloctoPointExchange.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


contract BloctoPointExchange {

    AggregatorV3Interface internal priceFeed;
    uint internal _usdPricePerPointDecimals = 8;
    uint internal _usdPricePerPoint = 1 * 10**(_usdPricePerPointDecimals-3); // default 0.001 usd

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return price;
    }

    function estimateCost(uint points) public view returns (uint) {
        return points * _usdPricePerPoint / uint(getLatestPrice());
    }
}