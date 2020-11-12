// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import {
  SafeMath as SafeMath256
} from './SafeMath.sol';


/**
 * @notice Library helpers for converting asset quantities between asset units and pips
 */
library AssetUnitConversions {
  using SafeMath256 for uint256;

  function pipsToAssetUnits(uint64 quantityInPips, uint8 assetDecimals)
    internal
    pure
    returns (uint256)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      return uint256(quantityInPips).mul(uint256(10)**(assetDecimals - 8));
    }
    return uint256(quantityInPips).div(uint256(10)**(8 - assetDecimals));
  }

  function assetUnitsToPips(uint256 quantityInAssetUnits, uint8 assetDecimals)
    internal
    pure
    returns (uint64)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    uint256 quantityInPips;
    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      quantityInPips = quantityInAssetUnits.div(
        uint256(10)**(assetDecimals - 8)
      );
    } else {
      quantityInPips = quantityInAssetUnits.mul(
        uint256(10)**(8 - assetDecimals)
      );
    }
    require(quantityInPips < 2**64, 'Pip quantity overflows uint64');

    return uint64(quantityInPips);
  }
}
