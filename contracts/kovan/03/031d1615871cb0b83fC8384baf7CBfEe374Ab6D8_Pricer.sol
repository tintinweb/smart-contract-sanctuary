// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Pricer {
  AggregatorV3Interface internal priceFeed;
  int256 lastPrice = 0;

  /**
   * Network: Kovan
   * Aggregator: ETH/USD
   * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
   */
  constructor() public {
    priceFeed = AggregatorV3Interface(
      0x9326BFA02ADD2366b30bacB125260Af641031331
    );
    lastPrice = getLatestPrice();
  }

  function priceChanged() external returns (int256) {
    int256 currentPrice = getLatestPrice();
    if (lastPrice > currentPrice) {
      lastPrice = currentPrice;
      return -1;
    } else if (lastPrice < currentPrice) {
      lastPrice = currentPrice;
      return 1;
    }
    return 0;
  }

  /**
   * Returns the latest price
   */
  function getLatestPrice() public view returns (int256) {
    (
      uint80 _roundID,
      int256 price,
      uint256 _startedAt,
      uint256 _timeStamp,
      uint80 _answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

