/**
 *Submitted for verification at BscScan.com on 2021-11-14
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

// File: Fundme.sol

contract Fundme{
    
    mapping(address=>uint256) public addressToAmountFunded;
    AggregatorV3Interface priceFeedObject;
    
    address owner;
    address[] funders;
    
    function fund() public payable{
        uint256 minimum_USD = 1 * 10 ** 18;//real price with 18 decimals
        require(GetConversionRate(msg.value) >= minimum_USD, "Minumim amount to fund is 50$!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    constructor(address DataFeedAdress) public{
        priceFeedObject = AggregatorV3Interface(DataFeedAdress);
        owner = msg.sender;
    }

    function getPrice() public view returns(uint256){
        (,int price,,,) = priceFeedObject.latestRoundData();//Gives the price with 8 additional decimals.
        return uint256(price * 10**10);//USD Price * 10**18
    }

    modifier OnlyOwner(){
       require(msg.sender == owner, "only owner can use this function");
       _;
    }
    
    function GetConversionRate(uint256 ETH_In_Wei) public view returns(uint256){
        uint256 currentPrice = getPrice();
        //ETH_In_Wei = realETHAmount * 10**18
        //eth amount * 1 eth price = eth amount price * 10 * 36
        return (currentPrice * ETH_In_Wei) / 10**18;
    }
    
    function getEntranceFee() public view returns(uint256){
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 10 ** 18;
        return (minimumUSD * precision) / price;
    }
    
    function Withdraw() payable OnlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
    }

}