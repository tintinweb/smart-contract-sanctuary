pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract OilPriceOracle {
    AggregatorV3Interface internal priceFeedOilUSD;
    AggregatorV3Interface internal priceFeedEthUSD;

    constructor() public {
        priceFeedOilUSD = AggregatorV3Interface(
            0x6292aA9a6650aE14fbf974E5029f36F95a1848Fd
        );
        priceFeedEthUSD = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestOilPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 OilPrice,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedOilUSD.latestRoundData();
        return uint256(OilPrice) / 100000000;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 EthPrice,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedEthUSD.latestRoundData();
        return uint256(EthPrice) / 100000000;
    }

    function OilpricePerEth() public view returns (uint256) {
        uint256 OilPrice = getLatestOilPrice();
        uint256 EthPrice = getLatestEthPrice();

        return EthPrice / OilPrice;
    }
}

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