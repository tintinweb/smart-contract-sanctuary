//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe
{
    mapping(address => uint256) public addressToAmountFund;
    address[] funders;

    address payable public owner;
    AggregatorV3Interface price_feed;

    constructor(address _address)
    {
        owner = payable(msg.sender);
        price_feed = AggregatorV3Interface(_address);
    }

    function fund() public payable
    {
        uint256 minimumUSD = usdToWeigh(50);
        require(msg.value >= minimumUSD, "You need to spend more USD");
        addressToAmountFund[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner
    {
        require(payable(msg.sender) == owner, "You are not the owner");
        _;
    }

    function withdraw() public payable onlyOwner
    {
        owner.transfer(address(this).balance);
        
        for(uint256 i = 0; i < funders.length; i++)
        {
            address funderAddress = funders[i];
            addressToAmountFund[funderAddress] = 0;
        }

        funders = new address[](0);
    }

    function getBalanceAtAddress(address _address) public view returns(uint256)
    {
        return addressToAmountFund[_address];
    }

    function getVersion() public view returns (uint256)
    {
        return price_feed.version();
    }

    function getPrice() public view returns (uint256)
    {
        (,int256 answer,,,) = price_feed.latestRoundData();

        return uint256(answer);
    }

    function usdToWeigh(uint256 usdAmount) public view returns (uint256)
    {
        uint256 decimals = uint256(price_feed.decimals());
        return ((usdAmount * 1000000000000000000) / getPrice()) * 10 ** decimals;
    }

    // function getConversionRate(uint256 ethAmount) public view returns (uint256)
    // {
    //     uint256 ethPrice = getPrice();
    //     uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    //     return ethAmountInUsd;
    // }
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