// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IOracle.sol";
import "../../interfaces/IChainlinkV3Aggregator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title ChainlinkUSDAdapter
/// @author @ace-contributor
/// @notice oracle that return price in USD 1e8
////////////////////////////////////////////////////////////////////////////////////////////

contract ChainlinkUSDAdapter is IOracle {

    /// @notice the asset with the price oracle
    address public immutable asset;

    /// @notice chainlink aggregator with price in USD
    IChainlinkV3Aggregator public immutable aggregator;

    /// @dev the latestAnser returned
    uint256 private latestAnswer;

    constructor(
        address _asset,
        address _aggregator
    ) {
        require(address(_aggregator) != address(0), "invalid aggregator");

        asset = _asset;
        aggregator = IChainlinkV3Aggregator(_aggregator);
    }

    /// @dev returns price of asset in 1e8
    function getPriceInUSD() external override returns (uint256 price) {
        (, int256 priceC, , , ) = aggregator.latestRoundData();
        price = uint256(priceC);
        latestAnswer = price;
        emit PriceUpdated(asset, price);
    }

    /// @dev returns the latest price of asset
    function viewPriceInUSD() external view override returns (uint256) {
        return latestAnswer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    function getPriceInUSD() external returns (uint256);

    function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkV3Aggregator {
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

