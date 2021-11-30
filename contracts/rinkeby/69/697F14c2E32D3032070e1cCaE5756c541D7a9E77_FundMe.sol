/**
 *Submitted for verification at Etherscan.io on 2021-11-30
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

contract FundMe {
    address public owner;
    mapping(address => uint256) public addressToAmountFunded;
    
    address[] public funders;
    constructor() public{
        owner = msg.sender;
    }

    function fund() public payable{
        uint256 minimumUSD = 1 * 10 ** 15;
        require(getConversionRate(msg.value) >= minimumUSD, "you need to spend more Eth");
        addressToAmountFunded[msg.sender] += msg.value;

        // what the ETh -> USD Converter 
        //Oracle is the bridge between real world and blockchain
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(address(0x9326BFA02ADD2366b30bacB125260Af641031331));
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(address(0x9326BFA02ADD2366b30bacB125260Af641031331));
        // (uint80 roundId,
        // int256 answer,
        // uint256 startedAt,
        // uint256 updatedAt,
        // uint80 answeredInRound) 
        // = priceFeed.latestRoundData();
        
        (,int256 answer,,,) = priceFeed.latestRoundData();

        // tuple 
        return uint256(answer * 10000000000); // typecasting

        // 8 decimals is returned
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public{
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance); // transferring the money back to the sender from the contract

        for (uint256 funderIndex= 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // this refers to the contract that you are in.
    }
   
}