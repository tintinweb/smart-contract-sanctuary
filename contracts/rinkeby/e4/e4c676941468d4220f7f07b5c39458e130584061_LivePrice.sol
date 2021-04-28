pragma solidity >=0.5.0 <0.8.0;

import "AggregatorV3Interface.sol";

contract LivePrice {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum MainNet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            uint timeStamp,

        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        require(price > 0, "Price calculation error");
        return price;
    }
}