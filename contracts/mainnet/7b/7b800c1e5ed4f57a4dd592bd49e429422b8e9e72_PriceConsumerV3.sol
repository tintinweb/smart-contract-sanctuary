/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File @chainlink/contracts/src/v0.6/interfaces/[email protected]

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


// File contracts/oracle/IPriceConsumerV3.sol

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

abstract contract IPriceConsumerV3 {
    function getLatestPrice() public view virtual returns (int256);
}


// File contracts/oracle/PriceConsumerV3.sol

pragma solidity ^0.6.2;


contract PriceConsumerV3 is IPriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view override returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}