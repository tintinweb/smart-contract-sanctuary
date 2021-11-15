// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";

contract MockDPXChainlinkUSDAdapter is IOracle {
  function getPriceInUSD() external pure override returns (uint256 price) {
    return 100e8; // 100$
  }

  function viewPriceInUSD() external pure override returns (uint256 price) {
    return 100e8; // 100$
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

