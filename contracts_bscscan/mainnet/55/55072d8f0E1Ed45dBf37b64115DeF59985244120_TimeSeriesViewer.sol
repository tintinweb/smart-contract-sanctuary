/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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

// File: contracts/utils/TimeSeriesViewer.sol

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title TimeSeriesViewer
 */

contract TimeSeriesViewer {
    constructor() {
        //
    }

    /**
     * @notice View historical prices for Chainlink feed
     * @param aggregator: aggregator price address
     * @param firstRoundId: first roundId from Chainlink
     * @param lastRoundId: last roundId from Chainlink
     */
    function viewHistoricalPrices(
        address aggregator,
        uint80 firstRoundId,
        uint80 lastRoundId
    )
        external
        view
        returns (
            uint80[] memory roundIds,
            int256[] memory prices,
            uint256[] memory timestamps
        )
    {
        uint256 numberRounds = lastRoundId - firstRoundId;

        roundIds = new uint80[](numberRounds);
        timestamps = new uint256[](numberRounds);
        prices = new int256[](numberRounds);

        for (uint80 i = firstRoundId; i < lastRoundId; i++) {
            (roundIds[i], prices[i], , timestamps[i], ) = AggregatorV3Interface(aggregator).getRoundData(i);
        }
    }
}