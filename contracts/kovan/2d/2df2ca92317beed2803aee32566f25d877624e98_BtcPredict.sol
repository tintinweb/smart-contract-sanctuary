// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "AggregatorV3Interface.sol";

contract BtcPredict {

    AggregatorV3Interface internal priceFeed;
     constructor() public {
        priceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
    }
 
    function getThePrice() private view returns (int256) {
        (
            , 
            int256 price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        
        return (price);
    }
    
    function checkresult(int256 predict)  public view returns (string memory)
    {
        int256 price = getThePrice() / 100000000;
        string memory message;
        if(predict - price > 0)
          message = "the price is more then your predict benlnwza";
        else if ( predict - price < 0)
          message = "the price is less than your predict benlnwza";
        else
          message = "WOW!!! You guessed it right";
          
        return message;
    }

}