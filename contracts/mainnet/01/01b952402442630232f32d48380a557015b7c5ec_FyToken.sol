/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./BalanceSheetInterface.sol";
import "./CarefulMath.sol";
import "./Erc20.sol";
import "./Erc20Interface.sol";
import "./Erc20Permit.sol";
import "./Erc20Recover.sol";
import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";
import "./ReentrancyGuard.sol";
import "./RedemptionPool.sol";
import "./UniswapAnchoredViewInterface.sol";

/**
 * @title FyToken
 * @author Mainframe
 */
contract FyToken is
    ReentrancyGuard, /* no depedency */
    FyTokenInterface, /* one dependency */
    Admin, /* two dependencies */
    Exponential, /* two dependencies */
    Erc20, /* three dependencies */
    Erc20Permit, /* five dependencies */
    Erc20Recover /* five dependencies */
{
    modifier isVaultOpen(address account) {
        require(balanceSheet.isVaultOpen(this, account), "ERR_VAULT_NOT_OPEN");
        _;
    }

    /**
     * @notice The fyToken always has 18 decimals.
     * @param name_ Erc20 name of this token.
     * @param symbol_ Erc20 symbol of this token.
     * @param expirationTime_ Unix timestamp in seconds for when this token expires.
     * @param fintroller_ The address of the Fintroller contract.
     * @param balanceSheet_ The address of the BalanceSheet contract.
     * @param underlying_ The contract address of the underlying asset.
     * @param collateral_ The contract address of the collateral asset.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 expirationTime_,
        FintrollerInterface fintroller_,
        BalanceSheetInterface balanceSheet_,
        Erc20Interface underlying_,
        Erc20Interface collateral_
    ) Erc20Permit(name_, symbol_, 18) Admin() {
        uint8 defaultNumberOfDecimals = 18;

        /* Set the underlying contract and calculate the decimal scalar offsets. */
        uint256 underlyingDecimals = underlying_.decimals();
        require(underlyingDecimals > 0, "ERR_FYTOKEN_CONSTRUCTOR_UNDERLYING_DECIMALS_ZERO");
        require(underlyingDecimals <= defaultNumberOfDecimals, "ERR_FYTOKEN_CONSTRUCTOR_UNDERLYING_DECIMALS_OVERFLOW");
        underlyingPrecisionScalar = 10**(defaultNumberOfDecimals - underlyingDecimals);
        underlying = underlying_;

        /* Set the collateral contract and calculate the decimal scalar offsets. */
        uint256 collateralDecimals = collateral_.decimals();
        require(collateralDecimals > 0, "ERR_FYTOKEN_CONSTRUCTOR_COLLATERAL_DECIMALS_ZERO");
        require(defaultNumberOfDecimals >= collateralDecimals, "ERR_FYTOKEN_CONSTRUCTOR_COLLATERAL_DECIMALS_OVERFLOW");
        collateralPrecisionScalar = 10**(defaultNumberOfDecimals - collateralDecimals);
        collateral = collateral_;

        /* Set the unix expiration time. */
        require(expirationTime_ > block.timestamp, "ERR_FYTOKEN_CONSTRUCTOR_EXPIRATION_TIME_NOT_VALID");
        expirationTime = expirationTime_;

        /* Set the Fintroller contract and sanity check it. */
        fintroller = fintroller_;
        fintroller.isFintroller();

        /* Set the Balance Sheet contract and sanity check it. */
        balanceSheet = balanceSheet_;
        balanceSheet.isBalanceSheet();

        /* Create the Redemption Pool contract and transfer the owner from the fyToken itself to the current caller. */
        redemptionPool = new RedemptionPool(fintroller_, this);
        AdminInterface(address(redemptionPool))._transferAdmin(msg.sender);
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    struct BorrowLocalVars {
        MathError mathErr;
        uint256 debt;
        uint256 debtCeiling;
        uint256 lockedCollateral;
        uint256 hypotheticalCollateralizationRatioMantissa;
        uint256 hypotheticalTotalSupply;
        uint256 newDebt;
        uint256 thresholdCollateralizationRatioMantissa;
    }

    /**
     * @notice Increases the debt of the caller and mints new fyToken.
     *
     * @dev Emits a {Borrow}, {Mint} and {Transfer} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - Must be called prior to maturation.
     * - The amount to borrow cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The locked collateral cannot be zero.
     * - The total supply of fyTokens cannot exceed the debt ceiling.
     * - The caller must not fall below the threshold collateralization ratio.
     *
     * @param borrowAmount The amount of fyTokens to borrow and print into existence.
     * @return bool true = success, otherwise it reverts.
     */
    function borrow(uint256 borrowAmount) public override isVaultOpen(msg.sender) nonReentrant returns (bool) {
        BorrowLocalVars memory vars;

        /* Checks: bond not matured. */
        require(isMatured() == false, "ERR_BOND_MATURED");

        /* Checks: the zero edge case. */
        require(borrowAmount > 0, "ERR_BORROW_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getBorrowAllowed(this), "ERR_BORROW_NOT_ALLOWED");

        /* Checks: debt ceiling. */
        (vars.mathErr, vars.hypotheticalTotalSupply) = addUInt(totalSupply, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_BORROW_MATH_ERROR");
        vars.debtCeiling = fintroller.getBondDebtCeiling(this);
        require(vars.hypotheticalTotalSupply <= vars.debtCeiling, "ERR_BORROW_DEBT_CEILING_OVERFLOW");

        /* Add the borrow amount to the account's current debt. */
        (vars.debt, , vars.lockedCollateral, ) = balanceSheet.getVault(this, msg.sender);
        require(vars.lockedCollateral > 0, "ERR_BORROW_LOCKED_COLLATERAL_ZERO");
        (vars.mathErr, vars.newDebt) = addUInt(vars.debt, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_BORROW_MATH_ERROR");

        /* Checks: the hypothetical collateralization ratio is above the threshold. */
        vars.hypotheticalCollateralizationRatioMantissa = balanceSheet.getHypotheticalCollateralizationRatio(
            this,
            msg.sender,
            vars.lockedCollateral,
            vars.newDebt
        );
        vars.thresholdCollateralizationRatioMantissa = fintroller.getBondCollateralizationRatio(this);
        require(
            vars.hypotheticalCollateralizationRatioMantissa >= vars.thresholdCollateralizationRatioMantissa,
            "ERR_BELOW_COLLATERALIZATION_RATIO"
        );

        /* Effects: print the new fyTokens into existence. */
        mintInternal(msg.sender, borrowAmount);

        /* Interactions: increase the debt of the account. */
        require(balanceSheet.setVaultDebt(this, msg.sender, vars.newDebt), "ERR_BORROW_CALL_SET_VAULT_DEBT");

        /* Emit a Borrow, Mint and Transfer event. */
        emit Borrow(msg.sender, borrowAmount);
        emit Transfer(address(this), msg.sender, borrowAmount);

        return true;
    }

    /**
     * @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
     *
     * @dev Emits a {Burn} event.
     *
     * Requirements:
     *
     * - Must be called prior to maturation.
     * - Can only be called by the Redemption Pool.
     * - The amount to burn cannot be zero.
     *
     * @param holder The account whose fyTokens to burn.
     * @param burnAmount The amount of fyTokens to burn.
     * @return bool true = success, otherwise it reverts.
     */
    function burn(address holder, uint256 burnAmount) external override nonReentrant returns (bool) {
        /* Checks: the caller is the Redemption Pool. */
        require(msg.sender == address(redemptionPool), "ERR_BURN_NOT_AUTHORIZED");

        /* Checks: the zero edge case. */
        require(burnAmount > 0, "ERR_BURN_ZERO");

        /* Effects: burns the fyTokens. */
        burnInternal(holder, burnAmount);

        return true;
    }

    struct LiquidateBorrowsLocalVars {
        MathError mathErr;
        uint256 collateralizationRatioMantissa;
        uint256 lockedCollateral;
        bool isAccountUnderwater;
    }

    /**
     * @notice Repays the debt of the borrower and rewards the liquidator with a surplus
     * of collateral.
     *
     * @dev Emits a {RepayBorrow}, {Transfer}, {ClutchCollateral} and {LiquidateBorrow} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The liquidator cannot liquidate themselves.
     * - The amount to repay cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The borrower must be underwater if the bond didn't mature.
     * - The caller must have at least `repayAmount` fyTokens.
     * - The borrower must have at least `repayAmount` debt.
     * - The collateral clutch cannot be more than what the borrower has in the vault.
     *
     * @param borrower The account to liquidate.
     * @param repayAmount The amount of fyTokens to repay.
     * @return true = success, otherwise it reverts.
     */
    function liquidateBorrow(address borrower, uint256 repayAmount)
        external
        override
        isVaultOpen(borrower)
        nonReentrant
        returns (bool)
    {
        LiquidateBorrowsLocalVars memory vars;

        /* Checks: borrowers cannot self liquidate. */
        require(msg.sender != borrower, "ERR_LIQUIDATE_BORROW_SELF");

        /* Checks: the zero edge case. */
        require(repayAmount > 0, "ERR_LIQUIDATE_BORROW_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getLiquidateBorrowAllowed(this), "ERR_LIQUIDATE_BORROW_NOT_ALLOWED");

        /* After maturation, any vault can be liquidated, irrespective of collateralization ratio. */
        if (isMatured() == false) {
            /* Checks: the borrower fell below the threshold collateraliation ratio. */
            vars.isAccountUnderwater = balanceSheet.isAccountUnderwater(this, borrower);
            require(vars.isAccountUnderwater, "ERR_ACCOUNT_NOT_UNDERWATER");
        }

        /* Effects & Interactions: repay the borrower's debt. */
        repayBorrowInternal(msg.sender, borrower, repayAmount);

        /* Interactions: clutch the collateral. */
        uint256 clutchableCollateralAmount = balanceSheet.getClutchableCollateral(this, repayAmount);
        require(
            balanceSheet.clutchCollateral(this, msg.sender, borrower, clutchableCollateralAmount),
            "ERR_LIQUIDATE_BORROW_CALL_CLUTCH_COLLATERAL"
        );

        emit LiquidateBorrow(msg.sender, borrower, repayAmount, clutchableCollateralAmount);

        return true;
    }

    /**
    /** @notice Prints new tokens into existence and assigns them to `beneficiary`,
     * increasing the total supply.
     *
     * @dev Emits a {Mint} event.
     *
     * Requirements:
     *
     * - Can only be called by the Redemption Pool.
     * - The amount to mint cannot be zero.
     *
     * @param beneficiary The account for which to mint the tokens.
     * @param mintAmount The amount of fyTokens to print into existence.
     * @return bool true = success, otherwise it reverts.
     */
    function mint(address beneficiary, uint256 mintAmount) external override nonReentrant returns (bool) {
        /* Checks: the caller is the Redemption Pool. */
        require(msg.sender == address(redemptionPool), "ERR_MINT_NOT_AUTHORIZED");

        /* Checks: the zero edge case. */
        require(mintAmount > 0, "ERR_MINT_ZERO");

        /* Effects: print the new fyTokens into existence. */
        mintInternal(beneficiary, mintAmount);

        return true;
    }

    /**
     * @notice Deletes the account's debt from the registry and take the fyTokens out of circulation.
     * @dev Emits a {Burn}, {Transfer} and {RepayBorrow} event.
     *
     * Requirements:
     *
     * - The vault must be open.
     * - The amount to repay cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The caller must have at least `repayAmount` fyTokens.
     * - The caller must have at least `repayAmount` debt.
     *
     * @param repayAmount Lorem ipsum.
     * @return true = success, otherwise it reverts.
     */
    function repayBorrow(uint256 repayAmount) external override isVaultOpen(msg.sender) nonReentrant returns (bool) {
        repayBorrowInternal(msg.sender, msg.sender, repayAmount);
        return true;
    }

    /**
     * @notice Clears the borrower's debt from the registry and take the fyTokens out of circulation.
     * @dev Emits a {Burn}, {Transfer} and {RepayBorrow} event.
     *
     * Requirements: same as the `repayBorrow` function, but here `borrower` is the account that must
     * have at least `repayAmount` fyTokens to repay the borrow.
     *
     * @param borrower The account for which to repay the borrow.
     * @param repayAmount The amount of fyTokens to repay.
     * @return true = success, otherwise it reverts.
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        override
        isVaultOpen(borrower)
        nonReentrant
        returns (bool)
    {
        repayBorrowInternal(msg.sender, borrower, repayAmount);
        return true;
    }

    /**
     * @notice Updates the Fintroller contract's address saved in storage.
     *
     * @dev Throws a {SetFintroller} event.
     *
     * Requirements:
     *
     * - The caller must be the administrator.
     *
     * @return bool true = success, otherwise it reverts.
     */
    function _setFintroller(FintrollerInterface newFintroller) external override onlyAdmin returns (bool) {
        /* Checks: sanity check the new contract. */
        newFintroller.isFintroller();

        /* Effects: update storage. */
        FintrollerInterface oldFintroller = fintroller;
        fintroller = newFintroller;

        emit SetFintroller(admin, oldFintroller, newFintroller);

        return true;
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev Checks if the bond matured.
     */
    function isMatured() internal view returns (bool) {
        return block.timestamp >= expirationTime;
    }

    /**
     * @dev See the documentation for the public functions that call this internal function.
     */
    function repayBorrowInternal(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal {
        /* Checks: the zero edge case. */
        require(repayAmount > 0, "ERR_REPAY_BORROW_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getRepayBorrowAllowed(this), "ERR_REPAY_BORROW_NOT_ALLOWED");

        /* Checks: borrower has a debt to pay. */
        uint256 debt = balanceSheet.getVaultDebt(this, borrower);
        require(debt >= repayAmount, "ERR_REPAY_BORROW_INSUFFICIENT_DEBT");

        /* Checks: the payer has enough fyTokens. */
        require(balanceOf(payer) >= repayAmount, "ERR_REPAY_BORROW_INSUFFICIENT_BALANCE");

        /* Effects: burn the fyTokens. */
        burnInternal(payer, repayAmount);

        /* Calculate the new debt of the borrower. */
        MathError mathErr;
        uint256 newDebt;
        (mathErr, newDebt) = subUInt(debt, repayAmount);
        /* This operation can't fail because of the previous `require`. */
        assert(mathErr == MathError.NO_ERROR);

        /* Interactions: reduce the debt of the borrower . */
        require(balanceSheet.setVaultDebt(this, borrower, newDebt), "ERR_REPAY_BORROW_CALL_SET_VAULT_DEBT");

        /* Emit both a Transfer and a RepayBorrow event. */
        emit Transfer(payer, address(this), repayAmount);
        emit RepayBorrow(payer, borrower, repayAmount, newDebt);
    }
}
