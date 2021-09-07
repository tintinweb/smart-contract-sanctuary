// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "./SafeErc20.sol";
import "./IBalanceSheetV1.sol";
import "./SBalanceSheetV1.sol";
import "./IHToken.sol";

import "./IHifiFlashUniswapV2.sol";
import "./IUniswapV2Pair.sol";

/// @notice Emitted when the caller is not the Uniswap V2 pair contract.
error HifiFlashUniswapV2__CallNotAuthorized(address caller);

/// @notice Emitted when the flash borrowed asset is the collateral instead of the underlying.
error HifiFlashUniswapV2__FlashBorrowCollateral(uint256 collateralAmount);

/// @notice Emitted when the liquidation does not yield a sufficient profit.
error HifiFlashUniswapV2__InsufficientProfit(
    uint256 seizedCollateralAmount,
    uint256 repayCollateralAmount,
    uint256 minProfit
);

/// @notice Emitted when neither the token0 nor the token1 is the underlying.
error HifiFlashUniswapV2__UnderlyingNotInPool(IUniswapV2Pair pair, address token0, address token1, IErc20 underlying);

/// @title HifiFlashUniswapV2
/// @author Hifi
contract HifiFlashUniswapV2 is IHifiFlashUniswapV2 {
    using SafeErc20 for IErc20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IHifiFlashUniswapV2
    IBalanceSheetV1 public override balanceSheet;

    /// @inheritdoc IHifiFlashUniswapV2
    mapping(address => IUniswapV2Pair) public override pairs;

    /// CONSTRUCTOR ///
    constructor(IBalanceSheetV1 balanceSheet_, address[] memory pairs_) {
        balanceSheet = IBalanceSheetV1(balanceSheet_);
        for (uint256 i = 0; i < pairs_.length; i++) {
            pairs[pairs_[i]] = IUniswapV2Pair(pairs_[i]);
        }
    }

    /// PUBLIC CONSTANT FUNCTIONS ////

    /// @inheritdoc IHifiFlashUniswapV2
    function getRepayCollateralAmount(
        IUniswapV2Pair pair,
        IErc20 underlying,
        uint256 underlyingAmount
    ) public view override returns (uint256 repayCollateralAmount) {
        // Depending upon which token is which, the reserves are returned in a different order.
        address token0 = pair.token0();
        uint112 collateralReserves;
        uint112 underlyingReserves;
        if (token0 == address(underlying)) {
            (underlyingReserves, collateralReserves, ) = pair.getReserves();
        } else {
            (collateralReserves, underlyingReserves, ) = pair.getReserves();
        }

        // Note that we can safely use unchecked arithmetic here because the UniswapV2Pair.sol contract performs
        // sanity checks on the amounts before calling the current contract.
        unchecked {
            uint256 numerator = collateralReserves * underlyingAmount * 1000;
            uint256 denominator = (underlyingReserves - underlyingAmount) * 997;
            repayCollateralAmount = numerator / denominator + 1;
        }
    }

    /// @inheritdoc IHifiFlashUniswapV2
    function getCollateralAndUnderlyingAmount(
        IUniswapV2Pair pair,
        uint256 amount0,
        uint256 amount1,
        IErc20 underlying
    ) public view override returns (IErc20 collateral, uint256 underlyingAmount) {
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (token0 == address(underlying)) {
            if (amount1 > 0) {
                revert HifiFlashUniswapV2__FlashBorrowCollateral(amount1);
            }
            collateral = IErc20(token1);
            underlyingAmount = amount0;
        } else if (token1 == address(underlying)) {
            if (amount0 > 0) {
                revert HifiFlashUniswapV2__FlashBorrowCollateral(amount0);
            }
            collateral = IErc20(token0);
            underlyingAmount = amount1;
        } else {
            revert HifiFlashUniswapV2__UnderlyingNotInPool(pair, token0, token1, underlying);
        }
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IUniswapV2Callee
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        if (msg.sender != address(pairs[msg.sender])) {
            revert HifiFlashUniswapV2__CallNotAuthorized(msg.sender);
        }

        // Unpack the ABI encoded data passed by the UniswapV2Pair contract.
        (address borrower, IHToken bond, uint256 minProfit) = abi.decode(data, (address, IHToken, uint256));

        // Figure out which token is the collateral and which token is the underlying.
        IErc20 underlying = bond.underlying();
        (IErc20 collateral, uint256 underlyingAmount) = getCollateralAndUnderlyingAmount(
            pairs[msg.sender],
            amount0,
            amount1,
            underlying
        );

        // Mint hTokens and liquidate the borrower.
        uint256 seizedCollateralAmount = mintAndLiquidateBorrow(borrower, bond, underlyingAmount, collateral);

        // Calculate the amount of collateral required to repay.
        uint256 repayCollateralAmount = getRepayCollateralAmount(pairs[msg.sender], underlying, underlyingAmount);
        if (seizedCollateralAmount <= repayCollateralAmount + minProfit) {
            revert HifiFlashUniswapV2__InsufficientProfit(seizedCollateralAmount, repayCollateralAmount, minProfit);
        }

        // Pay back the loan.
        collateral.safeTransfer(msg.sender, repayCollateralAmount);

        // Reap the profit.
        uint256 profitCollateralAmount = seizedCollateralAmount - repayCollateralAmount;
        collateral.safeTransfer(sender, profitCollateralAmount);

        // Emit an event.
        emit FlashLiquidateBorrow(
            sender,
            borrower,
            address(bond),
            underlyingAmount,
            seizedCollateralAmount,
            profitCollateralAmount
        );
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev Performs two operations:
    ///   1. Supplies the underlying to the HToken contract to mint hTokens without taking on debt.
    ///   2. Liquidates the borrower by transferring the underlying to the BalanceSheet. By doing this, the liquidator
    /// receives collateral at a discount.
    function mintAndLiquidateBorrow(
        address borrower,
        IHToken bond,
        uint256 underlyingAmount,
        IErc20 collateral
    ) internal returns (uint256 seizedCollateralAmount) {
        IErc20 underlying = bond.underlying();

        // Allow the HToken contract to spend USDC if allowance not enough.
        uint256 allowance = underlying.allowance(address(this), address(bond));
        if (allowance < underlyingAmount) {
            underlying.approve(address(bond), type(uint256).max);
        }

        // Mint hTokens.
        uint256 oldHTokenBalance = bond.balanceOf(address(this));
        bond.supplyUnderlying(underlyingAmount);
        uint256 newHTokenBalance = bond.balanceOf(address(this));
        uint256 mintedHTokenAmount;
        unchecked {
            mintedHTokenAmount = newHTokenBalance - oldHTokenBalance;
        }

        // Liquidate borrow with the newly minted hTokens.
        uint256 oldCollateralBalance = collateral.balanceOf(address(this));
        balanceSheet.liquidateBorrow(borrower, bond, mintedHTokenAmount, collateral);
        uint256 newCollateralBalance = collateral.balanceOf(address(this));
        unchecked {
            seizedCollateralAmount = newCollateralBalance - oldCollateralBalance;
        }
    }
}