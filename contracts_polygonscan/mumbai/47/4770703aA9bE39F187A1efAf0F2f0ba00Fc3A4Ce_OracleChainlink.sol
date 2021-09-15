/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OracleChainlink {

    string public symbol;
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

contract OracleFactoryChainlink {

    event CreateOracleChainlink(string symbol, address feed, address oracle);

    // symbol => feed
    mapping (string => address) _feeds;

    // symbol => oracle
    mapping (string => address) _oracles;

    function getFeed(string memory symbol) external view returns (address) {
        return _feeds[symbol];
    }

    function getOracle(string memory symbol) external view returns (address) {
        return _oracles[symbol];
    }

    function createOracle(string memory symbol, address feed) external returns (address) {
        address oracle = address(new OracleChainlink(symbol, feed));
        _feeds[symbol] = feed;
        _oracles[symbol] = oracle;
        emit CreateOracleChainlink(symbol, feed, oracle);
        return _oracles[symbol];
    }

}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}