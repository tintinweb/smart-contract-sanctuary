pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Oracle {
    AggregatorV3Interface internal priceFeed;
    uint8 private _networkId;
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */

    /**
     * Network: Binance Smart Chain
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
     */
    // network ID
    constructor(uint8 networkId) public {
        _networkId = networkId;
        if (_networkId == 1) {
            // ETH mainnet
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        }
        if (_networkId == 42) {
            // ETH kovan
            priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        }
        if (_networkId == 56) {
            // BCS mainnet
            priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        }
        if (_networkId == 97) {
            // BCS testnet
            priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256, uint8) {

        (
         ,
        int256 price,
        ,
         ,

        ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();

        return (uint256(price), decimals);
    }

    function getCustomPrice(address aggregator) public view returns (uint256) {
        AggregatorV3Interface priceToken = AggregatorV3Interface(aggregator);
        (
        ,
        int price,
        ,
       ,

        ) = priceToken.latestRoundData();
        return uint256(price);
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