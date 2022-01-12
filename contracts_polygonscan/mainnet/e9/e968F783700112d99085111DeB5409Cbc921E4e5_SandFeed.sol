// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract SandFeed {

    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;


    constructor() {
        priceFeed1 = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);     
        priceFeed2 = AggregatorV3Interface(0x3D49406EDd4D52Fb7FFd25485f32E073b529C924);  
    }

    function getThePrice() public view returns (int) {   
         
      /**
       * Returns the latest price of MATIC-USD
      */
    
      (             
       uint80 roundID1,              
       int price1,            
       uint startedAt1,             
       uint timeStamp1,
       uint80 answeredInRound1        
       ) = priceFeed1.latestRoundData();  
     
     /**
      * Returns the latest price of SAND-USD
     */
    
      (             
       uint80 roundID2,              
       int price2,            
       uint startedAt2,             
       uint timeStamp2,
       uint80 answeredInRound2        
       ) = priceFeed2.latestRoundData();  
     
    
    int sandMatic = price2*(10**18)/price1;
    return sandMatic;
    }
     
}