// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe{

    mapping(address => uint256) public paidAmount;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Hirsiz varr");
        _;
    }

    function fund() payable public {
        //50$
        uint256 minimumPayment = 50 * (10 ** (getDecimal()));
        require(ethToUsd(msg.value) >= minimumPayment,"Yetersiz Odeme");
        paidAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 idx = 0; idx < funders.length; idx++) {
            address funder = funders[idx];
            paidAmount[funder] = 0;
        }
        funders = new address[](0);
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return feed.version();
    }
    function getDecimal() public view returns(uint8) {
        AggregatorV3Interface feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return feed.decimals();
    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,) = feed.latestRoundData();
        return uint256(price);
    }

    // 1GWEI = 10**9 WEI, 1ETH = 10**9 GWEI 
    function ethToUsd(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethUsd = (ethPrice * ethAmount) / (10**18);
        return ethUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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