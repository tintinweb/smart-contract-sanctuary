// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "PriceConsumerV3.sol";

contract FundMe {
    address owner;
    PriceConsumerV3 feed;
    mapping(address => uint256) public founders;

    constructor(address ethUSDFeedAddrs) {
        owner = msg.sender; // who deployed the contract is the owner automatically
        feed = new PriceConsumerV3(ethUSDFeedAddrs);
    }

    function fund() public payable {
        uint256 minimumUSD = 5 * 10**18; // conversion to wei
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Minimum ETH is $5 (USD)"
        );
        founders[msg.sender] += msg.value;
    }

    function withdraw() public payable {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getETHPriceInUSD() public view returns (uint256) {
        return feed.getLatestPrice();
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getETHPriceInUSD();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    uint256 gweiScale = 1000000000;
    AggregatorV3Interface internal priceFeed;

    constructor(address feedAddr) {
        priceFeed = AggregatorV3Interface(feedAddr);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price) * gweiScale; // USD
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