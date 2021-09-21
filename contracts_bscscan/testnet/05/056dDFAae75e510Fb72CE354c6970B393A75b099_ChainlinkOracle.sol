/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity 0.6.12;

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

interface IOracle {
    function getLatestPrice() external view returns (uint256);
}

contract ChainlinkOracle is IOracle {
    AggregatorV3Interface public priceFeed;

    constructor(address initialPriceFeed) public {
        priceFeed = AggregatorV3Interface(initialPriceFeed);
    }

    function getLatestPrice() public override view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "invalid-chainlink-price");
        return uint256(price) * (10 ** (18 - uint256(priceFeed.decimals())));
    }
}