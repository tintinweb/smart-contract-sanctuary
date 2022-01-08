// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping (address => uint256) public addressToAmountFunded;
    address payable public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
 
    function fund() public payable {
        // minimum amount is $50
        uint256 minAmount = 50*10**18;
        require (getConversionRate(msg.value) >= minAmount, "Minimum amount is 50$");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getDesc() public view returns (string memory) {
        return priceFeed.description();
    }

    function getPrice() public view returns (uint256) {
        (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) =  priceFeed.latestRoundData();
        return uint256(answer*10000000000);
    }

    function getConversionRate(uint256 _amount) public view returns (uint256) {
        uint256 ethPrice = (getPrice() * _amount)/1000000000000000000; // ETH amount in USD
        return ethPrice;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimum USD
        uint256 minimumUSD = 50*10**18;
        uint256 price = getPrice();
        uint256 precision = 1*10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function withdraw() payable public onlyOwner {
        owner.transfer(address(this).balance);

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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