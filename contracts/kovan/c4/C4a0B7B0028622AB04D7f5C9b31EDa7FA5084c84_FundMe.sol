/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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

// File: Fund_Me.sol

//just a comment

contract FundMe{
    mapping (address => uint256) public addressToAmountFunded;
    // get the owner immediately ths copntact gets ccalled using constructor
    address[] public funders;
    address public owner;
    //#globalise so  ganache can get price of ether
    AggregatorV3Interface public priceFeed;
    constructor(address _priceFeed) public{
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }
    function fund () public payable{
        //$50 converting it into gwei
        uint256 minimumUSD = 50 * 10 ** 18;
        //1gwei < $50
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    function getVersion() public view returns(uint256){
        return priceFeed.version();

    }
    function getPrice() public view returns(uint256){
        (uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )=priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }   
    function getConversionRate(uint256 ethAmount) public view returns(uint256 ) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice *  ethAmount)/1000000000000000000;
        return ethAmountInUsd;
    }
    function getEntranceFee() public view returns(uint256){
        //minimum USD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price =getPrice();
        uint256 precision = 1* 10**18;
        return(minimumUSD *precision)/price;
    }
    //modifier are used tochange the behaviour of the fun in a declarative way
    modifier onlyOwner {
    	//is the message sender owner of the contract?
        require(msg.sender == owner);
        
        _;
    }
    function withdraw()  payable onlyOwner public {
        
        payable(msg.sender).transfer(address (this).balance);
        for(uint256 funderIndex=0;funderIndex<funders.length;funderIndex++){
            address funder =funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}