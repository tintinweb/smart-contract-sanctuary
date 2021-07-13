// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IBTokenSwapper.sol';
import './IERC20.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';
import './SafeERC20.sol';
import './SafeMath.sol';
import './BTokenSwapper.sol';

// Swapper using only one pair
// E.g. swap (AAA for BBB) or (BBB for AAA) through pair AAABBB
contract BTokenSwapper1 is IBTokenSwapper, BTokenSwapper {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable router;
    address public immutable pair;
    bool    public immutable isBXToken0;
    uint256 public immutable liquidityLimitRatio;

    constructor (
        address router_,
        address pair_,
        address addressBX_,
        address addressB0_,
        bool isBXToken0_,
        uint256 maxSlippageRatio_,
        uint256 liquidityLimitRatio_
    ) BTokenSwapper(addressBX_, addressB0_, maxSlippageRatio_)
    {
        router = router_;
        pair = pair_;
        isBXToken0 = isBXToken0_;
        liquidityLimitRatio = liquidityLimitRatio_;

        IERC20(addressBX_).safeApprove(router_, type(uint256).max);
        IERC20(addressB0_).safeApprove(router_, type(uint256).max);
    }

    function getLimitBX() external override view returns (uint256) {
        uint256 reserve;
        if (isBXToken0) {
            (reserve, , ) = IUniswapV2Pair(pair).getReserves();
        } else {
            (, reserve, ) = IUniswapV2Pair(pair).getReserves();
        }
        return reserve.rescale(decimalsBX, 18) * liquidityLimitRatio / 10**18;
    }

    //================================================================================

    // estimate the tokenB0 amount needed to swap for `amountOutBX` tokenBX
    function _getAmountInB0(uint256 amountOutBX) internal override view returns (uint256) {
        uint256 reserveIn;
        uint256 reserveOut;
        if (isBXToken0) {
            (reserveOut, reserveIn, ) = IUniswapV2Pair(pair).getReserves();
        } else {
            (reserveIn, reserveOut, ) = IUniswapV2Pair(pair).getReserves();
        }
        return IUniswapV2Router02(router).getAmountIn(amountOutBX, reserveIn, reserveOut);
    }

    // estimate the tokenBX amount needed to swap for `amountOutB0` tokenB0
    function _getAmountInBX(uint256 amountOutB0) internal override view returns (uint256) {
        uint256 reserveIn;
        uint256 reserveOut;
        if (isBXToken0) {
            (reserveIn, reserveOut, ) = IUniswapV2Pair(pair).getReserves();
        } else {
            (reserveOut, reserveIn, ) = IUniswapV2Pair(pair).getReserves();
        }
        return IUniswapV2Router02(router).getAmountIn(amountOutB0, reserveIn, reserveOut);
    }

    // low-level swap function
    function _swapExactTokensForTokens(address a, address b, address to) internal override {
        address[] memory path = new address[](2);
        path[0] = a;
        path[1] = b;

        IUniswapV2Router02(router).swapExactTokensForTokens(
            IERC20(a).balanceOf(address(this)),
            0,
            path,
            to,
            block.timestamp + 3600
        );
    }

    // low-level swap function
    function _swapTokensForExactTokens(address a, address b, uint256 amount, address to) internal override {
        address[] memory path = new address[](2);
        path[0] = a;
        path[1] = b;

        IUniswapV2Router02(router).swapTokensForExactTokens(
            amount,
            IERC20(a).balanceOf(address(this)),
            path,
            to,
            block.timestamp + 3600
        );
    }

}