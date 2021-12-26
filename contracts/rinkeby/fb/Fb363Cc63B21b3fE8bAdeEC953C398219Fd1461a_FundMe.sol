// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    address priceFeedAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
    mapping(address => uint256) public funders;
    address[] public funders_array;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * (10**10));
    }

    function getConversionRate(uint256 eth) public view returns (uint256) {
        uint256 price = getPrice();
        uint256 usd = (eth * price) / (10**18);
        return usd;
    }

    function fund() public payable {
        uint256 minUSD = 50 * (10**18);
        require(getConversionRate(msg.value) >= minUSD, "Need more USD");
        funders[msg.sender] += msg.value;
        funders_array.push(msg.sender);
    }

    function withdraw() public payable {
        require(msg.sender == owner, "Ownerable");
        for (uint256 index = 0; index < funders_array.length; index++) {
            address addr = funders_array[index];
            funders[addr] = 0;
        }
        funders_array = new address[](0);
        payable(msg.sender).transfer(address(this).balance);
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