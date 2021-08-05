// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC20.sol';
import './IBTokenSwapper.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';
import './SafeERC20.sol';
import './SafeMath.sol';

contract BTokenSwapperAMUSDC is IBTokenSwapper {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant UONE = 1e18;

    // Matic token addresses
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant amUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
    uint256 constant DECIMALS = 6;

    // Quickswap addresses
    address constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant PAIR = 0x2cF7252e74036d1Da831d11089D326296e64a728; // USDC-USDT

    // AAVE proxy
    address constant PROXY = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;

    uint256 public immutable maxSlippageRatio;
    uint256 public immutable liquidityLimitRatio;

    constructor (uint256 maxSlippageRatio_, uint256 liquidityLimitRatio_) {
        maxSlippageRatio = maxSlippageRatio_;
        liquidityLimitRatio = liquidityLimitRatio_;

        IERC20(USDC).safeApprove(PROXY, type(uint256).max);
        IERC20(amUSDC).safeApprove(PROXY, type(uint256).max);

        IERC20(USDT).safeApprove(ROUTER, type(uint256).max);
        IERC20(USDC).safeApprove(ROUTER, type(uint256).max);
    }

    function getLimitBX() external override view returns (uint256) {
        (uint256 reserve, , ) = IUniswapV2Pair(PAIR).getReserves();
        return reserve.rescale(DECIMALS, 18) * liquidityLimitRatio / 10**18;
    }

    // swap exact `amountB0` amount of tokenB0 for tokenBX
    function swapExactB0ForBX(uint256 amountB0, uint256 referencePrice)
    external override returns (uint256 resultB0, uint256 resultBX)
    {
        address caller = msg.sender;

        uint256 bx1 = IERC20(amUSDC).balanceOf(caller);
        amountB0 = amountB0.rescale(18, DECIMALS);

        if (amountB0 == 0) return (0, 0);

        IERC20(USDT).safeTransferFrom(caller, address(this), amountB0);
        _swapExactTokensForTokens(USDT, USDC, address(this));
        IProxy(PROXY).deposit(USDC, IERC20(USDC).balanceOf(address(this)), caller, 0);
        uint256 bx2 = IERC20(amUSDC).balanceOf(caller);

        resultB0 = amountB0.rescale(DECIMALS, 18);
        resultBX = (bx2 - bx1).rescale(DECIMALS, 18);

        require(
            resultBX * referencePrice >= resultB0 * (UONE - maxSlippageRatio),
            'BTokenSwapper.swapExactB0ForBX: slippage exceeds allowance'
        );
    }

    // swap exact `amountBX` amount of tokenBX token for tokenB0
    function swapExactBXForB0(uint256 amountBX, uint256 referencePrice)
    external override returns (uint256 resultB0, uint256 resultBX)
    {
        address caller = msg.sender;

        uint256 b01 = IERC20(USDT).balanceOf(caller);
        amountBX = amountBX.rescale(18, DECIMALS);

        if (amountBX == 0) return (0, 0);

        IERC20(amUSDC).safeTransferFrom(caller, address(this), amountBX);
        IProxy(PROXY).withdraw(USDC, type(uint256).max, address(this));
        _swapExactTokensForTokens(USDC, USDT, caller);
        uint256 b02 = IERC20(USDT).balanceOf(caller);

        resultB0 = (b02 - b01).rescale(DECIMALS, 18);
        resultBX = amountBX.rescale(DECIMALS, 18);

        require(
            resultB0 * UONE >= resultBX * referencePrice / UONE * (UONE - maxSlippageRatio),
            'BTokenSwapper.swapExactBXForB0: slippage exceeds allowance'
        );
    }

    // swap max amount of tokenB0 `amountB0` for exact amount of tokenBX `amountBX`
    // in case `amountB0` is sufficient, the remains will be sent back
    // in case `amountB0` is insufficient, it will be used up to swap for tokenBX
    function swapB0ForExactBX(uint256 amountB0, uint256 amountBX, uint256 referencePrice)
    external override returns (uint256 resultB0, uint256 resultBX)
    {
        address caller = msg.sender;

        uint256 b01 = IERC20(USDT).balanceOf(caller);
        uint256 bx1 = IERC20(amUSDC).balanceOf(caller);

        amountB0 = amountB0.rescale(18, DECIMALS);
        amountBX = amountBX.rescale(18, DECIMALS);

        if (amountB0 == 0 || amountBX == 0) return (0, 0);

        IERC20(USDT).safeTransferFrom(caller, address(this), amountB0);
        if (amountB0 >= _getAmountInB0(amountBX) * 11 / 10) {
            _swapTokensForExactTokens(USDT, USDC, amountBX, address(this));
        } else {
            _swapExactTokensForTokens(USDT, USDC, address(this));
        }
        IProxy(PROXY).deposit(USDC, IERC20(USDC).balanceOf(address(this)), caller, 0);

        uint256 remainB0 = IERC20(USDT).balanceOf(address(this));
        if (remainB0 != 0) IERC20(USDT).safeTransfer(caller, remainB0);

        uint256 b02 = IERC20(USDT).balanceOf(caller);
        uint256 bx2 = IERC20(amUSDC).balanceOf(caller);

        resultB0 = (b01 - b02).rescale(DECIMALS, 18);
        resultBX = (bx2 - bx1).rescale(DECIMALS, 18);

        require(
            resultBX * referencePrice >= resultB0 * (UONE - maxSlippageRatio),
            'BTokenSwapper.swapB0ForExactBX: slippage exceeds allowance'
        );
    }

    // swap max amount of tokenBX `amountBX` for exact amount of tokenB0 `amountB0`
    // in case `amountBX` is sufficient, the remains will be sent back
    // in case `amountBX` is insufficient, it will be used up to swap for tokenB0
    function swapBXForExactB0(uint256 amountB0, uint256 amountBX, uint256 referencePrice)
    external override returns (uint256 resultB0, uint256 resultBX)
    {
        address caller = msg.sender;

        uint256 b01 = IERC20(USDT).balanceOf(caller);
        uint256 bx1 = IERC20(amUSDC).balanceOf(caller);

        amountB0 = amountB0.rescale(18, DECIMALS);
        amountBX = amountBX.rescale(18, DECIMALS);

        if (amountB0 == 0 || amountBX == 0) return (0, 0);

        if (amountBX >= amountB0 * 11 / 10) amountBX = amountB0 * 11 / 10;

        IERC20(amUSDC).safeTransferFrom(caller, address(this), amountBX);
        IProxy(PROXY).withdraw(USDC, type(uint256).max, address(this));
        _swapExactTokensForTokens(USDC, USDT, caller);

        uint256 b02 = IERC20(USDT).balanceOf(caller);
        uint256 bx2 = IERC20(amUSDC).balanceOf(caller);

        resultB0 = (b02 - b01).rescale(DECIMALS, 18);
        resultBX = (bx1 - bx2).rescale(DECIMALS, 18);

        require(
            resultB0 * UONE >= resultBX * referencePrice / UONE * (UONE - maxSlippageRatio),
            'BTokenSwapper.swapBXForExactB0: slippage exceeds allowance'
        );
    }

    // in case someone send tokenB0/tokenBX to this contract,
    // the previous functions might be blocked
    // anyone can call this function to withdraw any remaining tokenB0/tokenBX in this contract
    // idealy, this contract should have no balance for tokenB0/tokenBX
    function sync() external override {
        IERC20 tokenB0 = IERC20(USDT);
        IERC20 tokenBX = IERC20(amUSDC);
        if (tokenB0.balanceOf(address(this)) != 0) tokenB0.safeTransfer(msg.sender, tokenB0.balanceOf(address(this)));
        if (tokenBX.balanceOf(address(this)) != 0) tokenBX.safeTransfer(msg.sender, tokenBX.balanceOf(address(this)));
    }

    // estimate the tokenB0 amount needed to swap for `amountOutBX` tokenBX
    function _getAmountInB0(uint256 amountOutBX) internal pure returns (uint256) {
        return amountOutBX;
    }

    // estimate the tokenBX amount needed to swap for `amountOutB0` tokenB0
    function _getAmountInBX(uint256 amountOutB0) internal pure returns (uint256) {
        return amountOutB0;
    }

    // low-level swap function
    function _swapExactTokensForTokens(address a, address b, address to) internal {
        address[] memory path = new address[](2);
        path[0] = a;
        path[1] = b;

        IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            IERC20(a).balanceOf(address(this)),
            0,
            path,
            to,
            block.timestamp + 3600
        );
    }

    // low-level swap function
    function _swapTokensForExactTokens(address a, address b, uint256 amount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = a;
        path[1] = b;

        IUniswapV2Router02(ROUTER).swapTokensForExactTokens(
            amount,
            IERC20(a).balanceOf(address(this)),
            path,
            to,
            block.timestamp + 3600
        );
    }

}

interface IProxy {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external;
}