/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.6.0;

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

contract PriceConsumerV3 {

    AggregatorV3Interface internal BTCpriceFeed;
    AggregatorV3Interface internal ETHpriceFeed;

    /**
     * Network: Kovan
     * Aggregator: BTC/USD
     * Address: 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
     *
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     *
     * Network: Mainnet
     * Aggregator: BTC/USD
     * Address: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     *
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() public {
        BTCpriceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        ETHpriceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * Returns the latest BTC price in USD
     */
    function getBTCprice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = BTCpriceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns the latest ETH price in USD
     */
    function getETHprice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ETHpriceFeed.latestRoundData();
        return price;
    }
}