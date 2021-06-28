// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./Initializable.sol";
import "./PRBMathUD60x18.sol";
import "./IErc20.sol";
import "./SafeErc20.sol";

import "./IBalanceSheetV1.sol";
import "./SBalanceSheetV1.sol";
import "./IFintrollerV1.sol";
import "./OwnableUpgradeable.sol";

/// @notice Emitted when the bond matured.
error BalanceSheet__BondMatured(IHToken bond);

/// @notice Emitted when the account exceeds the maximunm numbers of bonds permitted.
error BalanceSheet__BorrowMaxBonds(IHToken bond, uint256 hypotheticalBondListLength, uint256 maxBonds);

/// @notice Emitted when borrows are not allowed by the Fintroller contract.
error BalanceSheet__BorrowNotAllowed(IHToken bond);

/// @notice Emitted when borrowing a zero amount of hTokens.
error BalanceSheet__BorrowZero();

/// @notice Emitted when the hypothetical total supply of hTokens exceeds the debt ceiling.
error BalanceSheet__DebtCeilingOverflow(uint256 hypotheticalTotalSupply, uint256 debtCeiling);

/// @notice Emitted when collateral deposits are not allowed by the Fintroller contract.
error BalanceSheet__DepositCollateralNotAllowed(IErc20 collateral);

/// @notice Emitted when depositing a zero amount of collateral.
error BalanceSheet__DepositCollateralZero();

/// @notice Emitted when there is not enough collateral to seize.
error BalanceSheet__LiquidateBorrowInsufficientCollateral(
    address account,
    uint256 vaultCollateralAmount,
    uint256 seizableAmount
);

/// @notice Emitted when borrow liquidations are not allowed by the Fintroller contract.
error BalanceSheet__LiquidateBorrowNotAllowed(IHToken bond);

/// @notice Emitted when the borrower is liquidating themselves.
error BalanceSheet__LiquidateBorrowSelf(address account);

/// @notice Emitted when there is a liquidity shortfall.
error BalanceSheet__LiquidityShortfall(address account, uint256 shortfallLiquidity);

/// @notice Emitted when there is no liquidity shortfall.
error BalanceSheet__NoLiquidityShortfall(address account);

/// @notice Emitted when setting the oracle to the zero address.
error BalanceSheet__OracleZeroAddress();

/// @notice Emitted when the repayer does not have enough hTokens to repay the debt.
error BalanceSheet__RepayBorrowInsufficientBalance(IHToken bond, uint256 repayAmount, uint256 hTokenBalance);

/// @notice Emitted when repaying more debt than the borrower owes.
error BalanceSheet__RepayBorrowInsufficientDebt(IHToken bond, uint256 repayAmount, uint256 debtAmount);

/// @notice Emitted when borrow repays are not allowed by the Fintroller contract.
error BalanceSheet__RepayBorrowNotAllowed(IHToken bond);

/// @notice Emitted when repaying a borrow with a zero amount of hTokens.
error BalanceSheet__RepayBorrowZero();

/// @notice Emitted when withdrawing more collateral than there is in the vault.
error BalanceSheet__WithdrawCollateralUnderflow(address account, uint256 vaultCollateralAmount, uint256 withdrawAmount);

/// @notice Emitted when withdrawing a zero amount of collateral.
error BalanceSheet__WithdrawCollateralZero();

