/* SPDX-License-Identifier: LPGL-3.0-or-later */
pragma solidity ^0.7.0;

/**
 * @title ExponentialStorage
 * @author Paul Razvan Berg
 * @notice The storage interface ancillary to an Exponential contract.
 */
abstract contract ExponentialStorage {
    struct Exp {
        uint256 mantissa;
    }

    /**
     * @dev In Exponential denomination, 1e18 is 1.
     */
    uint256 internal constant expScale = 1e18;
    uint256 internal constant halfExpScale = expScale / 2;
    uint256 internal constant mantissaOne = expScale;
}
