// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./IPancakePair.sol";


contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;
    IPancakePair private pancakePair;
    

    /**
     * Network: BSC Testnet
     * Aggregator: BNB/USD
     * Address: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
     */
    constructor(address _pairAddress) {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        pancakePair = IPancakePair(_pairAddress);
    }

    /**
     * Returns the latest price
     */
    function getLatestBNBPrice() public view returns (int) {
        (
            uint80 roundID,  
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getPrice() public view returns (uint) {
        (
            uint112 _reserve0, 
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ) = pancakePair.getReserves(); 
        int _BNBprice = getLatestBNBPrice();
        return (uint(_reserve1)*uint(_BNBprice)*100)/(uint(_reserve0));
    }

    function convertToToken(uint USD) external view returns (uint)
    {
        uint tkPrice = getPrice();
        return (USD * 10**28)/tkPrice;
    }
    
    function tokenPrice() external view returns (uint)
    {
        uint tkPrice = getPrice();
        return tkPrice;
    }
}