/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// File: Resultant.sol


pragma solidity 0.8.9;

interface PriceFeed {
    function latestAnswer() external view returns (uint256);
}

contract ResultantV1 {
    PriceFeed public btc;
    PriceFeed public eth;
    PriceFeed public bnb;

    constructor(PriceFeed _btc,
                PriceFeed _eth,
                PriceFeed _bnb) {
        btc = _btc;
        eth = _eth;
        bnb = _bnb;
    }

    function result() external view returns (bool) {
        uint256 btcPrice = btc.latestAnswer();
        uint256 ethPrice = eth.latestAnswer();
        uint256 bnbPrice = bnb.latestAnswer();

        uint256 sum = btcPrice + ethPrice + bnbPrice;

        return sum % 2 == 0;
    }
}