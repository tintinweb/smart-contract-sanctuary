// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title MimAvaxOracleV1
/// @author 0xCalibur
/// @notice Oracle used for getting the price of 1 MIM in AVAX using Chainlink
contract MimAvaxOracleV1 is AggregatorV3Interface {
    AggregatorV3Interface public constant MIMUSD = AggregatorV3Interface(0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
    AggregatorV3Interface public constant AVAXUSD = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
    
    function decimals() external override pure returns (uint8) {
        return 18;
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
        (,int256 mimUsdFeed,,,) = MIMUSD.latestRoundData();
        (,int256 avaxUsdFeed,,,) = AVAXUSD.latestRoundData();

        return (0, (mimUsdFeed * 1e18) / avaxUsdFeed, 0, 0, 0);
    }
}