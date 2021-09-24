/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
  AggregatorV3Interface priceOracle;
  address public owner;

  uint256 MIN_USD_FUND = 50 * 10**18;
  mapping(address => uint256) public funds;
  address[] public funders;

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  constructor(address _priceOracle) {
    priceOracle = AggregatorV3Interface(_priceOracle);
    owner = msg.sender;
  }

  function fund() public payable {
    require(getConversionRate(msg.value) >= MIN_USD_FUND, "not enough fund");
    funds[msg.sender] = msg.value;
    funders.push(msg.sender);
  }

  function getConversionRate(uint256 _ethAmount) public view returns (uint256) {
    uint256 ethPrice = getPrice();
    uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 10**18;
    return ethAmountInUsd;
  }

  function withdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
    for (uint256 index = 0; index < funders.length; index++) {
      address funder = funders[index];
      funds[funder] = 0;
    }
    funders = new address[](0);
  }

  function getPriceOracleVersion() public view returns (uint256) {
    return priceOracle.version();
  }

  function getPrice() public view returns (uint256) {
    (, int256 answer, , ,) = priceOracle.latestRoundData();
    return uint256(answer * 10**10);
  }

  function getEntranceFee() public view returns (uint256) {
    uint256 ethPrice = getPrice();
    uint256 precision = 1 * 10**18;
    return (MIN_USD_FUND * precision) / ethPrice;
  }
}