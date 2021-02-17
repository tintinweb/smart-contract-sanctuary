/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./CarefulMath.sol";
import "./Erc20Interface.sol";
import "./Erc20Recover.sol";
import "./SafeErc20.sol";
import "./ReentrancyGuard.sol";

import "./FintrollerInterface.sol";
import "./RedemptionPoolInterface.sol";

/**
 * @title RedemptionPool
 * @author Hifi
 * @notice Mints 1 fyToken in exhchange for 1 underlying before maturation and burns 1 fyToken
 * in exchange for 1 underlying after maturation.
 * @dev Instantiated by the fyToken in its constructor.
 */
contract RedemptionPool is
    CarefulMath, /* no dependency */
    ReentrancyGuard, /* no dependency */
    RedemptionPoolInterface, /* one dependency */
    Admin, /* two dependencies */
    Erc20Recover /* five dependencies */
{
    using SafeErc20 for Erc20Interface;

    /**
     * @param fintroller_ The address of the Fintroller contract.
     * @param fyToken_ The address of the fyToken contract.
     */
    constructor(FintrollerInterface fintroller_, FyTokenInterface fyToken_) Admin() {
        /* Set the Fintroller contract and sanity check it. */
        fintroller = fintroller_;
        fintroller.isFintroller();

        /**
         * Set the fyToken contract. It cannot be sanity-checked because the fyToken creates this
         * contract in its own constructor and contracts cannot be called while initializing.
         */
        fyToken = fyToken_;
    }

    struct RedeemFyTokensLocalVars {
        MathError mathErr;
        uint256 newUnderlyingTotalSupply;
        uint256 underlyingPrecisionScalar;
        uint256 underlyingAmount;
    }

    /**
     * @notice Pays the token holder the face value at maturation time.
     *
     * @dev Emits a {RedeemFyTokens} event.
     *
     * Requirements:
     *
     * - Must be called after maturation.
     * - The amount to redeem cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - There must be enough liquidity in the Redemption Pool.
     *
     * @param fyTokenAmount The amount of fyTokens to redeem for the underlying asset.
     * @return bool true = success, otherwise it reverts.
     */
    function redeemFyTokens(uint256 fyTokenAmount) external override nonReentrant returns (bool) {
        RedeemFyTokensLocalVars memory vars;

        /* Checks: maturation time. */
        require(block.timestamp >= fyToken.expirationTime(), "ERR_BOND_NOT_MATURED");

        /* Checks: the zero edge case. */
        require(fyTokenAmount > 0, "ERR_REDEEM_FYTOKENS_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getRedeemFyTokensAllowed(fyToken), "ERR_REDEEM_FYTOKENS_NOT_ALLOWED");

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be downscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.underlyingAmount) = divUInt(fyTokenAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_REDEEM_FYTOKENS_MATH_ERROR");
        } else {
            vars.underlyingAmount = fyTokenAmount;
        }

        /* Checks: there is enough liquidity. */
        require(vars.underlyingAmount <= totalUnderlyingSupply, "ERR_REDEEM_FYTOKENS_INSUFFICIENT_UNDERLYING");

        /* Effects: decrease the remaining supply of underlying. */
        (vars.mathErr, vars.newUnderlyingTotalSupply) = subUInt(totalUnderlyingSupply, vars.underlyingAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        totalUnderlyingSupply = vars.newUnderlyingTotalSupply;

        /* Interactions: burn the fyTokens. */
        require(fyToken.burn(msg.sender, fyTokenAmount), "ERR_SUPPLY_UNDERLYING_CALL_BURN");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransfer(msg.sender, vars.underlyingAmount);

        emit RedeemFyTokens(msg.sender, fyTokenAmount, vars.underlyingAmount);

        return true;
    }

    struct SupplyUnderlyingLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newUnderlyingTotalSupply;
        uint256 underlyingPrecisionScalar;
    }

    /**
     * @notice An alternative to the usual minting method that does not involve taking on debt.
     *
     * @dev Emits a {SupplyUnderlying} event.
     *
     * Requirements:
     *
     * - Must be called prior to maturation.
     * - The amount to supply cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The caller must have allowed this contract to spend `underlyingAmount` tokens.
     *
     * @param underlyingAmount The amount of underlying to supply to the Redemption Pool.
     * @return bool true = success, otherwise it reverts.
     */
    function supplyUnderlying(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        SupplyUnderlyingLocalVars memory vars;

        /* Checks: maturation time. */
        require(block.timestamp < fyToken.expirationTime(), "ERR_BOND_MATURED");

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "ERR_SUPPLY_UNDERLYING_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getSupplyUnderlyingAllowed(fyToken), "ERR_SUPPLY_UNDERLYING_NOT_ALLOWED");

        /* Effects: update storage. */
        (vars.mathErr, vars.newUnderlyingTotalSupply) = addUInt(totalUnderlyingSupply, underlyingAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_MATH_ERROR");
        totalUnderlyingSupply = vars.newUnderlyingTotalSupply;

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Interactions: mint the fyTokens. */
        require(fyToken.mint(msg.sender, vars.fyTokenAmount), "ERR_SUPPLY_UNDERLYING_CALL_MINT");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransferFrom(msg.sender, address(this), underlyingAmount);

        emit SupplyUnderlying(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }
}