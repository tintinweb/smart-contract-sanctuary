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

/// @title AvaxUsdtOracleV1
/// @author 0xCalibur
/// @notice Oracle used for getting the price of 1 USDT in AVAX using Chainlink
contract AvaxUsdtOracleV1 is AggregatorV3Interface {
    AggregatorV3Interface public constant USDTUSD = AggregatorV3Interface(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);
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
        (,int256 usdtUsdFeed,,,) = USDTUSD.latestRoundData();
        (,int256 avaxUsdFeed,,,) = AVAXUSD.latestRoundData();

        return (0, (usdtUsdFeed * 1e18) / avaxUsdFeed, 0, 0, 0);
    }
}