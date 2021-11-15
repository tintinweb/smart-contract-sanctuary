// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OracleChainlink {

    string  public symbol;
    address public immutable feed;
    uint256 public immutable feedDecimals;
    uint256 public constant decimals = 18;

    constructor (string memory symbol_, address feed_) {
        symbol = symbol_;
        feed = feed_;
        feedDecimals = IChainlinkFeed(feed_).decimals();
    }

    function getPrice() external view returns (uint256) {
        (, int256 price, , , ) = IChainlinkFeed(feed).latestRoundData();
        return uint256(price) * 10**(decimals - feedDecimals);
    }

}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

