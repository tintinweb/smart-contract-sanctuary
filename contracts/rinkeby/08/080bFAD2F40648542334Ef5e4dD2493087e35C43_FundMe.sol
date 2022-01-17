// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "PriceConsumerV3.sol";

contract FundMe {
    address owner;
    PriceConsumerV3 feed;
    mapping(address => uint256) public funders;
    address[] fundersList = new address[](0); // empty list

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only account owner is allowed to perform this operation"
        );
        _;
    }

    constructor(address ethUSDFeedAddrs) {
        owner = msg.sender; // who deployed the contract is the owner automatically
        feed = new PriceConsumerV3(ethUSDFeedAddrs);
    }

    function fund() public payable {
        require(
            getConversionRate(msg.value) >= getEntranceFee(),
            "Minimum ETH is $5 (USD)"
        );
        funders[msg.sender] += msg.value;
        fundersList.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 idx = 0; idx < fundersList.length; idx++) {
            funders[fundersList[idx]] = 0;
        }
        fundersList = new address[](0);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = feed.getLatestPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18; // 5 USD represented in wei
        uint256 price = feed.getLatestPrice();
        uint256 precision = 1 * 10**18;

        return (minimumUSD * precision) / price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    uint256 gweiScale = 10000000000;
    AggregatorV3Interface internal priceFeed;

    constructor(address feedAddr) {
        priceFeed = AggregatorV3Interface(feedAddr);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(uint256(price) * gweiScale); // USD
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