/// @title BalanceSheetV1
/// @author Hifi
/// @dev Due to the upgradeability pattern, we have to inherit from the storage contract last.
contract BalanceSheetV1 is
    Initializable, // no dependency
    OwnableUpgradeable, // two dependencies
    IBalanceSheetV1, // one dependency
    SBalanceSheetV1 // no dependency
{
    using PRBMathUD60x18 for uint256;
    using SafeErc20 for IErc20;

    /// INITIALIZER ///

    /// @notice The upgradeability variant of the contract constructor.
    /// @param fintroller_ The address of the Fintroller contract.
    /// @param oracle_ The address of the oracle contract.
    function initialize(IFintrollerV1 fintroller_, IChainlinkOperator oracle_) public initializer {
        // Initialize the owner.
        OwnableUpgradeable.__OwnableUpgradeable__init();

        // Set the Fintroller contract.
        fintroller = fintroller_;

        // Set the oracle contract.
        oracle = oracle_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IBalanceSheetV1
    function getBondList(address account) external view override returns (IHToken[] memory) {
        return vaults[account].bondList;
    }

    /// @inheritdoc IBalanceSheetV1
    function getCollateralAmount(address account, IErc20 collateral)
        external
        view
        override
        returns (uint256 collateralAmount)
    {
        return vaults[account].collateralAmounts[collateral];
    }

    /// @inheritdoc IBalanceSheetV1
    function getCollateralList(address account) external view override returns (IErc20[] memory) {
        return vaults[account].collateralList;
    }

    /// @inheritdoc IBalanceSheetV1
    function getSeizableCollateralAmount(
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) public view override returns (uint256 seizableCollateralAmount) {
        // When the liquidation incentive is zero, the end result would be zero anyways.
        uint256 liquidationIncentive = fintroller.getLiquidationIncentive(collateral);
        if (liquidationIncentive == 0) {
            return 0;
        }

        // Grab the normalized USD price of the collateral.
        uint256 normalizedCollateralPrice = oracle.getNormalizedPrice(collateral.symbol());

        // Grab the normalized USD price of the underlying.
        uint256 normalizedUnderlyingPrice = oracle.getNormalizedPrice(bond.underlying().symbol());

        // Calculate the top part of the equation.
        uint256 numerator = repayAmount.mul(liquidationIncentive.mul(normalizedUnderlyingPrice));

        // Calculate the normalized seizable collateral amount.
        uint256 normalizedSeizableCollateralAmount = numerator.div(normalizedCollateralPrice);

        // Denormalize the collateral amount.
        uint256 collateralPrecisionScalar = 10**(18 - collateral.decimals());
        if (collateralPrecisionScalar != 1) {
            unchecked {
                seizableCollateralAmount = normalizedSeizableCollateralAmount / collateralPrecisionScalar;
            }
        } else {
            seizableCollateralAmount = normalizedSeizableCollateralAmount;
        }
    }

    /// @inheritdoc IBalanceSheetV1
    function getCurrentAccountLiquidity(address account)
        public
        view
        override
        returns (uint256 excessLiquidity, uint256 shortfallLiquidity)
    {
        return getHypotheticalAccountLiquidity(account, IErc20(address(0)), 0, IHToken(address(0)), 0);
    }

    /// @inheritdoc IBalanceSheetV1
    function getDebtAmount(address account, IHToken bond) external view override returns (uint256 debtAmount) {
        return vaults[account].debtAmounts[bond];
    }

    struct HypotheticalAccountLiquidityLocalVars {
        uint256 bondListLength;
        uint256 collateralAmount;
        uint256 collateralListLength;
        uint256 collateralValueUsd;
        uint256 collateralizationRatio;
        uint256 debtAmount;
        uint256 debtValueUsd;
        uint256 normalizedCollateralAmount;
        uint256 normalizedCollateralPrice;
        uint256 precisionScalar;
        uint256 totalDebtValueUsd;
        uint256 totalWeightedCollateralValueUsd;
        uint256 normalizedUnderlyingPrice;
        uint256 weightedCollateralValueUsd;
    }

    /// @inheritdoc IBalanceSheetV1
    function getHypotheticalAccountLiquidity(
        address account,
        IErc20 collateralModify,
        uint256 collateralAmountModify,
        IHToken bondModify,
        uint256 debtAmountModify
    ) public view override returns (uint256 excessLiquidity, uint256 shortfallLiquidity) {
        HypotheticalAccountLiquidityLocalVars memory vars;

        // Load into memory for faster iteration.
        IErc20[] memory collateralList = vaults[account].collateralList;
        vars.collateralListLength = collateralList.length;

        // Sum up each collateral USD value divided by the collateralization ratio.
        for (uint256 i = 0; i < vars.collateralListLength; i++) {
            IErc20 collateral = collateralList[i];

            if (collateralModify != collateral) {
                vars.collateralAmount = vaults[account].collateralAmounts[collateral];
            } else {
                vars.collateralAmount = collateralAmountModify;
            }

            // Normalize the collateral amount.
            vars.precisionScalar = 10**(18 - collateral.decimals());
            if (vars.precisionScalar != 1) {
                vars.normalizedCollateralAmount = vars.collateralAmount * vars.precisionScalar;
            } else {
                vars.normalizedCollateralAmount = vars.collateralAmount;
            }

            // Grab the normalized USD price of the collateral.
            vars.normalizedCollateralPrice = oracle.getNormalizedPrice(collateral.symbol());

            // Calculate the USD value of the collateral amount;
            vars.collateralValueUsd = vars.normalizedCollateralAmount.mul(vars.normalizedCollateralPrice);

            // Calculate the USD value of the weighted collateral by dividing the USD value of the collateral amount
            // by the collateralization ratio.
            vars.collateralizationRatio = fintroller.getCollateralizationRatio(collateral);
            vars.weightedCollateralValueUsd = vars.collateralValueUsd.div(vars.collateralizationRatio);

            // Add the previously calculated USD value of the weighted collateral to the totals.
            vars.totalWeightedCollateralValueUsd += vars.weightedCollateralValueUsd;
        }

        // Load into memory for faster iteration.
        IHToken[] memory bondList = vaults[account].bondList;
        vars.bondListLength = bondList.length;

        // Sum up all debts.
        for (uint256 i = 0; i < vars.bondListLength; i++) {
            IHToken bond = bondList[i];

            if (bondModify != bond) {
                vars.debtAmount = vaults[account].debtAmounts[bond];
            } else {
                vars.debtAmount = debtAmountModify;
            }

            // Grab the normalized USD price of the underlying.
            vars.normalizedUnderlyingPrice = oracle.getNormalizedPrice(bond.underlying().symbol());

            // Calculate the USD value of the collateral amount;
            vars.debtValueUsd = vars.debtAmount.mul(vars.normalizedUnderlyingPrice);

            // Add the previously calculated USD value to the totals.
            vars.totalDebtValueUsd += vars.debtValueUsd;
        }

        // Excess liquidity when there is more weighted collateral than debt, and shortfall liquidity when there is
        // less weighted collateral than debt.
        unchecked {
            if (vars.totalWeightedCollateralValueUsd > vars.totalDebtValueUsd) {
                excessLiquidity = vars.totalWeightedCollateralValueUsd - vars.totalDebtValueUsd;
            } else {
                shortfallLiquidity = vars.totalDebtValueUsd - vars.totalWeightedCollateralValueUsd;
            }
        }
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    // @inheritdoc IHToken
    function borrow(IHToken bond, uint256 borrowAmount) public override {
        // Checks: the Fintroller allows this action to be performed.
        if (!fintroller.getBorrowAllowed(bond)) {
            revert BalanceSheet__BorrowNotAllowed(bond);
        }

        // Checks: bond not matured.
        if (bond.isMatured()) {
            revert BalanceSheet__BondMatured(bond);
        }

        // Checks: the zero edge case.
        if (borrowAmount == 0) {
            revert BalanceSheet__BorrowZero();
        }

        // Checks: debt ceiling.
        uint256 hypotheticalTotalSupply = bond.totalSupply() + borrowAmount;
        uint256 debtCeiling = fintroller.getDebtCeiling(bond);
        if (hypotheticalTotalSupply > debtCeiling) {
            revert BalanceSheet__DebtCeilingOverflow(hypotheticalTotalSupply, debtCeiling);
        }

        // Add the borrow amount to the borrower account's current debt.
        uint256 newDebtAmount = vaults[msg.sender].debtAmounts[bond] + borrowAmount;

        // Effects: add the bond to the redundant list if it hasn't been added already.
        if (vaults[msg.sender].debtAmounts[bond] == 0) {
            // Checks: below max bonds limit.
            unchecked {
                uint256 hypotheticalBondListLength = vaults[msg.sender].bondList.length + 1;
                uint256 maxBonds = SFintrollerV1(address(fintroller)).maxBonds();
                if (hypotheticalBondListLength > maxBonds) {
                    revert BalanceSheet__BorrowMaxBonds(bond, hypotheticalBondListLength, maxBonds);
                }
            }
            vaults[msg.sender].bondList.push(bond);
        }

        // Checks: there is no liquidity shortfall.
        (, uint256 hypotheticalShortfallLiquidity) = getHypotheticalAccountLiquidity(
            msg.sender,
            IErc20(address(0)),
            0,
            bond,
            newDebtAmount
        );
        if (hypotheticalShortfallLiquidity > 0) {
            revert BalanceSheet__LiquidityShortfall(msg.sender, hypotheticalShortfallLiquidity);
        }

        // Effects: increase the amount of debt in the vault.
        vaults[msg.sender].debtAmounts[bond] = newDebtAmount;

        // Interactions: print the new hTokens into existence.
        bond.mint(msg.sender, borrowAmount);

        // Emit a Borrow event.
        emit Borrow(msg.sender, bond, borrowAmount);
    }

    /// @inheritdoc IBalanceSheetV1
    function depositCollateral(IErc20 collateral, uint256 depositAmount) external override {
        // Checks: the Fintroller allows this action to be performed.
        if (!fintroller.getDepositCollateralAllowed(collateral)) {
            revert BalanceSheet__DepositCollateralNotAllowed(collateral);
        }

        // Checks: the zero edge case.
        if (depositAmount == 0) {
            revert BalanceSheet__DepositCollateralZero();
        }

        // Effects: add the collateral to the redundant list, if this is the first time collateral is added.
        if (vaults[msg.sender].collateralAmounts[collateral] == 0) {
            vaults[msg.sender].collateralList.push(collateral);
        }

        // Effects: increase the amount of collateral in the vault.
        vaults[msg.sender].collateralAmounts[collateral] += depositAmount;

        // Interactions: perform the Erc20 transfer.
        collateral.safeTransferFrom(msg.sender, address(this), depositAmount);

        // Emit a DepositCollateral event.
        emit DepositCollateral(msg.sender, collateral, depositAmount);
    }

    /// @inheritdoc IBalanceSheetV1
    function liquidateBorrow(
        address borrower,
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) external override {
        // Checks: caller not the borrower.
        if (msg.sender == borrower) {
            revert BalanceSheet__LiquidateBorrowSelf(borrower);
        }

        // Checks: the Fintroller allows this action to be performed.
        if (!fintroller.getLiquidateBorrowAllowed(bond)) {
            revert BalanceSheet__LiquidateBorrowNotAllowed(bond);
        }

        // After maturation, any vault can be liquidated, irrespective of account liquidity.
        if (bond.isMatured() == false) {
            // Checks: the borrower has a shortfall of liquidity.
            (, uint256 shortfallLiquidity) = getCurrentAccountLiquidity(borrower);
            if (shortfallLiquidity == 0) {
                revert BalanceSheet__NoLiquidityShortfall(borrower);
            }
        }

        // Checks: there is enough collateral in the vault.
        uint256 vaultCollateralAmount = vaults[borrower].collateralAmounts[collateral];
        uint256 seizableCollateralAmount = getSeizableCollateralAmount(bond, repayAmount, collateral);
        if (vaultCollateralAmount < seizableCollateralAmount) {
            revert BalanceSheet__LiquidateBorrowInsufficientCollateral(
                borrower,
                vaultCollateralAmount,
                seizableCollateralAmount
            );
        }

        // Effects & Interactions: repay the borrower's debt.
        repayBorrowInternal(msg.sender, borrower, bond, repayAmount);

        // Calculate the new collateral amount.
        uint256 newCollateralAmount;
        unchecked {
            newCollateralAmount = vaults[borrower].collateralAmounts[collateral] - seizableCollateralAmount;
        }

        // Effects: decrease the amount of collateral in the vault.
        vaults[borrower].collateralAmounts[collateral] = newCollateralAmount;

        // Effects: delete the collateral from the redundant list, if the resultant amount of collateral is zero.
        if (newCollateralAmount == 0) {
            removeCollateralFromList(borrower, collateral);
        }

        // Interactions: seize the collateral.
        collateral.safeTransfer(msg.sender, seizableCollateralAmount);

        // Emit a LiquidateBorrow event.
        emit LiquidateBorrow(msg.sender, borrower, bond, repayAmount, collateral, seizableCollateralAmount);
    }

    /// @inheritdoc IBalanceSheetV1
    function repayBorrow(IHToken bond, uint256 repayAmount) external override {
        repayBorrowInternal(msg.sender, msg.sender, bond, repayAmount);
    }

    /// @inheritdoc IBalanceSheetV1
    function repayBorrowBehalf(
        address borrower,
        IHToken bond,
        uint256 repayAmount
    ) external override {
        repayBorrowInternal(msg.sender, borrower, bond, repayAmount);
    }

    /// @inheritdoc IBalanceSheetV1
    function setOracle(IChainlinkOperator newOracle) external override onlyOwner {
        if (address(newOracle) == address(0)) {
            revert BalanceSheet__OracleZeroAddress();
        }
        address oldOracle = address(oracle);
        oracle = newOracle;
        emit SetOracle(owner, oldOracle, address(newOracle));
    }

    /// @inheritdoc IBalanceSheetV1
    function withdrawCollateral(IErc20 collateral, uint256 withdrawAmount) external override {
        // Checks: the zero edge case.
        if (withdrawAmount == 0) {
            revert BalanceSheet__WithdrawCollateralZero();
        }

        // Checks: there is enough collateral in teh vault.
        uint256 vaultCollateralAmount = vaults[msg.sender].collateralAmounts[collateral];
        if (vaultCollateralAmount < withdrawAmount) {
            revert BalanceSheet__WithdrawCollateralUnderflow(msg.sender, vaultCollateralAmount, withdrawAmount);
        }

        // Calculate the new collateral amount.
        uint256 newCollateralAmount;
        unchecked {
            newCollateralAmount = vaultCollateralAmount - withdrawAmount;
        }

        // Checks: the hypothetical account liquidity is okay.
        if (vaults[msg.sender].bondList.length > 0) {
            (, uint256 hypotheticalShortfallLiquidity) = getHypotheticalAccountLiquidity(
                msg.sender,
                collateral,
                newCollateralAmount,
                IHToken(address(0)),
                0
            );
            if (hypotheticalShortfallLiquidity > 0) {
                revert BalanceSheet__LiquidityShortfall(msg.sender, hypotheticalShortfallLiquidity);
            }
        }

        // Effects: decrease the amount of collateral in the vault.
        vaults[msg.sender].collateralAmounts[collateral] = newCollateralAmount;

        // Effects: delete the collateral from the redundant list, if the resultant amount of collateral is zero.
        if (newCollateralAmount == 0) {
            removeCollateralFromList(msg.sender, collateral);
        }

        // Interactions: perform the Erc20 transfer.
        collateral.safeTransfer(msg.sender, withdrawAmount);

        // Emit a WithdrawCollateral event.
        emit WithdrawCollateral(msg.sender, collateral, withdrawAmount);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev Removes the bond from the redundant bond list.
    function removeBondFromList(address account, IHToken bond) internal {
        // Load into memory for faster iteration.
        IHToken[] memory memoryBondList = vaults[account].bondList;
        uint256 length = memoryBondList.length;

        // Find the index where the bond is stored at.
        uint256 bondIndex = length;
        for (uint256 i = 0; i < length; i++) {
            if (memoryBondList[i] == bond) {
                bondIndex = i;
                break;
            }
        }

        // We must have found the bond in the list or the redundant data structure is broken.
        assert(bondIndex < length);

        // Copy last item in list to location of item to be removed, reduce length by 1.
        IHToken[] storage storedBondList = vaults[account].bondList;
        storedBondList[bondIndex] = storedBondList[length - 1];
        storedBondList.pop();
    }

    /// @dev Removes the collateral from the redundant collateral list.
    function removeCollateralFromList(address account, IErc20 collateral) internal {
        // Load into memory for faster iteration.
        IErc20[] memory memoryCollateralList = vaults[account].collateralList;
        uint256 length = memoryCollateralList.length;

        // Find the index where the collateral is stored at.
        uint256 collateralIndex = length;
        for (uint256 i = 0; i < length; i++) {
            if (memoryCollateralList[i] == collateral) {
                collateralIndex = i;
                break;
            }
        }

        // We must have found the collateral in the list or the redundant data structure is broken.
        assert(collateralIndex < length);

        // Copy last item in list to location of item to be removed, reduce length by 1.
        IErc20[] storage storedCollateralList = vaults[account].collateralList;
        storedCollateralList[collateralIndex] = storedCollateralList[length - 1];
        storedCollateralList.pop();
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function repayBorrowInternal(
        address payer,
        address borrower,
        IHToken bond,
        uint256 repayAmount
    ) internal {
        // Checks: the Fintroller allows this action to be performed.
        if (!fintroller.getRepayBorrowAllowed(bond)) {
            revert BalanceSheet__RepayBorrowNotAllowed(bond);
        }

        // Checks: the zero edge case.
        if (repayAmount == 0) {
            revert BalanceSheet__RepayBorrowZero();
        }

        // Checks: borrower has debt.
        uint256 debtAmount = vaults[borrower].debtAmounts[bond];
        if (debtAmount < repayAmount) {
            revert BalanceSheet__RepayBorrowInsufficientDebt(bond, repayAmount, debtAmount);
        }

        // Checks: the payer has enough hTokens.
        uint256 hTokenBalance = bond.balanceOf(payer);
        if (hTokenBalance < repayAmount) {
            revert BalanceSheet__RepayBorrowInsufficientBalance(bond, repayAmount, hTokenBalance);
        }

        // Effects: decrease the amount of debt in the vault.
        uint256 newDebtAmount;
        unchecked {
            newDebtAmount = vaults[borrower].debtAmounts[bond] - repayAmount;
            vaults[borrower].debtAmounts[bond] = newDebtAmount;
        }

        // Effects: delete the bond from the redundant list, if the resultant amount of debt is zero.
        if (newDebtAmount == 0) {
            removeBondFromList(borrower, bond);
        }

        // Interactions: burn the hTokens.
        bond.burn(payer, repayAmount);

        // Emit a RepayBorrow event.
        emit RepayBorrow(borrower, payer, bond, repayAmount, newDebtAmount);
    }
}