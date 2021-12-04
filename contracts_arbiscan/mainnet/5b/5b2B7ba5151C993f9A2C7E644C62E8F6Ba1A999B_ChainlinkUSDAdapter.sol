// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
  event PriceUpdated(address asset, uint256 newPrice);

  function getPriceInUSD() external returns (uint256);

  function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IOracle} from '../interfaces/IOracle.sol';
import {IChainlinkV3Aggregator} from '../external/interfaces/IChainlinkV3Aggregator.sol';

contract ChainlinkUSDAdapter is IOracle {
    /// @notice the asset with the price oracle
    address public immutable asset;

    /// @notice chainlink aggregator with price in USD
    IChainlinkV3Aggregator public immutable aggregator;

    /// @dev the latestAnser returned
    uint256 private latestAnswer;

    constructor(address _asset, address _aggregator) {
        require(address(_aggregator) != address(0), 'invalid aggregator');

        asset = _asset;
        aggregator = IChainlinkV3Aggregator(_aggregator);
    }

    /// @dev adjusts the precision of a uint
    function adjustDecimal(
        uint256 balance,
        uint8 org,
        uint8 target
    ) internal pure returns (uint256 adjustedBalance) {
        adjustedBalance = balance;
        if (target < org) {
            adjustedBalance = adjustedBalance / (10**(org - target));
        } else if (target > org) {
            adjustedBalance = adjustedBalance * (10**(target - org));
        }
    }

    /// @dev returns price of asset in 1e8
    function getPriceInUSD() external override returns (uint256 price) {
        (, int256 priceC, , , ) = aggregator.latestRoundData();
        price = adjustDecimal(uint256(priceC), aggregator.decimals(), 8);
        latestAnswer = price;
        emit PriceUpdated(asset, price);
    }

    /// @dev returns the latest price of asset
    function viewPriceInUSD() external view override returns (uint256) {
        return latestAnswer;
    }
}