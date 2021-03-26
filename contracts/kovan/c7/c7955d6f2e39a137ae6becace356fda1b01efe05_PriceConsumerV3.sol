/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// This example code is designed to quickly deploy an example contract using Remix.

pragma solidity ^0.6.7;

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

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }
    
  
// creating struct to assign the values to user
    struct userupdate{
        address useraddress;
        int price;
        uint time;
        int value;
    }

// mapping the userupdate to the useraddress
    mapping(address=>userupdate) public userPricelist;

// function to get the convertion rate of ETH/USD for the given value and assigning the values to userPricelist
    function getLatestPrice(int _value) public returns(int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
            userPricelist[msg.sender].useraddress=msg.sender;
            userPricelist[msg.sender].price=price;
            userPricelist[msg.sender].time=timeStamp;
            userPricelist[msg.sender].value=(price)*_value;
            return( userPricelist[msg.sender].price);
            
         }
         
// gets the price of the ETHInUSD, timeStamp and valueInUSD for the given value
         function getprice() public view returns(int ETHInUSD,uint dateTime,int valueInUSD ){
             return(  userPricelist[msg.sender].price,
            userPricelist[msg.sender].time,
            userPricelist[msg.sender].value);
         }

// delets the history of searchs of the user
         function deletehistory() public returns(bool){
             delete userPricelist[msg.sender];
             return true;
         }
}