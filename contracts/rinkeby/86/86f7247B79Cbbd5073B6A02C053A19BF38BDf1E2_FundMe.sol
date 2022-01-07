// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    uint256 public amount;

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUsd = 50;
        require(getConversionRate(msg.value) > minimumUsd, "deployed wrong");
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getLastestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getConversionRate(uint256 _amount) public view returns (uint256) {
        uint256 ethPrice = getLastestPrice();
        uint256 inUsd = (ethPrice * _amount) / 1_000_000;
        return inUsd;
    }

    function who() public view returns (address) {
        return msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function withdraw() public payable onlyOwner {
        // require(owner == msg.sender, "not owner");
        payable(msg.sender).transfer(msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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