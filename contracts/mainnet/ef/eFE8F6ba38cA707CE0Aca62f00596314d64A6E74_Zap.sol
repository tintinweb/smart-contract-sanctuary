// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./Curve.sol";

import "./console.sol";

contract Zap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    struct ZapData {
        address curve;
        address base;
        uint256 zapAmount;
        uint256 curveBaseBal;
        uint8 curveBaseDecimals;
        uint256 curveQuoteBal;
    }

    struct DepositData {
        uint256 curBaseAmount;
        uint256 curQuoteAmount;
        uint256 maxBaseAmount;
        uint256 maxQuoteAmount;
    }

    struct DepositAmountsData {
        uint256 curveRatio;
        uint256 depositAmount1;
        uint256 depositAmount2;
        uint256 lp1;
        uint256[] outs1;
        uint256 lp2;
        uint256[] outs2;
    }

    /// @notice Zaps from a quote token (non-USDC) into the LP pool
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param _deadline Deadline for this zap to be completed by
    /// @param _minLPAmount Min LP amount to get
    /// @return uint256 - The amount of LP tokens received
    function zapFromBase(
        address _curve,
        uint256 _zapAmount,
        uint256 _deadline,
        uint256 _minLPAmount
    ) public returns (uint256) {
        return zap(_curve, _zapAmount, _deadline, _minLPAmount, true);
    }

    /// @notice Zaps from a quote token (USDC) into the LP pool
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param _deadline Deadline for this zap to be completed by
    /// @param _minLPAmount Min LP amount to get
    /// @return uint256 - The amount of LP tokens received
    function zapFromQuote(
        address _curve,
        uint256 _zapAmount,
        uint256 _deadline,
        uint256 _minLPAmount
    ) public returns (uint256) {
        return zap(_curve, _zapAmount, _deadline, _minLPAmount, false);
    }

    /// @notice Zaps from a single token into the LP pool
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param _deadline Deadline for this zap to be completed by
    /// @param _minLPAmount Min LP amount to get
    /// @param isFromBase Is the zap originating from the base? (if base, then not USDC)
    /// @return uint256 - The amount of LP tokens received
    function zap(
        address _curve,
        uint256 _zapAmount,
        uint256 _deadline,
        uint256 _minLPAmount,
        bool isFromBase
    ) public returns (uint256) {
        (address base, uint256 swapAmount) = calcSwapAmountForZap(_curve, _zapAmount, isFromBase);

        // Swap on curve
        if (isFromBase) {
            IERC20(base).safeTransferFrom(msg.sender, address(this), _zapAmount);
            IERC20(base).safeApprove(_curve, 0);
            IERC20(base).safeApprove(_curve, swapAmount);

            Curve(_curve).originSwap(base, address(USDC), swapAmount, 0, _deadline);
        } else {
            USDC.safeTransferFrom(msg.sender, address(this), _zapAmount);
            USDC.safeApprove(_curve, 0);
            USDC.safeApprove(_curve, swapAmount);

            Curve(_curve).originSwap(address(USDC), base, swapAmount, 0, _deadline);
        }

        // Calculate deposit amount
        (uint256 depositAmount, uint256 baseAmount, uint256 quoteAmount) = _calcDepositAmount(_curve, base);

        // Can only deposit the smaller amount as we won't have enough of the
        // token to deposit
        IERC20(base).safeApprove(_curve, 0);
        IERC20(base).safeApprove(_curve, baseAmount);

        USDC.safeApprove(_curve, 0);
        USDC.safeApprove(_curve, quoteAmount);

        (uint256 lpAmount, ) = Curve(_curve).deposit(depositAmount, _deadline);
        require(lpAmount >= _minLPAmount, "!Zap/not-enough-lp-amount");

        // Transfer all remaining balances back to user
        IERC20(_curve).transfer(msg.sender, IERC20(_curve).balanceOf(address(this)));
        IERC20(base).transfer(msg.sender, IERC20(base).balanceOf(address(this)));
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

        return lpAmount;
    }

    // **** View only functions **** //

    /// @notice Iteratively calculates how much base to swap
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @return uint256 - The amount to swap
    function calcSwapAmountForZapFromBase(address _curve, uint256 _zapAmount) public view returns (uint256) {
        (, uint256 ret) = calcSwapAmountForZap(_curve, _zapAmount, true);
        return ret;
    }

    /// @notice Iteratively calculates how much quote to swap
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @return uint256 - The amount to swap
    function calcSwapAmountForZapFromQuote(address _curve, uint256 _zapAmount) public view returns (uint256) {
        (, uint256 ret) = calcSwapAmountForZap(_curve, _zapAmount, false);
        return ret;
    }

    /// @notice Iteratively calculates how much to swap
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param isFromBase Is the swap originating from the base?
    /// @return address - The address of the base
    /// @return uint256 - The amount to swap
    function calcSwapAmountForZap(
        address _curve,
        uint256 _zapAmount,
        bool isFromBase
    ) public view returns (address, uint256) {
        // Base will always be index 0
        address base = Curve(_curve).reserves(0);

        // Ratio of base quote in 18 decimals
        uint256 curveBaseBal = IERC20(base).balanceOf(_curve);
        uint8 curveBaseDecimals = ERC20(base).decimals();
        uint256 curveQuoteBal = USDC.balanceOf(_curve);
        uint256 curveRatio = curveBaseBal.mul(10**(36 - uint256(curveBaseDecimals))).div(curveQuoteBal.mul(1e12));

        // How much user wants to swap
        uint256 initialSwapAmount =
            _zapAmount.sub(
                curveRatio <= 1e18 ? _zapAmount.mul(curveRatio).div(1e18) : _zapAmount.mul(1e18).div(curveRatio)
            );

        // Calc Base Swap Amount
        if (isFromBase) {
            return (
                base,
                _calcBaseSwapAmount(
                    initialSwapAmount,
                    ZapData({
                        curve: _curve,
                        base: base,
                        zapAmount: _zapAmount,
                        curveBaseBal: curveBaseBal,
                        curveBaseDecimals: curveBaseDecimals,
                        curveQuoteBal: curveQuoteBal
                    })
                )
            );
        }

        // Calc quote swap amount
        return (
            base,
            _calcQuoteSwapAmount(
                initialSwapAmount,
                ZapData({
                    curve: _curve,
                    base: base,
                    zapAmount: _zapAmount,
                    curveBaseBal: curveBaseBal,
                    curveBaseDecimals: curveBaseDecimals,
                    curveQuoteBal: curveQuoteBal
                })
            )
        );
    }

    // **** Helper functions ****

    /// @notice Given a base amount, and a quote amount, calculate the deposit amount,
    ///         the number of LP tokens that will be generated, along with the maximized
    ///         base/quote amounts
    /// @param _curve The address of the curve
    /// @param _baseAmount The amount of base tokens
    /// @param _quoteAmount The amount of base tokens
    /// @return uint256 - The deposit amount
    /// @return uint256 - The LPTs received
    /// @return uint256[] memory - The baseAmount and quoteAmount
    function calcMaxDepositAmount(
        address _curve,
        uint256 _baseAmount,
        uint256 _quoteAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return
            _calcMaxDepositAmount(
                _curve,
                DepositData({
                    curBaseAmount: _baseAmount,
                    curQuoteAmount: _quoteAmount,
                    maxBaseAmount: _baseAmount,
                    maxQuoteAmount: _quoteAmount
                })
            );
    }

    /// @notice Given a base amount, calculate the max base amount to be deposited
    /// @param _curve The address of the curve
    /// @param _quoteAmount The amount of base tokens
    /// @return uint256 - The max quote amount
    function calcMaxBaseForDeposit(address _curve, uint256 _quoteAmount) public view returns (uint256) {
        (, uint256[] memory outs) = Curve(_curve).viewDeposit(2e18);
        uint256 baseAmount = outs[0].mul(_quoteAmount).div(1e6);

        return baseAmount;
    }

    /// @notice Given a base amount, calculate the max quote amount to be deposited
    /// @param _curve The address of the curve
    /// @param _baseAmount The amount of quote tokens
    /// @return uint256 - The max quote amount
    function calcMaxQuoteForDeposit(address _curve, uint256 _baseAmount) public view returns (uint256) {
        uint8 curveBaseDecimals = ERC20(Curve(_curve).reserves(0)).decimals();
        (, uint256[] memory outs) = Curve(_curve).viewDeposit(2e18);
        uint256 ratio = outs[0].mul(10**(36 - curveBaseDecimals)).div(outs[1].mul(1e12));
        uint256 quoteAmount = _baseAmount.mul(10**(36 - curveBaseDecimals)).div(ratio).div(1e12);

        return quoteAmount;
    }

    // **** Internal function ****

    // Stack too deep resulted in this function
    function _ratio(uint256 ratio, uint256 a) internal pure returns (uint256) {
        if (ratio > 1e18) {
            return a.mul(1e18).div(ratio);
        }
        return a.mul(ratio).div(1e18);
    }

    // Stack too deep
    function _getCurveRatioAndBaseDecimals(address _curve) internal view returns (uint8, uint256) {
        address base = Curve(_curve).reserves(0);
        uint8 curveBaseDecimals = ERC20(base).decimals();
        uint256 curveRatio =
            IERC20(base).balanceOf(_curve).mul(10**(36 - uint256(curveBaseDecimals))).div(
                USDC.balanceOf(_curve).mul(1e12)
            );

        return (curveBaseDecimals, curveRatio);
    }

    function _getDepositAmountsData(address _curve, DepositData memory dd)
        internal
        view
        returns (DepositAmountsData memory)
    {
        uint256 maxBaseAmount = calcMaxBaseForDeposit(_curve, dd.curQuoteAmount);
        uint256 maxQuoteAmount = calcMaxQuoteForDeposit(_curve, dd.curBaseAmount);

        (uint8 curveBaseDecimals, uint256 curveRatio) = _getCurveRatioAndBaseDecimals(_curve);

        uint256 depositAmount1;
        uint256 depositAmount2;
        uint256 lp1;
        uint256[] memory outs1;
        uint256 lp2;
        uint256[] memory outs2;

        // Stack too deep
        {
            uint256 usdcDepositAmount = dd.curQuoteAmount.mul(1e12);
            uint256 baseDepositAmount = maxBaseAmount.mul(10**(18 - curveBaseDecimals));
            depositAmount1 = usdcDepositAmount.add(baseDepositAmount.mul(1e18).div(curveRatio));

            // Prune amounts to get best possible result
            // Due to loss in precision in floating point math
            depositAmount1 = depositAmount1.mul(9995).div(10000);
            (lp1, outs1) = Curve(_curve).viewDeposit(depositAmount1);

            // Re-using variables
            usdcDepositAmount = maxQuoteAmount.div(1e4).mul(1e16);
            baseDepositAmount = dd.curBaseAmount.mul(10**(18 - curveBaseDecimals));
            depositAmount2 = usdcDepositAmount.add(baseDepositAmount.mul(1e18).div(curveRatio));

            // Prune amounts to get best possible result
            // Due to loss in precision in floating point math
            depositAmount2 = depositAmount2.mul(9995).div(10000);

            // EURS 2 decimals screws things up for small amounts
            // Need to give 2% slippage
            if (curveBaseDecimals == 2) {
                depositAmount2 = depositAmount2.mul(98).div(100);
            }

            (lp2, outs2) = Curve(_curve).viewDeposit(depositAmount2);
        }

        return
            DepositAmountsData({
                curveRatio: curveRatio,
                depositAmount1: depositAmount1,
                depositAmount2: depositAmount2,
                lp1: lp1,
                outs1: outs1,
                lp2: lp2,
                outs2: outs2
            });
    }

    function _calcMaxDepositAmount(address _curve, DepositData memory dd)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        DepositAmountsData memory dad = _getDepositAmountsData(_curve, dd);

        // Both invalid, can't use max
        // Use smaller value
        if (
            (dad.outs1[0] > dd.maxBaseAmount || dad.outs1[1] > dd.maxQuoteAmount) &&
            (dad.outs2[0] > dd.maxBaseAmount || dad.outs2[1] > dd.maxQuoteAmount)
        ) {
            return
                _calcMaxDepositAmount(
                    _curve,
                    DepositData({
                        curBaseAmount: _ratio(dad.curveRatio, dd.curBaseAmount),
                        curQuoteAmount: _ratio(dad.curveRatio, dd.curQuoteAmount),
                        maxBaseAmount: dd.maxBaseAmount,
                        maxQuoteAmount: dd.maxQuoteAmount
                    })
                );
        }

        // Only deposit 1 is valid
        if (
            dad.outs1[0] <= dd.maxBaseAmount &&
            dad.outs1[1] <= dd.maxQuoteAmount &&
            (dad.outs2[0] > dd.maxBaseAmount || dad.outs2[1] > dd.maxQuoteAmount)
        ) {
            return (dad.depositAmount1, dad.lp1, dad.outs1);
        }

        // Only deposit 2 is valid
        if (
            dad.outs2[0] <= dd.maxBaseAmount &&
            dad.outs2[1] <= dd.maxQuoteAmount &&
            (dad.outs1[0] > dd.maxBaseAmount || dad.outs1[1] > dd.maxQuoteAmount)
        ) {
            return (dad.depositAmount2, dad.lp2, dad.outs2);
        }

        // Both valid however, just return the largest
        if (dad.lp1 > dad.lp2) {
            return (dad.depositAmount1, dad.lp1, dad.outs1);
        }

        return (dad.depositAmount2, dad.lp2, dad.outs2);
    }

    function _calcQuoteSwapAmount(uint256 initialSwapAmount, ZapData memory zapData) internal view returns (uint256) {
        uint256 swapAmount = initialSwapAmount;
        uint256 delta = swapAmount.div(2);
        uint256 recvAmount;
        uint256 curveRatio;
        uint256 userRatio;

        // Computer bring me magic number
        for (uint256 i = 0; i < 32; i++) {
            // How much will we receive in return
            recvAmount = Curve(zapData.curve).viewOriginSwap(address(USDC), zapData.base, swapAmount);

            // Update user's ratio
            userRatio = recvAmount.mul(10**(36 - uint256(zapData.curveBaseDecimals))).div(
                zapData.zapAmount.sub(swapAmount).mul(1e12)
            );
            curveRatio = zapData.curveBaseBal.sub(recvAmount).mul(10**(36 - uint256(zapData.curveBaseDecimals))).div(
                zapData.curveQuoteBal.add(swapAmount).mul(1e12)
            );

            // If user's ratio is approx curve ratio, then just swap
            // I.e. ratio converges
            if (userRatio.div(1e12) == curveRatio.div(1e12)) {
                return swapAmount;
            }
            // Otherwise, we keep iterating
            else if (userRatio > curveRatio) {
                // We swapping too much
                swapAmount = swapAmount.sub(delta);
            } else if (userRatio < curveRatio) {
                // We swapping too little
                swapAmount = swapAmount.add(delta);
            }

            // Cannot swap more than zapAmount
            if (swapAmount > zapData.zapAmount) {
                swapAmount = zapData.zapAmount - 1;
            }

            // Keep halving
            delta = delta.div(2);
        }

        return swapAmount;
    }

    function _calcBaseSwapAmount(uint256 initialSwapAmount, ZapData memory zapData) internal view returns (uint256) {
        uint256 swapAmount = initialSwapAmount;
        uint256 delta = swapAmount.div(2);
        uint256 recvAmount;
        uint256 curveRatio;
        uint256 userRatio;

        // Computer bring me magic number
        for (uint256 i = 0; i < 32; i++) {
            // How much will we receive in return
            recvAmount = Curve(zapData.curve).viewOriginSwap(zapData.base, address(USDC), swapAmount);

            // Update user's ratio
            userRatio = zapData.zapAmount.sub(swapAmount).mul(10**(36 - uint256(zapData.curveBaseDecimals))).div(
                recvAmount.mul(1e12)
            );
            curveRatio = zapData.curveBaseBal.add(swapAmount).mul(10**(36 - uint256(zapData.curveBaseDecimals))).div(
                zapData.curveQuoteBal.sub(recvAmount).mul(1e12)
            );

            // If user's ratio is approx curve ratio, then just swap
            // I.e. ratio converges
            if (userRatio.div(1e12) == curveRatio.div(1e12)) {
                return swapAmount;
            }
            // Otherwise, we keep iterating
            else if (userRatio > curveRatio) {
                // We swapping too little
                swapAmount = swapAmount.add(delta);
            } else if (userRatio < curveRatio) {
                // We swapping too much
                swapAmount = swapAmount.sub(delta);
            }

            // Cannot swap more than zap
            if (swapAmount > zapData.zapAmount) {
                swapAmount = zapData.zapAmount - 1;
            }

            // Keep halving
            delta = delta.div(2);
        }

        return swapAmount;
    }

    function _calcDepositAmount(address _curve, address _base)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Calculate _depositAmount
        uint8 curveBaseDecimals = ERC20(_base).decimals();
        uint256 curveRatio =
            IERC20(_base).balanceOf(_curve).mul(10**(36 - uint256(curveBaseDecimals))).div(
                USDC.balanceOf(_curve).mul(1e12)
            );

        // Deposit amount is denomiated in USD value (based on pool LP ratio)
        // Things are 1:1 on USDC side on deposit
        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdcDepositAmount = usdcAmount.mul(1e12);

        // Things will be based on ratio on deposit
        uint256 baseAmount = IERC20(_base).balanceOf(address(this));
        uint256 baseDepositAmount = baseAmount.mul(10**(18 - uint256(curveBaseDecimals)));

        // Trim out decimal values
        uint256 depositAmount = usdcDepositAmount.add(baseDepositAmount.mul(1e18).div(curveRatio));

        // Good morning fuck EURS
        if (curveBaseDecimals == 2) {
            depositAmount = depositAmount.mul(98).div(100);
        }

        // // Make sure we have enough of our inputs
        (, uint256[] memory outs) = Curve(_curve).viewDeposit(1e18);

        (, outs) = Curve(_curve).viewDeposit(depositAmount);

        uint256 baseDelta = outs[0] > baseAmount ? outs[0].sub(baseAmount) : 0;
        uint256 usdcDelta = outs[1] > usdcAmount ? outs[1].sub(usdcAmount) : 0;
        uint256 ratio;

        // Make sure we can deposit
        if (baseDelta > 0) {
            ratio = baseDelta.mul(10**curveBaseDecimals).div(baseAmount);
            depositAmount = depositAmount.sub(depositAmount.mul(ratio).div(10**curveBaseDecimals));
        }

        if (usdcDelta > 0) {
            ratio = usdcDelta.mul(1e6).div(usdcAmount);
            depositAmount = depositAmount.sub(depositAmount.mul(ratio).div(1e6));
        }

        // Truncate for rounding errors
        depositAmount = depositAmount.div(1e16).mul(1e16);

        return (depositAmount, baseAmount, usdcAmount);
    }
}