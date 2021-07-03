/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface AggregatorV3Interface {  
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);  // getRoundData and latestRoundData should both raise "No data present"
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
    
interface Oracle {
    function setEthererumPrice() external;
    function getEthererumPrice() external view returns(int);
}

contract oracle {
    AggregatorV3Interface internal priceFeed1;
    
    constructor() {
        priceFeed1=AggregatorV3Interface(0x10900f50d1bC46b4Ed796C50A4Cc63791CaF7501);
    }
    
    int ethereumPrice;
    
    function setEthererumPrice() public {        
        (, int price, , ,) = priceFeed1.latestRoundData();
        ethereumPrice = price;
    }
    
    function getEthererumPrice() public view returns(int) {
        return ethereumPrice;
    }
}