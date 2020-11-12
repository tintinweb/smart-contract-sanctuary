/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./BalanceSheetInterface.sol";
import "./Erc20Interface.sol";
import "./Exponential.sol";
import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";
import "./OraclePriceUtils.sol";
import "./ReentrancyGuard.sol";
import "./SafeErc20.sol";
import "./UniswapAnchoredViewInterface.sol";

/**
 * @title BalanceSheet
 * @author Mainframe
 */
contract BalanceSheet is
    ReentrancyGuard, /* no depedency */
    BalanceSheetInterface, /* one dependency */
    Admin, /* two dependencies */
    Exponential /* two dependencies */
{
    using OraclePriceUtils for UniswapAnchoredViewInterface;
    using SafeErc20 for Erc20Interface;

    modifier isVaultOpenForMsgSender(FyTokenInterface fyToken) {
        require(vaults[address(fyToken)][msg.sender].isOpen, "ERR_VAULT_NOT_OPEN");
        _;
    }

    /**
     * @param fintroller_ The address of the Fintroller contract.
     */
    constructor(FintrollerInterface fintroller_) Admin() {
        /* Set the fyToken contract and sanity check it. */
        fintroller = fintroller_;
        fintroller.isFintroller();
    }

    /**
     * CONSTANT FUNCTIONS
     */

    struct CalculateClutchableCollateralLocalVars {
        MathError mathErr;
        Exp clutchableCollateralAmountUpscaled;
        uint256 clutchableCollateralAmount;
        uint256 collateralPrecisionScalar;
        uint256 collateralPriceUpscaled;
        uint256 liquidationIncentiveMantissa;
        Exp numerator;
        uint256 oraclePricePrecisionScalar;
        uint256 underlyingPriceUpscaled;
    }

    /**
     * @notice Determines the amount of collateral that can be clutched when liquidating a borrow.
     *
     * @dev The formula applied is:
     * clutchedCollateral = repayAmount * liquidationIncentive * underlyingPriceUsd / priceCollateralUsd
     *
     * Requirements:
     *
     * - `repayAmount` must be non-zero.
     *
     * @param fyToken The fyToken to make the query against.
     * @param repayAmount The amount of fyTokens to repay.
     * @return The amount of clutchable collateral as uint256, specified in the collateral's decimal system.
     */
    function getClutchableCollateral(FyTokenInterface fyToken, uint256 repayAmount)
        external
        view
        override
        returns (uint256)
    {
        CalculateClutchableCollateralLocalVars memory vars;

        /* Avoid the zero edge cases. */
        require(repayAmount > 0, "ERR_GET_CLUTCHABLE_COLLATERAL_ZERO");

        /* When the liquidation incentive is zero, the end result would be zero anyways. */
        vars.liquidationIncentiveMantissa = fintroller.liquidationIncentiveMantissa();
        if (vars.liquidationIncentiveMantissa == 0) {
            return 0;
        }

        /* Grab the upscaled USD price of the underlying. */
        UniswapAnchoredViewInterface oracle = fintroller.oracle();
        vars.oraclePricePrecisionScalar = fintroller.oraclePricePrecisionScalar();
        (vars.mathErr, vars.underlyingPriceUpscaled) = oracle.getAdjustedPrice(
            fyToken.underlying().symbol(),
            vars.oraclePricePrecisionScalar
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_CLUTCHABLE_COLLATERAL_MATH_ERROR");

        /* Grab the upscaled USD price of the collateral. */
        (vars.mathErr, vars.collateralPriceUpscaled) = oracle.getAdjustedPrice(
            fyToken.collateral().symbol(),
            vars.oraclePricePrecisionScalar
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_CLUTCHABLE_COLLATERAL_MATH_ERROR");

        /* Calculate the top part of the equation. */
        (vars.mathErr, vars.numerator) = mulExp3(
            Exp({ mantissa: repayAmount }),
            Exp({ mantissa: vars.liquidationIncentiveMantissa }),
            Exp({ mantissa: vars.underlyingPriceUpscaled })
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_CLUTCHABLE_COLLATERAL_MATH_ERROR");

        /* Calculate the mantissa form of the clutched collateral amount. */
        (vars.mathErr, vars.clutchableCollateralAmountUpscaled) = divExp(
            vars.numerator,
            Exp({ mantissa: vars.collateralPriceUpscaled })
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_CLUTCHABLE_COLLATERAL_MATH_ERROR");

        /* If the precision scalar is not 1, calculate the final form of the clutched collateral amount. */
        vars.collateralPrecisionScalar = fyToken.collateralPrecisionScalar();
        if (vars.collateralPrecisionScalar != 1) {
            (vars.mathErr, vars.clutchableCollateralAmount) = divUInt(
                vars.clutchableCollateralAmountUpscaled.mantissa,
                vars.collateralPrecisionScalar
            );
            require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_CLUTCHABLE_COLLATERAL_MATH_ERROR");
        } else {
            vars.clutchableCollateralAmount = vars.clutchableCollateralAmountUpscaled.mantissa;
        }

        return vars.clutchableCollateralAmount;
    }

    /**
     * @notice Determines the current collateralization ratio for the given account;
     * @param fyToken The fyToken to make the query against.
     * @param account The account to make the query against.
     * @return A quotient if locked collateral is non-zero, otherwise zero.
     */
    function getCurrentCollateralizationRatio(FyTokenInterface fyToken, address account)
        public
        view
        override
        returns (uint256)
    {
        Vault memory vault = vaults[address(fyToken)][account];
        return getHypotheticalCollateralizationRatio(fyToken, account, vault.lockedCollateral, vault.debt);
    }

    struct GetHypotheticalAccountLiquidityLocalVars {
        MathError mathErr;
        uint256 collateralPriceUpscaled;
        uint256 collateralPrecisionScalar;
        uint256 collateralizationRatioMantissa;
        Exp debtValueUsd;
        Exp hypotheticalCollateralizationRatio;
        Exp lockedCollateralValueUsd;
        uint256 lockedCollateralUpscaled;
        uint256 oraclePricePrecisionScalar;
        uint256 underlyingPriceUpscaled;
        uint256 underlyingPrecisionScalar;
    }

    /**
     * @notice Determines the hypothetical account collateralization ratio for the given locked
     * collateral and debt, at the current prices provided by the oracle.
     *
     * @dev The formula applied is: collateralizationRatio = lockedCollateralValueUsd / debtValueUsd
     *
     * Requirements:
     *
     * - The vault must be open.
     * - `debt` must be non-zero.
     * - The oracle prices must be non-zero.
     *
     * @param fyToken The fyToken for which to make the query against.
     * @param account The account for which to make the query against.
     * @param lockedCollateral The hypothetical locked collateral.
     * @param debt The hypothetical debt.
     * @return The hypothetical collateralization ratio as a percentage mantissa if locked
     * collateral is non-zero, otherwise zero.
     */
    function getHypotheticalCollateralizationRatio(
        FyTokenInterface fyToken,
        address account,
        uint256 lockedCollateral,
        uint256 debt
    ) public view override returns (uint256) {
        GetHypotheticalAccountLiquidityLocalVars memory vars;

        /* If the vault is not open, a hypothetical collateralization ratio cannot be calculated. */
        require(vaults[address(fyToken)][account].isOpen, "ERR_VAULT_NOT_OPEN");

        /* Avoid the zero edge cases. */
        if (lockedCollateral == 0) {
            return 0;
        }
        require(debt > 0, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_DEBT_ZERO");

        /* Grab the upscaled USD price of the collateral. */
        UniswapAnchoredViewInterface oracle = fintroller.oracle();
        vars.oraclePricePrecisionScalar = fintroller.oraclePricePrecisionScalar();
        (vars.mathErr, vars.collateralPriceUpscaled) = oracle.getAdjustedPrice(
            fyToken.collateral().symbol(),
            vars.oraclePricePrecisionScalar
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");

        /* Grab the upscaled USD price of the underlying. */
        (vars.mathErr, vars.underlyingPriceUpscaled) = oracle.getAdjustedPrice(
            fyToken.underlying().symbol(),
            vars.oraclePricePrecisionScalar
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");

        /* Upscale the collateral, which can have any precision, to mantissa precision. */
        vars.collateralPrecisionScalar = fyToken.collateralPrecisionScalar();
        if (vars.collateralPrecisionScalar != 1) {
            (vars.mathErr, vars.lockedCollateralUpscaled) = mulUInt(lockedCollateral, vars.collateralPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");
        } else {
            vars.lockedCollateralUpscaled = lockedCollateral;
        }

        /* Calculate the USD value of the collateral. */
        (vars.mathErr, vars.lockedCollateralValueUsd) = mulExp(
            Exp({ mantissa: vars.lockedCollateralUpscaled }),
            Exp({ mantissa: vars.collateralPriceUpscaled })
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");

        /* Calculate the USD value of the debt. */
        (vars.mathErr, vars.debtValueUsd) = mulExp(
            Exp({ mantissa: debt }),
            Exp({ mantissa: vars.underlyingPriceUpscaled })
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");

        /**
         * Calculate the collateralization ratio by dividing the USD value of the hypothetical locked collateral by
         * the USD value of the debt.
         */
        (vars.mathErr, vars.hypotheticalCollateralizationRatio) = divExp(
            vars.lockedCollateralValueUsd,
            vars.debtValueUsd
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_GET_HYPOTHETICAL_COLLATERALIZATION_RATIO_MATH_ERROR");

        return vars.hypotheticalCollateralizationRatio.mantissa;
    }

    /**
     * @notice Reads all the properties of a vault.
     * @return (uint256 debt, uint256 freeCollateral, uint256 lockedCollateral, bool isOpen).
     */
    function getVault(FyTokenInterface fyToken, address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            vaults[address(fyToken)][account].debt,
            vaults[address(fyToken)][account].freeCollateral,
            vaults[address(fyToken)][account].lockedCollateral,
            vaults[address(fyToken)][account].isOpen
        );
    }

    /**
     * @notice Reads the debt held by the given account.
     */
    function getVaultDebt(FyTokenInterface fyToken, address account) external view override returns (uint256) {
        return vaults[address(fyToken)][account].debt;
    }

    /**
     * @notice Reads the collateral that the given account locked in the vault.
     */
    function getVaultLockedCollateral(FyTokenInterface fyToken, address account)
        external
        view
        override
        returns (uint256)
    {
        return vaults[address(fyToken)][account].lockedCollateral;
    }

    /**
     * @notice Checks whether the account can be liquidated or not.
     * @param fyToken The fyToken for which to make the query against.
     * @param account The account for which to make the query against.
     * @return true = is underwater, otherwise not.
     */
    function isAccountUnderwater(FyTokenInterface fyToken, address account) external view override returns (bool) {
        Vault memory vault = vaults[address(fyToken)][account];
        if (!vault.isOpen || vault.debt == 0) {
            return false;
        }
        uint256 currentCollateralizationRatioMantissa = getCurrentCollateralizationRatio(fyToken, account);
        uint256 thresholdCollateralizationRatioMantissa = fintroller.getBondCollateralizationRatio(fyToken);
        return currentCollateralizationRatioMantissa < thresholdCollateralizationRatioMantissa;
    }

    /**
     * @notice Checks whether the account has a vault opened for a particular fyToken.
     */
    function isVaultOpen(FyTokenInterface fyToken, address account) external view override returns (bool) {
        return vaults[address(fyToken)][account].isOpen;
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    /**
     * @notice Transfers the collateral from the borrower's vault to the liquidator account.
     *
     * @dev Emits a {ClutchCollateral} event.
     *
     * Requirements:
     *
     * - Can only be called by the fyToken.
     * - There must be enough collateral in the borrower's vault.
     *
     * @param fyToken The address of the fyToken contract.
     * @param liquidator The account who repaid the borrower's debt and the receiver of the collateral.
     * @param borrower The account who fell underwater and is liquidated.
     * @param collateralAmount The amount of collateral to clutch, specified in the collateral's decimal system.
     * @return true = success, otherwise it reverts.
     */
    function clutchCollateral(
        FyTokenInterface fyToken,
        address liquidator,
        address borrower,
        uint256 collateralAmount
    ) external override nonReentrant returns (bool) {
        /* Checks: the caller is the fyToken. */
        require(msg.sender == address(fyToken), "ERR_CLUTCH_COLLATERAL_NOT_AUTHORIZED");

        /* Checks: there is enough clutchable collateral in the vault. */
        uint256 lockedCollateral = vaults[address(fyToken)][borrower].lockedCollateral;
        require(lockedCollateral >= collateralAmount, "ERR_INSUFFICIENT_LOCKED_COLLATERAL");

        /* Calculate the new locked collateral amount. */
        MathError mathErr;
        uint256 newLockedCollateral;
        (mathErr, newLockedCollateral) = subUInt(lockedCollateral, collateralAmount);
        assert(mathErr == MathError.NO_ERROR);

        /* Effects: update the vault. */
        vaults[address(fyToken)][borrower].lockedCollateral = newLockedCollateral;

        /* Interactions: transfer the collateral. */
        fyToken.collateral().safeTransfer(liquidator, collateralAmount);

        emit ClutchCollateral(fyToken, liquidator, borrower, collateralAmount);

        return true;
    }

    /**
     * @notice Deposits collateral into the account's vault.
     *
     * @dev Emits a {DepositCollateral} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The amount to deposit cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The caller must have allowed this contract to spend `collateralAmount` tokens.
     *
     * @param fyToken The address of the fyToken contract.
     * @param collateralAmount The amount of collateral to withdraw.
     * @return true = success, otherwise it reverts.
     */
    function depositCollateral(FyTokenInterface fyToken, uint256 collateralAmount)
        external
        override
        isVaultOpenForMsgSender(fyToken)
        nonReentrant
        returns (bool)
    {
        /* Checks: the zero edge case. */
        require(collateralAmount > 0, "ERR_DEPOSIT_COLLATERAL_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getDepositCollateralAllowed(fyToken), "ERR_DEPOSIT_COLLATERAL_NOT_ALLOWED");

        /* Effects: update storage. */
        MathError mathErr;
        uint256 hypotheticalFreeCollateral;
        (mathErr, hypotheticalFreeCollateral) = addUInt(
            vaults[address(fyToken)][msg.sender].freeCollateral,
            collateralAmount
        );
        require(mathErr == MathError.NO_ERROR, "ERR_DEPOSIT_COLLATERAL_MATH_ERROR");
        vaults[address(fyToken)][msg.sender].freeCollateral = hypotheticalFreeCollateral;

        /* Interactions: perform the Erc20 transfer. */
        fyToken.collateral().safeTransferFrom(msg.sender, address(this), collateralAmount);

        emit DepositCollateral(fyToken, msg.sender, collateralAmount);

        return true;
    }

    struct FreeCollateralLocalVars {
        MathError mathErr;
        uint256 collateralizationRatioMantissa;
        uint256 hypotheticalCollateralizationRatioMantissa;
        uint256 newFreeCollateral;
        uint256 newLockedCollateral;
    }

    /**
     * @notice Frees a portion or all of the locked collateral.
     * @dev Emits a {FreeCollateral} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The amount to free cannot be zero.
     * - There must be enough locked collateral.
     * - The account cannot fall below the collateralization ratio.
     *
     * @param fyToken The address of the fyToken contract.
     * @param collateralAmount The amount of free collateral to lock.
     * @return bool true = success, otherwise it reverts.
     */
    function freeCollateral(FyTokenInterface fyToken, uint256 collateralAmount)
        external
        override
        isVaultOpenForMsgSender(fyToken)
        returns (bool)
    {
        FreeCollateralLocalVars memory vars;

        /* Checks: the zero edge case. */
        require(collateralAmount > 0, "ERR_FREE_COLLATERAL_ZERO");

        /* Checks: enough locked collateral. */
        Vault memory vault = vaults[address(fyToken)][msg.sender];
        require(vault.lockedCollateral >= collateralAmount, "ERR_INSUFFICIENT_LOCKED_COLLATERAL");

        /* This operation can't fail because of the first `require` in this function. */
        (vars.mathErr, vars.newLockedCollateral) = subUInt(vault.lockedCollateral, collateralAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Checks: the hypothetical collateralization ratio is above the threshold. */
        if (vault.debt > 0) {
            vars.hypotheticalCollateralizationRatioMantissa = getHypotheticalCollateralizationRatio(
                fyToken,
                msg.sender,
                vars.newLockedCollateral,
                vault.debt
            );
            vars.collateralizationRatioMantissa = fintroller.getBondCollateralizationRatio(fyToken);
            require(
                vars.hypotheticalCollateralizationRatioMantissa >= vars.collateralizationRatioMantissa,
                "ERR_BELOW_COLLATERALIZATION_RATIO"
            );
        }

        /* Effects: update storage. */
        vaults[address(fyToken)][msg.sender].lockedCollateral = vars.newLockedCollateral;
        (vars.mathErr, vars.newFreeCollateral) = addUInt(vault.freeCollateral, collateralAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_FREE_COLLATERAL_MATH_ERROR");
        vaults[address(fyToken)][msg.sender].freeCollateral = vars.newFreeCollateral;

        emit FreeCollateral(fyToken, msg.sender, collateralAmount);

        return true;
    }

    /**
     * @notice Locks a portion or all of the free collateral to make it eligible for borrowing.
     * @dev Emits a {LockCollateral} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The amount to lock cannot be zero.
     * - There must be enough free collateral.
     *
     * @param fyToken The address of the fyToken contract.
     * @param collateralAmount The amount of free collateral to lock.
     * @return bool true = success, otherwise it reverts.
     */
    function lockCollateral(FyTokenInterface fyToken, uint256 collateralAmount)
        external
        override
        isVaultOpenForMsgSender(fyToken)
        returns (bool)
    {
        /* Avoid the zero edge case. */
        require(collateralAmount > 0, "ERR_LOCK_COLLATERAL_ZERO");

        Vault memory vault = vaults[address(fyToken)][msg.sender];
        require(vault.freeCollateral >= collateralAmount, "ERR_INSUFFICIENT_FREE_COLLATERAL");

        MathError mathErr;
        uint256 newLockedCollateral;
        (mathErr, newLockedCollateral) = addUInt(vault.lockedCollateral, collateralAmount);
        require(mathErr == MathError.NO_ERROR, "ERR_LOCK_COLLATERAL_MATH_ERROR");
        vaults[address(fyToken)][msg.sender].lockedCollateral = newLockedCollateral;

        /* This operation can't fail because of the first `require` in this function. */
        uint256 hypotheticalFreeCollateral;
        (mathErr, hypotheticalFreeCollateral) = subUInt(vault.freeCollateral, collateralAmount);
        assert(mathErr == MathError.NO_ERROR);
        vaults[address(fyToken)][msg.sender].freeCollateral = hypotheticalFreeCollateral;

        emit LockCollateral(fyToken, msg.sender, collateralAmount);

        return true;
    }

    /**
     * @notice Opens a Vault for the caller.
     * @dev Emits an {OpenVault} event.
     *
     * Requirements:
     *
     * - The vault cannot be already open.
     *
     * @param fyToken The address of the fyToken contract for which to open the vault.
     * @return true = success, otherwise it reverts.
     */
    function openVault(FyTokenInterface fyToken) external override returns (bool) {
        fyToken.isFyToken();
        require(vaults[address(fyToken)][msg.sender].isOpen == false, "ERR_VAULT_OPEN");
        vaults[address(fyToken)][msg.sender].isOpen = true;
        emit OpenVault(fyToken, msg.sender);
        return true;
    }

    /**
     * @notice Updates the debt accrued by a particular account.
     *
     * @dev Emits a {SetVaultDebt} event.
     *
     * Requirements:
     *
     * - Can only be called by the fyToken.
     *
     * @param fyToken The address of the fyToken contract.
     * @param account The account for which to update the debt.
     * @return bool=true success, otherwise it reverts.
     */
    function setVaultDebt(
        FyTokenInterface fyToken,
        address account,
        uint256 newVaultDebt
    ) external override returns (bool) {
        /* Checks: the caller is the fyToken. */
        require(msg.sender == address(fyToken), "ERR_SET_VAULT_DEBT_NOT_AUTHORIZED");

        /* Effects: update storage. */
        uint256 oldVaultDebt = vaults[address(fyToken)][account].debt;
        vaults[address(fyToken)][account].debt = newVaultDebt;

        emit SetVaultDebt(fyToken, account, oldVaultDebt, newVaultDebt);

        return true;
    }

    /**
     * @notice Withdraws a portion or all of the free collateral.
     *
     * @dev Emits a {WithdrawCollateral} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The amount to withdraw cannot be zero.
     * - There must be enough free collateral in the vault.
     *
     * @param fyToken The address of the fyToken contract.
     * @param collateralAmount The amount of collateral to withdraw.
     * @return true = success, otherwise it reverts.
     */
    function withdrawCollateral(FyTokenInterface fyToken, uint256 collateralAmount)
        external
        override
        isVaultOpenForMsgSender(fyToken)
        nonReentrant
        returns (bool)
    {
        /* Checks: the zero edge case. */
        require(collateralAmount > 0, "ERR_WITHDRAW_COLLATERAL_ZERO");

        /* Checks: there is enough free collateral. */
        require(
            vaults[address(fyToken)][msg.sender].freeCollateral >= collateralAmount,
            "ERR_INSUFFICIENT_FREE_COLLATERAL"
        );

        /* Effects: update storage. */
        MathError mathErr;
        uint256 newFreeCollateral;
        (mathErr, newFreeCollateral) = subUInt(vaults[address(fyToken)][msg.sender].freeCollateral, collateralAmount);
        /* This operation can't fail because of the first `require` in this function. */
        assert(mathErr == MathError.NO_ERROR);
        vaults[address(fyToken)][msg.sender].freeCollateral = newFreeCollateral;

        /* Interactions: perform the Erc20 transfer. */
        fyToken.collateral().safeTransfer(msg.sender, collateralAmount);

        emit WithdrawCollateral(fyToken, msg.sender, collateralAmount);

        return true;
    }
}
