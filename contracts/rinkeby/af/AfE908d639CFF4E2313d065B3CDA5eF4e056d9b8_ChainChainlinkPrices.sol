/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

pragma solidity ^0.6.2;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int);
  function decimals() external view returns (uint8);
}

/*
* This contract uses two chainlink price feeds to make a new price feed
* and has the interface needed for AAVE to interact with it.
* For price feeds A -> B and C -> B, outputs A -> C
*/

contract ChainChainlinkPrices is IChainlinkAggregator {

    address internal priceFeedAddress1;
    address internal priceFeedAddress2;
    IChainlinkAggregator internal priceFeed1;
    IChainlinkAggregator internal priceFeed2;
    IChainlinkAggregator internal priceFeedControl;

    /**
     * 
     */
    constructor(address p1, address p2) public {
        priceFeedAddress1 = p1;
        priceFeedAddress2 = p2;
        priceFeed1 = IChainlinkAggregator(p1);
        priceFeed2 = IChainlinkAggregator(p2);
    }
    
    /**
     * Returns the latest price
     */
    function getPrice1() public view returns (int) {
        return priceFeed1.latestAnswer();
    }    
    function getPrice2() public view returns (int) {
        return priceFeed2.latestAnswer();
    }
    function getPriceSource1() public view returns (address) {
        return priceFeedAddress1;
    }
    function getPriceSource2() public view returns (address) {
        return priceFeedAddress2;
    }
    /**
     * Converts DAI price to ETH using two feeds and returns 18 decimal point precision
     */
    function latestAnswer() public view virtual override returns (int) {
        int price1 = getPrice1();
        uint8 price1d = priceFeed1.decimals();
        int price2 = getPrice2();
        uint8 price2d = priceFeed2.decimals();
        int newprice = price1  * (int(10) ** (price2d - price1d + uint8(18))) / price2;
        return newprice;
    }
    function decimals() public view virtual override returns (uint8) {
        return uint8(18);
    }
}