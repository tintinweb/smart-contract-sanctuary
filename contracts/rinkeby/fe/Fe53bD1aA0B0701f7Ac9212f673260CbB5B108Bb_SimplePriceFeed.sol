// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IAggregatorV3.sol";

/// @title SimplePriceFeed
/// @author Hifi
contract SimplePriceFeed is IAggregatorV3 {
    string internal internalDescription;
    int256 internal price;

    constructor(string memory description_) {
        internalDescription = description_;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external view override returns (string memory) {
        return internalDescription;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 roundId_)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (roundId_, price, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, 0, 0, 0);
    }

    function setPrice(int256 newPrice) external {
        price = newPrice;
    }
}