/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



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

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;


    constructor (address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function getPrice() public view returns (uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        // 18 - decimals() = 10
        return uint256(price * 10 ** 10);
    }

    function getEntranceFee() public view returns(uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision) / price;
    }


    function fund () public payable {
        uint256 minimumETH = 50 * 10 ** 18;
        // if (msg.value <  minimumETH) ...
        // Bug HERE uint256 -> int256 .. need to think in a better solution.
        require(getConversionRate(msg.value) >= minimumETH, "You need to spend more eth!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }


    // function getConversionRate2(int256 amount) public view returns (int256) {
    //     (,int256 price,,,) = priceFeed.latestRoundData();

    //     // Fetch decimals
    //     uint8 decimals = priceFeed.decimals();

    //     // Normalize to 18 decimal places (aka converting to WEI)
    //     price = price * 10 ** uint8(18) - decimals;

    //     // In wei
    //     int256 weiAmountInUsd = price * amount;

    //     // In ETH
    //     int256 ethAmountInUsd = weiAmountInUsd / (10 ** 18);

    //     return ethAmountInUsd;
    // }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        // Get the latest value
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10 ** 18);
        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the bosses");
        _;
    }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }
}