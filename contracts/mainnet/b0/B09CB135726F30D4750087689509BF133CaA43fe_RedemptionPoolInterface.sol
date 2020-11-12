/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./RedemptionPoolStorage.sol";

/**
 * @title RedemptionPoolInterface
 * @author Mainframe
 */
abstract contract RedemptionPoolInterface is RedemptionPoolStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function redeemFyTokens(uint256 underlyingAmount) external virtual returns (bool);

    function supplyUnderlying(uint256 underlyingAmount) external virtual returns (bool);

    /**
     * EVENTS
     */
    event RedeemFyTokens(address indexed account, uint256 fyTokenAmount, uint256 underlyingAmount);

    event SupplyUnderlying(address indexed account, uint256 underlyingAmount, uint256 fyTokenAmount);
}
