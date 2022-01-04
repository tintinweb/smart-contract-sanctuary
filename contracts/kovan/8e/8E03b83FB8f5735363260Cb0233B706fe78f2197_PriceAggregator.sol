// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./chainlink/AggregatorV3Interface.sol";

contract PriceAggregator {
    AggregatorV3Interface internal aggregatorV3;

    constructor(address _aggregatorV3) {
        aggregatorV3 = AggregatorV3Interface(_aggregatorV3);
    }

    /**
     * Returns the latest price
     */
    // solhint-disable no-unused-vars
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = aggregatorV3.latestRoundData();

        return price;
    }
    // solhint-enable no-unused-vars
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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