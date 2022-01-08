/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



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
    AggregatorV3Interface internal priceFeed;

    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // initiate the owner
        // owner = 0xB7Adc793e1d963DcB64290D651857a3e6E54eC4D;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner);
    //     _;
    // }

    function fundModified() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function fund() public payable {
        uint256 minimumValue = 100; // in wei
        require(msg.value > minimumValue, "not enough funds");
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public payable {
        // require(msg.sender == owner, "inavalid owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}