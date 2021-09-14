/**
 *Submitted for verification at Etherscan.io on 2021-09-14
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

// File: FundMe.sol

contract FundMe{
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund() public payable{
        //$50
        
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConvertionPrice(msg.value)  >= minimumUSD , ' You need to spend more Eth');
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        
    }
    
    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
            ( ,int256 answer,,,) = priceFeed.latestRoundData();
            //returns data with 8 decimal places...but we are making it to 18 decimal places to maintain consistensy
            //3440.267102640000000000
            return uint256(answer * 10000000000);
            
    }
    
    function getConvertionPrice(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        //ethPrice and ethAmount both are in 18 decimanls...so divided by 18 decimals
        uint256 ethAmountInUsd = ( ethPrice * ethAmount ) / 1000000000000000000;
        return ethAmountInUsd;
        //0.000003447046820530... should be
    }
    
    modifier onlyOwner{
         require(msg.sender == owner, ' Need to be owner to withdraw');
         _;
    }
    
    function withdraw() payable onlyOwner public{
        msg.sender.transfer(address(this).balance);
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}