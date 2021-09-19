/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

/*
 * Network: Rinkbey
 * Token: EHT/USD
 * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
*/

contract FundMe {

    // keeps track of account which gave funds 
    mapping(address => uint256) public addressToAmmountFunded;
    address public owner;
    address[] public funders;
    
    constructor() {
        owner = msg.sender;
    }
    
    // payable define that function is accepting payaments in form of etherium
    function fund() public payable {
        
        // stting minium fund amount to $50 
        uint256 miniumAmount = 50 * 10 ** 18;

        // check if requirement is met 
        require(getConversionRate(msg.value) >= miniumAmount, "You need to spent more ETH!!");
        
        addressToAmmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256){
      AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
      return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        (,int256 price,,,) = priceFeed.latestRoundData();
        
        return uint256(price * 10000000000);
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        
        uint256 ethPrice = getPrice();
        
        return (ethAmount * ethPrice) / 1000000000000000000;
    }
    
    // called with function and runs the code in modifier
    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable OnlyOwner public  {
        payable(msg.sender).transfer(address(this).balance);
        
        for (uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) {
            address funder = funders[fundersIndex];
            addressToAmmountFunded[funder] = 0;
        }
        
        funders = new address[](0);
    }
}