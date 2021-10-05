/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: contract.sol

contract PriceConverter {
    AggregatorV3Interface internal eth_usd_price_feed;
    AggregatorV3Interface internal jpy_usd_price_feed;

    constructor() {
        eth_usd_price_feed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        jpy_usd_price_feed = AggregatorV3Interface(
            0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942
        );
    }

    function getEthUsd() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = eth_usd_price_feed.latestRoundData();

        return price;
    }

    function getJpyUsd() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = jpy_usd_price_feed.latestRoundData();

        return price;
    }

    function getJpyEth(uint256 _amountInJpy) public view returns (uint256) {
        uint256 newInput = _amountInJpy * 10**8;

        uint256 EthUsd = uint256(getEthUsd());
        uint256 JpyUsd = uint256(getJpyUsd());

        return (newInput * JpyUsd) / EthUsd;
    }
}