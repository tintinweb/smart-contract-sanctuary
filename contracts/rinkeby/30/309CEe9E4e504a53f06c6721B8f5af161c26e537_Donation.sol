// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "AggregatorV3Interface.sol";

contract Donation {
    address payable owner;

    AggregatorV3Interface internal priceFeed;

    mapping(address => uint256) public donationByAddress;

    constructor(address _priceFeed) {
        owner = payable(msg.sender);

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "This is an owner only function");
        _;
    }

    modifier minValue(uint256 value) {
        require(msg.value >= value, "Minimal call value isn't satisfied");
        _;
    }

    modifier minUsdValue(uint256 usd) {
        uint256 weiRequired = convertUsdToWei(usd);
        require(msg.value >= weiRequired, "Not enough value.");
        _;
    }

    function donate() public payable minUsdValue(10) {
        uint256 usdDonated = convertToUsd(msg.value);
        donationByAddress[msg.sender] += usdDonated;
    }

    function convertUsdToWei(uint256 usd) public view returns (uint256) {
        uint256 usdRate = getLatestPrice();
        uint8 decimals = priceFeed.decimals();

        uint256 usdInWei = ((usd * 10**(decimals + 18)) / usdRate);

        return usdInWei;
    }

    function convertToUsd(uint256 weiValue) public view returns (uint256) {
        uint256 usdRate = getLatestPrice();
        uint8 decimals = priceFeed.decimals();

        uint256 converted = (usdRate * weiValue) / 10**(18 + decimals);

        return converted;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    function withdraw() external payable ownerOnly {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
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