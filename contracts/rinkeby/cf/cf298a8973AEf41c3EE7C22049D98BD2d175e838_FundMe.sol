// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping (address => uint) public addressToAmountFunded;
    address public owner;
    address[] funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint minFund_USD = 50 * 10 ** 18; 

        require(getConversionRate(msg.value) >= minFund_USD, "Minimum fund should be $50.00");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint(answer * 10 ** 10);
    }

    function getConversionRate(uint ethAmount) public view returns(uint) {
        uint ethPrice = getPrice();
        uint ethAmountInUSD = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUSD;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function!");
        _;
    }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance); 
        for (uint funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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