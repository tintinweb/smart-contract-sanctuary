/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./Erc20Interface.sol";
import "./SafeErc20.sol";

import "./BatterseaTargetV1Interface.sol";
import "./BalanceSheetInterface.sol";
import "./FyTokenInterface.sol";
import "./RedemptionPoolInterface.sol";
import "./ExchangeProxyInterface.sol";
import "./TokenInterface.sol";
import "./WethInterface.sol";

/**
 * @title BatterseaTargetV1
 * @author Hifi
 * @notice Target contract with scripts for the Battersea release of the protocol.
 * @dev Meant to be used with a DSProxy contract via delegatecall.
 */
contract BatterseaTargetV1 is
    CarefulMath, /* no dependency */
    BatterseaTargetV1Interface /* one dependency */
{
    using SafeErc20 for Erc20Interface;
    using SafeErc20 for FyTokenInterface;

    /**
     * @notice Borrows fyTokens.
     *
     * @param fyToken The address of the FyToken contract.
     * @param borrowAmount The amount of fyTokens to borrow.
     */
    function borrow(FyTokenInterface fyToken, uint256 borrowAmount) public {
        fyToken.borrow(borrowAmount);
        fyToken.safeTransfer(msg.sender, borrowAmount);
    }

    /**
     * @notice Borrows fyTokens and sells them on Balancer in exchange for underlying.
     *
     * @dev Emits a {BorrowAndSellFyTokens} event.
     *
     * This is a payable function so it can receive ETH transfers.
     *
     * @param fyToken The address of the FyToken contract.
     * @param borrowAmount The amount of fyTokens to borrow.
     * @param underlyingAmount The amount of underlying to sell fyTokens for.
     */
    function borrowAndSellFyTokens(
        FyTokenInterface fyToken,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) public payable {
        Erc20Interface underlying = fyToken.underlying();

        /* Borrow the fyTokens. */
        fyToken.borrow(borrowAmount);

        /* Allow the Balancer contract to spend fyTokens if allowance not enough. */
        uint256 allowance = fyToken.allowance(address(this), EXCHANGE_PROXY_ADDRESS);
        if (allowance < borrowAmount) {
            fyToken.approve(EXCHANGE_PROXY_ADDRESS, type(uint256).max);
        }

        /* Prepare the parameters for calling Balancer. */
        TokenInterface tokenIn = TokenInterface(address(fyToken));
        TokenInterface tokenOut = TokenInterface(address(underlying));
        uint256 totalAmountOut = underlyingAmount;
        uint256 maxTotalAmountIn = borrowAmount;
        uint256 nPools = 1;

        /* Recall that Balancer reverts when the swap is not successful. */
        uint256 totalAmountIn =
            ExchangeProxyInterface(EXCHANGE_PROXY_ADDRESS).smartSwapExactOut(
                tokenIn,
                tokenOut,
                totalAmountOut,
                maxTotalAmountIn,
                nPools
            );

        /* When we get a better price than the worst that we assumed we would, not all fyTokens are sold. */
        MathError mathErr;
        uint256 fyTokenDelta;
        (mathErr, fyTokenDelta) = subUInt(borrowAmount, totalAmountIn);
        require(mathErr == MathError.NO_ERROR, "ERR_BORROW_AND_SELL_FYTOKENS_MATH_ERROR");

        /* If the fyToken delta is non-zero, we use it to partially repay the borrow. */
        /* Note: this is not gas-efficient. */
        if (fyTokenDelta > 0) {
            fyToken.repayBorrow(fyTokenDelta);
        }

        /* Finally, transfer the recently bought underlying to the end user. */
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit BorrowAndSellFyTokens(msg.sender, borrowAmount, fyTokenDelta, underlyingAmount);
    }

    /**
     * @notice Deposits collateral into the BalanceSheet contract.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to deposit.
     */
    function depositCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) public {
        /* Transfer the collateral to the DSProxy. */
        fyToken.collateral().safeTransferFrom(msg.sender, address(this), collateralAmount);

        /* Deposit the collateral into the BalanceSheet contract. */
        depositCollateralInternal(balanceSheet, fyToken, collateralAmount);
    }

    /**
     * @notice Deposits and locks collateral into the BalanceSheet contract.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to deposit and lock.
     */
    function depositAndLockCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) public {
        depositCollateral(balanceSheet, fyToken, collateralAmount);
        balanceSheet.lockCollateral(fyToken, collateralAmount);
    }

    /**
     * @notice Deposits and locks collateral into the vault via the BalanceSheet contract
     * and borrows fyTokens.
     *
     * @dev This is a payable function so it can receive ETH transfers.
     *
     * Requirements:
     * - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to deposit and lock.
     * @param borrowAmount The amount of fyTokens to borrow.
     */
    function depositAndLockCollateralAndBorrow(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) public payable {
        depositAndLockCollateral(balanceSheet, fyToken, collateralAmount);
        borrow(fyToken, borrowAmount);
    }

    /**
     * @notice Deposits and locks collateral into the vault via the BalanceSheet contract, borrows fyTokens
     * and sells them on Balancer in exchange for underlying.
     *
     * @dev This is a payable function so it can receive ETH transfers.
     *
     * Requirements:
     * - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to deposit and lock.
     * @param borrowAmount The amount of fyTokens to borrow.
     * @param underlyingAmount The amount of underlying to sell fyTokens for.
     */
    function depositAndLockCollateralAndBorrowAndSellFyTokens(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) external payable {
        depositAndLockCollateral(balanceSheet, fyToken, collateralAmount);
        borrowAndSellFyTokens(fyToken, borrowAmount, underlyingAmount);
    }

    /**
     * @notice Frees collateral from the vault in the BalanceSheet contract.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to free.
     */
    function freeCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) external {
        balanceSheet.freeCollateral(fyToken, collateralAmount);
    }

    /**
     * @notice Frees collateral from the vault and withdraws it from the
     * BalanceSheet contract.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to free and withdraw.
     */
    function freeAndWithdrawCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) external {
        balanceSheet.freeCollateral(fyToken, collateralAmount);
        withdrawCollateral(balanceSheet, fyToken, collateralAmount);
    }

    /**
     * @notice Locks collateral in the vault in the BalanceSheet contract.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to lock.
     */
    function lockCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) external {
        balanceSheet.lockCollateral(fyToken, collateralAmount);
    }

    /**
     * @notice Locks collateral into the vault in the BalanceSheet contract
     * and draws debt via the FyToken contract.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to lock.
     * @param borrowAmount The amount of fyTokens to borrow.
     * @param underlyingAmount The amount of underlying to sell fyTokens for.
     */
    function lockCollateralAndBorrow(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) external {
        balanceSheet.lockCollateral(fyToken, collateralAmount);
        borrowAndSellFyTokens(fyToken, borrowAmount, underlyingAmount);
    }

    /**
     * @notice Open the vaults in the BalanceSheet contract for the given fyToken.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     */
    function openVault(BalanceSheetInterface balanceSheet, FyTokenInterface fyToken) external {
        balanceSheet.openVault(fyToken);
    }

    /**
     * @notice Redeems fyTokens in exchange for underlying tokens.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `repayAmount` fyTokens.
     *
     * @param fyToken The address of the FyToken contract.
     * @param fyTokenAmount The amount of fyTokens to redeem.
     */
    function redeemFyTokens(FyTokenInterface fyToken, uint256 fyTokenAmount) public {
        Erc20Interface underlying = fyToken.underlying();
        RedemptionPoolInterface redemptionPool = fyToken.redemptionPool();

        /* Transfer the fyTokens to the DSProxy. */
        fyToken.safeTransferFrom(msg.sender, address(this), fyTokenAmount);

        /* Redeem the fyTokens. */
        uint256 preUnderlyingBalance = underlying.balanceOf(address(this));
        redemptionPool.redeemFyTokens(fyTokenAmount);

        /* Calculate how many underlying have been redeemed. */
        uint256 postUnderlyigBalance = underlying.balanceOf(address(this));
        MathError mathErr;
        uint256 underlyingAmount;
        (mathErr, underlyingAmount) = subUInt(postUnderlyigBalance, preUnderlyingBalance);
        require(mathErr == MathError.NO_ERROR, "ERR_REDEEM_FYTOKENS_MATH_ERROR");

        /* The underlying is now in the DSProxy, so we relay it to the end user. */
        underlying.safeTransfer(msg.sender, underlyingAmount);
    }

    /**
     * @notice Repays the fyToken borrow.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `repayAmount` fyTokens.
     *
     * @param fyToken The address of the FyToken contract.
     * @param repayAmount The amount of fyTokens to repay.
     */
    function repayBorrow(FyTokenInterface fyToken, uint256 repayAmount) public {
        /* Transfer the fyTokens to the DSProxy. */
        fyToken.safeTransferFrom(msg.sender, address(this), repayAmount);

        /* Repay the borrow. */
        fyToken.repayBorrow(repayAmount);
    }

    /**
     * @notice Market sells underlying and repays the borrows via the FyToken contract.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `underlyingAmount` tokens.
     *
     * @param fyToken The address of the FyToken contract.
     * @param underlyingAmount The amount of underlying to sell.
     * @param repayAmount The amount of fyTokens to repay.
     */
    function sellUnderlyingAndRepayBorrow(
        FyTokenInterface fyToken,
        uint256 underlyingAmount,
        uint256 repayAmount
    ) external {
        Erc20Interface underlying = fyToken.underlying();

        /* Transfer the underlying to the DSProxy. */
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        /* Allow the Balancer contract to spend underlying if allowance not enough. */
        uint256 allowance = underlying.allowance(address(this), EXCHANGE_PROXY_ADDRESS);
        if (allowance < underlyingAmount) {
            underlying.approve(EXCHANGE_PROXY_ADDRESS, type(uint256).max);
        }

        /* Prepare the parameters for calling Balancer. */
        TokenInterface tokenIn = TokenInterface(address(underlying));
        TokenInterface tokenOut = TokenInterface(address(fyToken));
        uint256 totalAmountOut = repayAmount;
        uint256 maxTotalAmountIn = underlyingAmount;
        uint256 nPools = 1;

        /* Recall that Balancer reverts when the swap is not successful. */
        uint256 totalAmountIn =
            ExchangeProxyInterface(EXCHANGE_PROXY_ADDRESS).smartSwapExactOut(
                tokenIn,
                tokenOut,
                totalAmountOut,
                maxTotalAmountIn,
                nPools
            );

        /* Use the recently bought fyTokens to repay the borrow. */
        fyToken.repayBorrow(repayAmount);

        /* When we get a better price than the worst that we assumed we would, not all underlying is sold. */
        MathError mathErr;
        uint256 underlyingDelta;
        (mathErr, underlyingDelta) = subUInt(underlyingAmount, totalAmountIn);
        require(mathErr == MathError.NO_ERROR, "ERR_SELL_UNDERLYING_AND_REPAY_BORROW_MATH_ERROR");

        /* If the underlying delta is non-zero, send it back to the user. */
        if (underlyingDelta > 0) {
            underlying.safeTransfer(msg.sender, underlyingDelta);
        }
    }

    /**
     * @notice Supplies the underlying to the RedemptionPool contract and mints fyTokens.
     * @param fyToken The address of the FyToken contract.
     * @param underlyingAmount The amount of underlying to supply.
     */
    function supplyUnderlying(FyTokenInterface fyToken, uint256 underlyingAmount) public {
        uint256 preFyTokenBalance = fyToken.balanceOf(address(this));
        supplyUnderlyingInternal(fyToken, underlyingAmount);

        /* Calculate how many fyTokens have been minted. */
        uint256 postFyTokenBalance = fyToken.balanceOf(address(this));
        MathError mathErr;
        uint256 fyTokenAmount;
        (mathErr, fyTokenAmount) = subUInt(postFyTokenBalance, preFyTokenBalance);
        require(mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_MATH_ERROR");

        /* The fyTokens are now in the DSProxy, so we relay them to the end user. */
        fyToken.safeTransfer(msg.sender, fyTokenAmount);
    }

    /**
     * @notice Supplies the underlying to the RedemptionPool contract, mints fyTokens
     * and repays the borrow.
     *
     * @dev Requirements:
     * - The caller must have allowed the DSProxy to spend `underlyingAmount` tokens.
     *
     * @param fyToken The address of the FyToken contract.
     * @param underlyingAmount The amount of underlying to supply.
     */
    function supplyUnderlyingAndRepayBorrow(FyTokenInterface fyToken, uint256 underlyingAmount) external {
        uint256 preFyTokenBalance = fyToken.balanceOf(address(this));
        supplyUnderlyingInternal(fyToken, underlyingAmount);

        /* Calculate how many fyTokens have been minted. */
        uint256 postFyTokenBalance = fyToken.balanceOf(address(this));
        MathError mathErr;
        uint256 fyTokenAmount;
        (mathErr, fyTokenAmount) = subUInt(postFyTokenBalance, preFyTokenBalance);
        require(mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_AND_REPAY_BORROW_MATH_ERROR");

        /* Use the newly minted fyTokens to repay the debt. */
        fyToken.repayBorrow(fyTokenAmount);
    }

    /**
     * @notice Withdraws collateral from the vault in the BalanceSheet contract.
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param collateralAmount The amount of collateral to withdraw.
     */
    function withdrawCollateral(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) public {
        balanceSheet.withdrawCollateral(fyToken, collateralAmount);

        /* The collateral is now in the DSProxy, so we relay it to the end user. */
        Erc20Interface collateral = fyToken.collateral();
        collateral.safeTransfer(msg.sender, collateralAmount);
    }

    /**
     * @notice Wraps ETH into WETH and deposits into the BalanceSheet contract.
     *
     * @dev This is a payable function so it can receive ETH transfers.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     */
    function wrapEthAndDepositCollateral(BalanceSheetInterface balanceSheet, FyTokenInterface fyToken) public payable {
        uint256 collateralAmount = msg.value;

        /* Convert the received ETH to WETH. */
        WethInterface(WETH_ADDRESS).deposit{ value: collateralAmount }();

        /* Deposit the collateral into the BalanceSheet contract. */
        depositCollateralInternal(balanceSheet, fyToken, collateralAmount);
    }

    /**
     * @notice Wraps ETH into WETH, deposits and locks collateral into the BalanceSheet contract
     * and borrows fyTokens.
     *
     * @dev This is a payable function so it can receive ETH transfers.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     */
    function wrapEthAndDepositAndLockCollateral(BalanceSheetInterface balanceSheet, FyTokenInterface fyToken)
        public
        payable
    {
        uint256 collateralAmount = msg.value;
        wrapEthAndDepositCollateral(balanceSheet, fyToken);
        balanceSheet.lockCollateral(fyToken, collateralAmount);
    }

    /**
     * @notice Wraps ETH into WETH, deposits and locks collateral into the vault in the BalanceSheet
     * contracts and borrows fyTokens.
     *
     * @dev This is a payable function so it can receive ETH transfers.
     *
     * @param balanceSheet The address of the BalanceSheet contract.
     * @param fyToken The address of the FyToken contract.
     * @param borrowAmount The amount of fyTokens to borrow.
     * @param underlyingAmount The amount of underlying to sell fyTokens for.
     */
    function wrapEthAndDepositAndLockCollateralAndBorrow(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 borrowAmount,
        uint256 underlyingAmount
    ) external payable {
        wrapEthAndDepositAndLockCollateral(balanceSheet, fyToken);
        borrowAndSellFyTokens(fyToken, borrowAmount, underlyingAmount);
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev See the documentation for the public functions that call this internal function.
     */
    function depositCollateralInternal(
        BalanceSheetInterface balanceSheet,
        FyTokenInterface fyToken,
        uint256 collateralAmount
    ) internal {
        /* Allow the BalanceSheet contract to spend tokens if allowance not enough. */
        Erc20Interface collateral = fyToken.collateral();
        uint256 allowance = collateral.allowance(address(this), address(balanceSheet));
        if (allowance < collateralAmount) {
            collateral.approve(address(balanceSheet), type(uint256).max);
        }

        /* Open the vault if not already open. */
        bool isVaultOpen = balanceSheet.isVaultOpen(fyToken, address(this));
        if (isVaultOpen == false) {
            balanceSheet.openVault(fyToken);
        }

        /* Deposit the collateral into the BalanceSheet contract. */
        balanceSheet.depositCollateral(fyToken, collateralAmount);
    }

    /**
     * @dev See the documentation for the public functions that call this internal function.
     */
    function supplyUnderlyingInternal(FyTokenInterface fyToken, uint256 underlyingAmount) internal {
        RedemptionPoolInterface redemptionPool = fyToken.redemptionPool();
        Erc20Interface underlying = fyToken.underlying();

        /* Transfer the underlying to the DSProxy. */
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        /* Allow the RedemptionPool contract to spend tokens if allowance not enough. */
        uint256 allowance = underlying.allowance(address(this), address(redemptionPool));
        if (allowance < underlyingAmount) {
            underlying.approve(address(redemptionPool), type(uint256).max);
        }

        /* Supply the underlying and mint fyTokens. */
        redemptionPool.supplyUnderlying(underlyingAmount);
    }
}