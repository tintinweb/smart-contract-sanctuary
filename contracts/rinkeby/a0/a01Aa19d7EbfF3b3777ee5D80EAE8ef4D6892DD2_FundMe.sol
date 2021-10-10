/**
 *Submitted for verification at Etherscan.io on 2021-10-10
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

contract FundMe{
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    //constructor is a function called the instant your contract is deployed
    constructor() public{
        owner = msg.sender;
    }
    
    
    //payable , able to accept some type of payment
    function fund() public payable{
        //$50
        uint256 minimumUSD = 50 * 100000000;
        //checking the truethiness of whatver require we have
        //if they didn't send us enough ether then exceute
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        
        //msg.sender = sender of function call
        //msg.value = how much they send
        addressToAmountFunded[msg.sender] += msg.value;
        //what the ETH -> USD conversion relocatable
        
        //if someon used this contract add it to array
        funders.push(msg.sender);
    }
    
    //view if you are just gonna be reading a state
    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    //get price public view
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        //get the tuple value
        //ignore some variables that are not in used by making it blank
        /*
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        */
        (,int price,,,) = priceFeed.latestRoundData();
        //typecasting on solidity
        return uint256(price);
    }
    
    //convert value to usd
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/100000000;
        return ethAmountInUsd;
    }
    
    //MOdifier is used to change the behavior of function in a declarative way
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable onlyOwner public{
        //only want the contract admin/owner
        //require msg.sender = owner
        payable(msg.sender).transfer(address(this).balance);
        
        //everytime you withdraw make balance 0 of the owner address
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //create a new funders array
        funders = new address[](0);
    }
    
}