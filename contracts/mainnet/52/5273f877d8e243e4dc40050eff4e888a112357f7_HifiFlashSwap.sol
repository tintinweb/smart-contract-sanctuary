// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./Erc20Interface.sol";
import "./BalanceSheetInterface.sol";
import "./FyTokenInterface.sol";
import "./RedemptionPoolInterface.sol";

import "./HifiFlashSwapInterface.sol";
import "./UniswapV2PairLike.sol";

/// @title HifiFlashSwap
/// @author Hifi
contract HifiFlashSwap is
    HifiFlashSwapInterface, // one dependency
    Admin // two dependencies
{
    constructor(address balanceSheet_, address pair_) Admin() {
        balanceSheet = BalanceSheetInterface(balanceSheet_);
        pair = UniswapV2PairLike(pair_);
        wbtc = Erc20Interface(pair.token0());
        usdc = Erc20Interface(pair.token1());
    }

    /// @dev Calculate the amount of WBTC that has to be repaid to Uniswap. The formula applied is:
    ///
    ///              (wbtcReserves * usdcAmount) * 1000
    /// repayment = ------------------------------------
    ///              (usdcReserves - usdcAmount) * 997
    ///
    /// See "getAmountIn" and "getAmountOut" in UniswapV2Library.sol. Flash swaps that are repaid via
    /// the corresponding pair token is akin to a normal swap, so the 0.3% LP fee applies.
    function getRepayWbtcAmount(uint256 usdcAmount) public view returns (uint256) {
        (uint112 wbtcReserves, uint112 usdcReserves, ) = pair.getReserves();

        // Note that we don't need CarefulMath because the UniswapV2Pair.sol contract performs sanity
        // checks on "wbtcAmount" and "usdcAmount" before calling the current contract.
        uint256 numerator = wbtcReserves * usdcAmount * 1000;
        uint256 denominator = (usdcReserves - usdcAmount) * 997;
        uint256 wbtcRepaymentAmount = numerator / denominator + 1;

        return wbtcRepaymentAmount;
    }

    /// @dev Called by the UniswapV2Pair contract.
    function uniswapV2Call(
        address sender,
        uint256 wbtcAmount,
        uint256 usdcAmount,
        bytes calldata data
    ) external override {
        // Unpack the ABI encoded data passed by the UniswapV2Pair contract.
        (address fyTokenAddress, address borrower, uint256 minProfit) = abi.decode(data, (address, address, uint256));
        FyTokenInterface fyToken = FyTokenInterface(fyTokenAddress);
        require(balanceSheet.isAccountUnderwater(fyToken, borrower), "ERR_ACCOUNT_NOT_UNDERWATER");
        require(fyToken.isFyToken(), "ERR_FYTOKEN_INSPECTION");

        require(msg.sender == address(pair), "ERR_UNISWAP_V2_CALL_NOT_AUTHORIZED");
        require(wbtcAmount == 0, "ERR_WBTC_AMOUNT_ZERO");

        // Mint fyUSDC and liquidate the borrower.
        uint256 mintedFyUsdcAmount = mintFyUsdc(fyToken, usdcAmount);
        uint256 clutchedWbtcAmount = liquidateBorrow(fyToken, borrower, mintedFyUsdcAmount);

        // Calculate the amount of WBTC required.
        uint256 repayWbtcAmount = getRepayWbtcAmount(usdcAmount);
        require(clutchedWbtcAmount > repayWbtcAmount + minProfit, "ERR_INSUFFICIENT_PROFIT");

        // Pay back the loan.
        require(wbtc.transfer(address(pair), repayWbtcAmount), "ERR_WBTC_TRANSFER");

        // Reap the profit.
        uint256 profit = clutchedWbtcAmount - repayWbtcAmount;
        wbtc.transfer(sender, profit);

        emit FlashLiquidate(
            sender,
            borrower,
            fyTokenAddress,
            usdcAmount,
            mintedFyUsdcAmount,
            clutchedWbtcAmount,
            profit
        );
    }

    /// @dev Supply the USDC to the RedemptionPool and mint fyUSDC.
    function mintFyUsdc(FyTokenInterface fyToken, uint256 usdcAmount) internal returns (uint256) {
        RedemptionPoolInterface redemptionPool = fyToken.redemptionPool();

        // Allow the RedemptionPool to spend USDC if allowance not enough.
        uint256 allowance = usdc.allowance(address(this), address(redemptionPool));
        if (allowance < usdcAmount) {
            usdc.approve(address(redemptionPool), type(uint256).max);
        }

        uint256 oldFyTokenBalance = fyToken.balanceOf(address(this));
        redemptionPool.supplyUnderlying(usdcAmount);
        uint256 newFyTokenBalance = fyToken.balanceOf(address(this));
        uint256 mintedFyUsdcAmount = newFyTokenBalance - oldFyTokenBalance;
        return mintedFyUsdcAmount;
    }

    /// @dev Liquidate the borrower by transferring the USDC to the BalanceSheet. In doing this,
    /// the liquidator receives WBTC at a discount.
    function liquidateBorrow(
        FyTokenInterface fyToken,
        address borrower,
        uint256 mintedFyUsdcAmount
    ) internal returns (uint256) {
        uint256 oldWbtcBalance = wbtc.balanceOf(address(this));
        fyToken.liquidateBorrow(borrower, mintedFyUsdcAmount);
        uint256 newWbtcBalance = wbtc.balanceOf(address(this));
        uint256 clutchedWbtcAmount = newWbtcBalance - oldWbtcBalance;
        return clutchedWbtcAmount;
    }
}