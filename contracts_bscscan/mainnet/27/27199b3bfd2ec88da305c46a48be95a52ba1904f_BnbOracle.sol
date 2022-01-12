/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org


// SPDX-License-Identifier: BUSL-1.1


// File contracts/interfaces/IBnbOracle.sol


pragma solidity 0.8.10;


interface IBnbOracle {
    function getRate(address currency) external view returns (int, uint8);
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/BnbOracle.sol


pragma solidity 0.8.10;


contract BnbOracle is IBnbOracle {
    
    // Maps a currency address (eg BUSD) to the chainlink price feed address (eg BUSD/BNB)
    mapping(address => address) public priceFeeds;

    constructor(address[] memory currencies, address[] memory feeds) {
        uint len = currencies.length;
        require(len > 0 && feeds.length == len, "Errors.VALIDATION_ERROR");

        address currency;
        address feed;
        for (uint n=0; n<len; n++) {
            currency = currencies[n];
            feed = feeds[n];
            require(currency != address(0) && feed != address(0));
            priceFeeds[currency] = feed;
        }
    }

    function getRate(address currency) external view override returns (int rate, uint8 decimals) {

        address feed = priceFeeds[currency];
        require(feed != address(0), "Errors.UNSUPPORTED_FEED");

        ( , rate, , , ) = AggregatorV3Interface(feed).latestRoundData();
        decimals = AggregatorV3Interface(feed).decimals();
    }
}