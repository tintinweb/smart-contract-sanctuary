/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

contract getPrice{
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    address public owner;
    AggregatorV3Interface public priceFeed;
    
    
    constructor(AggregatorV3Interface priceFeed_) public{
        owner = msg.sender;
        priceFeed = priceFeed_;
    }
    
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        roundID; startedAt; timeStamp; answeredInRound;
        
        return uint256(price);
    }
    
    function setPriceFeed(AggregatorV3Interface priceFeed_) public onlyOwner{
        priceFeed = priceFeed_;
    }
    
    function setOwner(address owner_) public onlyOwner{
        owner = owner_;
    }
}