/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity >= 0.6.0 < 0.9.0;
// SPDX-License-Identifier: MIT

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


contract FundMe{
    
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] funders;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund() public payable{
        uint minimumUSD = 50 * 10 **18;
        require(getConversionRate(msg.value) > minimumUSD, "You need to pay more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
        
    }
    
     function getPrice() public view returns(uint256){
         AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
         
         (,int256 answer, , , ) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);
     }
    
    function getConversionRate(uint ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
           
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function withDraw() payable onlyOwner public{
        msg.sender.transfer(address(this).balance);
        for(uint256 i = 0; i < funders.length; i++){
            addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
}