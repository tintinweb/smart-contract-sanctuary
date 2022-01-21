/**
 *Submitted for verification at Etherscan.io on 2022-01-21
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
    constructor() public{
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
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();

    }
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
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