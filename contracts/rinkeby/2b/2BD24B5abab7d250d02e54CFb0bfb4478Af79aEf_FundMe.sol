/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;



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

// File: FundMe.sol

contract FundMe {
    address public owner;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 min = 50 * 10**18;
        require(getConversionRate(msg.value) >= min, "Need More ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountUsd;
        //.000003806890000000
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
}