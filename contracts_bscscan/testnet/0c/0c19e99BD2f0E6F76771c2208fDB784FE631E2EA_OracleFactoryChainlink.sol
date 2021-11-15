// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OracleChainlink {

    address public immutable feed;
    uint256 public immutable decimals;

    constructor (address feed_) {
        feed = feed_;
        decimals = IChainlinkFeed(feed_).decimals();
    }

    function getPrice() external view returns (uint256) {
        (, int256 price, , , ) = IChainlinkFeed(feed).latestRoundData();
        return uint256(price) * 10**(18 - decimals);
    }

}

contract OracleFactoryChainlink {

    event CreateOracleChainlink(address feed, address oracle);

    // feed => oracle
    mapping (address => address) _oracles;

    function getOracle(address feed) external view returns (address) {
        return _oracles[feed];
    }

    function createOracle(address feed) external returns (address) {
        if (_oracles[feed] == address(0)) {
            address oracle = address(new OracleChainlink(feed));
            _oracles[feed] = oracle;
            emit CreateOracleChainlink(feed, oracle);
        }
        return _oracles[feed];
    }

}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

