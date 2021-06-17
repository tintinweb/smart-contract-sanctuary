/// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;
import "./IErc20.sol";
import "./SafeErc20.sol";

import "./IRegentsTargetV1.sol";
import "./ExchangeProxyInterface.sol";
import "./TokenInterface.sol";
import "./WethInterface.sol";

/// @title RegentsTargetV1
/// @author Hifi
/// @notice Target contract with scripts for the Regents release of the protocol.
/// @dev Meant to be used with a DSProxy contract via delegatecall.
contract RegentsTargetV1 is IRegentsTargetV1 {
    using SafeErc20 for IErc20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IRegentsTargetV1
    address public constant override EXCHANGE_PROXY_ADDRESS = 0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21;

    /// @inheritdoc IRegentsTargetV1
    address public constant override WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IRegentsTargetV1
    function borrow(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 borrowAmount
    ) public override {
        balanceSheet.borrow(hToken, borrowAmount);
        hToken.transfer(msg.sender, borrowAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function borrowAndSellHTokens(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) public payable override {
        IErc20 underlying = hToken.underlying();

        // Borrow the hTokens.
        balanceSheet.borrow(hToken, borrowAmount);

        // Allow the Balancer contract to spend hTokens if allowance not enough.
        uint256 allowance = hToken.allowance(address(this), EXCHANGE_PROXY_ADDRESS);
        if (allowance < borrowAmount) {
            hToken.approve(EXCHANGE_PROXY_ADDRESS, type(uint256).max);
        }

        // Prepare the parameters for calling Balancer.
        TokenInterface tokenIn = TokenInterface(address(hToken));
        TokenInterface tokenOut = TokenInterface(address(underlying));
        uint256 totalAmountOut = underlyingAmount;
        uint256 maxTotalAmountIn = borrowAmount;
        uint256 nPools = 1;

        // Recall that Balancer reverts when the swap is not successful.
        uint256 totalAmountIn =
            ExchangeProxyInterface(EXCHANGE_PROXY_ADDRESS).smartSwapExactOut(
                tokenIn,
                tokenOut,
                totalAmountOut,
                maxTotalAmountIn,
                nPools
            );

        // When we get a better price than the worst that we assumed we would, not all hTokens are sold.
        uint256 hTokenDelta = borrowAmount - totalAmountIn;

        // If the hToken delta is non-zero, we use it to partially repay the borrow.
        // Note: this is not gas-efficient.
        if (hTokenDelta > 0) {
            balanceSheet.repayBorrow(hToken, hTokenDelta);
        }

        // Finally, transfer the recently bought underlying to the end user.
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit BorrowAndSellHTokens(msg.sender, borrowAmount, hTokenDelta, underlyingAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function depositCollateral(
        IBalanceSheetV1 balanceSheet,
        IErc20 collateral,
        uint256 collateralAmount
    ) public override {
        // Transfer the collateral to the DSProxy.
        collateral.safeTransferFrom(msg.sender, address(this), collateralAmount);

        // Deposit the collateral into the BalanceSheet contract.
        depositCollateralInternal(balanceSheet, collateral, collateralAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function depositAndBorrow(
        IBalanceSheetV1 balanceSheet,
        IErc20 collateral,
        IHToken hToken,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) public payable override {
        depositCollateral(balanceSheet, collateral, collateralAmount);
        borrow(balanceSheet, hToken, borrowAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function depositAndBorrowAndSellHTokens(
        IBalanceSheetV1 balanceSheet,
        IErc20 collateral,
        IHToken hToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) external payable override {
        depositCollateral(balanceSheet, collateral, collateralAmount);
        borrowAndSellHTokens(balanceSheet, hToken, borrowAmount, underlyingAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function redeem(IHToken hToken, uint256 hTokenAmount) public override {
        IErc20 underlying = hToken.underlying();

        // Transfer the hTokens to the DSProxy.
        hToken.transferFrom(msg.sender, address(this), hTokenAmount);

        // Redeem the hTokens.
        uint256 preUnderlyingBalance = underlying.balanceOf(address(this));
        hToken.redeem(hTokenAmount);

        // Calculate how many underlying have been redeemed.
        uint256 postUnderlyigBalance = underlying.balanceOf(address(this));
        uint256 underlyingAmount = postUnderlyigBalance - preUnderlyingBalance;

        // The underlying is now in the DSProxy, so we relay it to the end user.
        underlying.safeTransfer(msg.sender, underlyingAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function repayBorrow(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 repayAmount
    ) public override {
        // Transfer the hTokens to the DSProxy.
        hToken.transferFrom(msg.sender, address(this), repayAmount);

        // Repay the borrow.
        balanceSheet.repayBorrow(hToken, repayAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function sellUnderlyingAndRepayBorrow(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 underlyingAmount,
        uint256 repayAmount
    ) external override {
        IErc20 underlying = hToken.underlying();

        // Transfer the underlying to the DSProxy.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Allow the Balancer contract to spend underlying if allowance not enough.
        uint256 allowance = underlying.allowance(address(this), EXCHANGE_PROXY_ADDRESS);
        if (allowance < underlyingAmount) {
            underlying.approve(EXCHANGE_PROXY_ADDRESS, type(uint256).max);
        }

        // Prepare the parameters for calling Balancer.
        TokenInterface tokenIn = TokenInterface(address(underlying));
        TokenInterface tokenOut = TokenInterface(address(hToken));
        uint256 totalAmountOut = repayAmount;
        uint256 maxTotalAmountIn = underlyingAmount;
        uint256 nPools = 1;

        // Recall that Balancer reverts when the swap is not successful.
        uint256 totalAmountIn =
            ExchangeProxyInterface(EXCHANGE_PROXY_ADDRESS).smartSwapExactOut(
                tokenIn,
                tokenOut,
                totalAmountOut,
                maxTotalAmountIn,
                nPools
            );

        // Use the recently bought hTokens to repay the borrow.
        balanceSheet.repayBorrow(hToken, repayAmount);

        // When we get a better price than the worst that we assumed we would, not all underlying is sold.
        uint256 underlyingDelta = underlyingAmount - totalAmountIn;

        // If the underlying delta is non-zero, send it back to the user.
        if (underlyingDelta > 0) {
            underlying.safeTransfer(msg.sender, underlyingDelta);
        }
    }

    /// @inheritdoc IRegentsTargetV1
    function supplyUnderlying(IHToken hToken, uint256 underlyingAmount) public override {
        uint256 preHTokenBalance = hToken.balanceOf(address(this));
        supplyUnderlyingInternal(hToken, underlyingAmount);

        //Calculate how many hTokens have been minted.
        uint256 postHTokenBalance = hToken.balanceOf(address(this));
        uint256 hTokenAmount = postHTokenBalance - preHTokenBalance;

        // The hTokens are now in the DSProxy, so we relay them to the end user.
        hToken.transfer(msg.sender, hTokenAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function supplyUnderlyingAndRepayBorrow(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 underlyingAmount
    ) external override {
        uint256 preHTokenBalance = hToken.balanceOf(address(this));
        supplyUnderlyingInternal(hToken, underlyingAmount);

        // Calculate how many hTokens have been minted.
        uint256 postHTokenBalance = hToken.balanceOf(address(this));
        uint256 hTokenAmount = postHTokenBalance - preHTokenBalance;

        // Use the newly minted hTokens to repay the debt.
        balanceSheet.repayBorrow(hToken, hTokenAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function withdrawCollateral(
        IBalanceSheetV1 balanceSheet,
        IErc20 collateral,
        uint256 withdrawAmount
    ) public override {
        ///IErc20 collateral, uint256 withdrawAmount
        balanceSheet.withdrawCollateral(collateral, withdrawAmount);

        // The collateral is now in the DSProxy, so we relay it to the end user.
        collateral.safeTransfer(msg.sender, withdrawAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function wrapEthAndDepositCollateral(IBalanceSheetV1 balanceSheet, IHToken hToken) public payable override {
        uint256 collateralAmount = msg.value;

        // Convert the received ETH to WETH.
        WethInterface(WETH_ADDRESS).deposit{ value: collateralAmount }();

        // Deposit the collateral into the BalanceSheet contract.
        depositCollateralInternal(balanceSheet, hToken, collateralAmount);
    }

    /// @inheritdoc IRegentsTargetV1
    function wrapEthAndDepositAndBorrowAndSellHTokens(
        IBalanceSheetV1 balanceSheet,
        IHToken hToken,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) external payable override {
        wrapEthAndDepositCollateral(balanceSheet, hToken);

        borrowAndSellHTokens(balanceSheet, hToken, borrowAmount, underlyingAmount);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function depositCollateralInternal(
        IBalanceSheetV1 balanceSheet,
        IErc20 collateral,
        uint256 collateralAmount
    ) internal {
        // Allow the BalanceSheet contract to spend tokens if allowance not enough.
        uint256 allowance = collateral.allowance(address(this), address(balanceSheet));
        if (allowance < collateralAmount) {
            collateral.approve(address(balanceSheet), type(uint256).max);
        }

        // Deposit the collateral into the BalanceSheet contract.
        balanceSheet.depositCollateral(collateral, collateralAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function supplyUnderlyingInternal(IHToken hToken, uint256 underlyingAmount) internal {
        //IRedemptionPool redemptionPool = hToken.redemptionPool();
        IErc20 underlying = hToken.underlying();

        // Transfer the underlying to the DSProxy.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Allow the RedemptionPool contract to spend tokens if allowance not enough.
        uint256 allowance = underlying.allowance(address(this), address(hToken));
        if (allowance < underlyingAmount) {
            underlying.approve(address(hToken), type(uint256).max);
        }

        // Supply the underlying and mint hTokens.
        hToken.supplyUnderlying(underlyingAmount);
    }
}