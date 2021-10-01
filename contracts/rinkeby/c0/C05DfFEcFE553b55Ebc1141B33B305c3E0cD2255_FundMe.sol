/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



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

//import "@chainlink/contracts/src/v0.8/vendor/SafeMathChainlink.sol";

contract FundMe {
    //using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }
    
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18;  // USD also has to be with 18 decimals
        // mozna wyslac 20000000000000000 wei = 0,02 ETh = ~56$  - to przejdzie
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        /* 
        if (msg.value < minimumUSD) {   // alternative way
            revert?
        }*/
        
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);  // we use it to reset balances after withdrawal
    }

    function getEntranceFee() public view returns(uint256) {
        //minimum USD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }
    
    function getVersion() public view returns (uint256) {
        // Rinkeby price feed oracle https://docs.chain.link/docs/ethereum-addresses/
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();  // alternative way, with just commas
        /*
        (uint80 roundId,
         int256 answer,
         uint256 startedAt,
         uint256 updatedAt,
         uint80 answeredInRound) = priceFeed.latestRoundData();
        */
        return uint256(answer * 10000000000);  // this will return price with 18 decimal places instead of default 8
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        //require(ethAmount >= 1000000000000000000, "This function requires price in Wei, with 18 decimal places");
        // 1 Wei = 0000000000000000001 ETH
        uint256 ethPrice = getPrice();  // 285448535517 = 2854.48535517 USD/ETH, 2854485355170000000000 = 2854.485355170000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount / 1000000000000000000); // / 1000000000000000000;
        return ethAmountInUsd;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;  // <code of functions wih this modifier will be executed/placed here (can also do it above require...) 
    }
    

    function withdraw() payable onlyOwner public {
        //require(msg.sender == owner);  // no need that anymore - i made modifier onlyOwner
        payable(msg.sender).transfer(address(this).balance);  // added payable() for 0.8.9
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);  // blank array
    }
}