/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: AggregatorV3Interface

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
    address public owner;
    mapping(address => uint256) public fundAddress;
    address[] public funders;
    AggregatorV3Interface public priceFeed;
    
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }
    function fund() public payable {
        //set minimum to $50 usd
        
        uint256 minimumUSD = 50 * 10 ** 18;
        
        require(getConversionRate(msg.value) > minimumUSD, "minimum spending is $50");
        fundAddress[msg.sender] += msg.value;
        funders.push(msg.sender);
        //convert eth -> usd
         
    }
    
    function getVersion() public view returns (uint256) {
        // bsc bnb/busd testnet 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        // eth/usd rinkeby0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256) {
        // bsc bnb/busd 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        // eth/usd rinkeby0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ( uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
        ) =  priceFeed.latestRoundData();
        
        return uint256(answer) * 10 ** 18;
    }
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUsd;
    }
    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "You're not the owner!");
        _;
    }
    function withdraw() payable onlyOwner public {
        
        
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            fundAddress[funder] = 0;
        }
        funders = new address[](0);
    }
}