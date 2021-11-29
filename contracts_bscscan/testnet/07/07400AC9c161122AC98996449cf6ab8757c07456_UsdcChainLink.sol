// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

    function decimals()
    external
    view
    returns (
        uint8
    );

    function description()
    external
    view
    returns (
        string memory
    );

    function version()
    external
    view
    returns (
        uint256
    );

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlink {

    function getLatestPrice() external view returns (int);

    function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/AggregatorV3Interface.sol";
import "../interface/IChainlink.sol";

contract UsdcChainLink is IChainlink{

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x90c069C4538adAc136E051052E14c1cD799C41B7);
    }

    /**
    * Returns the latest price
    */
    function getLatestPrice() public override view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public override view returns (uint8) {
        return priceFeed.decimals();
    }
}