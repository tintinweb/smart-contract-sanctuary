/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";

/**
 * @title RedemptionPoolStorage
 * @author Mainframe
 */
abstract contract RedemptionPoolStorage {
    /**
     * @notice The unique Fintroller associated with this contract.
     */
    FintrollerInterface public fintroller;

    /**
     * @notice The amount of the underyling asset available to be redeemed after maturation.
     */
    uint256 public totalUnderlyingSupply;

    /**
     * The unique fyToken associated with this Redemption Pool.
     */
    FyTokenInterface public fyToken;

    /**
     * @notice Indicator that this is a Redemption Pool contract, for inspection.
     */
    bool public constant isRedemptionPool = true;
}
