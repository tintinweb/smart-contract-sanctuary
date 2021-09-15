/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// Part: AggregatorV3Interface

// # import and defining interface => interchangable.

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface";

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

contract FundMe {
    // payable: used to pay for things
    // user can assign value for every function call
    
    // #1. track address -> contract eth transfer. which address pay what amount of dollars
    // #2. set minimum amount of funds

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() {  // if we opt for 'public' (visibility option) for this, got error.
        owner = payable(msg.sender);
    }

    function fund() public payable {
        // # set minimum value
        uint256 minimumUSD = 50 * 10 ** 18;
                   
        // # require statement => minimum. 
        require(getConversionRate(msg.value) > minimumUSD, "You need to spend more ETH!"); // else, revert.
        addressToAmountFunded[msg.sender] += msg.value;
        // msg.sender = the sender of function call
        // msg.value = how much they sent.
        // what the eth -> usd conversion rate
        // tell solidity what functions can be called on another contract. 
        funders.push(msg.sender);
    }  

    // # decimals does not work in solidity
    // testnet 

    function getVersion() public view returns (uint256){
        AggregatorV3Interface PriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        return PriceFeed.version();
    }
    function getPrice() public view returns (uint256){
        AggregatorV3Interface PriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        (uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound)
        = PriceFeed.latestRoundData();
        // for int256 answer, we should yield uint256 results
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount);
        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender==owner);
        _; // underscore.  
    }

    function withdraw() payable onlyOwner public {
        // # this: CURRENT contract you are in.
        // address(this): address of ours, in 'this' contract
        // address(this).balance: balance of our addresss, in 'this' contract
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }         
        funders = new address[](0);
    }
}