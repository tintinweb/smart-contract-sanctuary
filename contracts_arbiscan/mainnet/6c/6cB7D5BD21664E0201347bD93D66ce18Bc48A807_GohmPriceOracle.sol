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

// Interfaces
import {IChainlinkV3Aggregator} from '../external/interfaces/IChainlinkV3Aggregator.sol';

contract GohmPriceOracle {
    /*==== PUBLIC VARS ====*/

    address public constant OHMv2_CHAINLINK_AGGREGATOR =
        0x761aaeBf021F19F198D325D7979965D0c7C9e53b;

    address public constant OHM_INDEX_CHAINLINK_AGGREGATOR =
        0x48C4721354A3B29D80EF03C65E6644A37338a0B1;

    /*==== VIEWS ====*/

    /// @notice Gets the price of gOHM in USD
    /// @return price of gOHM in USD in 1e8 precision
    function getPriceInUSD() external view returns (uint256) {
        return (getOHMv2PriceInUSD() * getOHMIndex()) / 1e9;
    }

    /// @notice Gets the price of OHM (v2) in USD
    /// @return the price of OHM (v2) in USD in 1e8 precision
    function getOHMv2PriceInUSD() public view returns (uint256) {
        (, int256 price, , , ) = IChainlinkV3Aggregator(
            OHMv2_CHAINLINK_AGGREGATOR
        ).latestRoundData();

        return uint256(price);
    }

    /// @notice Gets the current index of OHM
    /// @return the current index of OHM in 1e9 precision
    function getOHMIndex() public view returns (uint256) {
        (, int256 index, , , ) = IChainlinkV3Aggregator(
            OHM_INDEX_CHAINLINK_AGGREGATOR
        ).latestRoundData();

        return uint256(index);
    }
}