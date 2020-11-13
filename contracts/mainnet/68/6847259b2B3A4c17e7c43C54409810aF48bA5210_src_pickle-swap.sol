// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./lib/erc20.sol";

import "./interfaces/uniswapv2.sol";

contract PickleSwap {
    using SafeERC20 for IERC20;

    UniswapRouterV2 router = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function convertWETHPair(
        address fromLP,
        address toLP,
        uint256 value
    ) public {
        IUniswapV2Pair fromPair = IUniswapV2Pair(fromLP);
        IUniswapV2Pair toPair = IUniswapV2Pair(toLP);

        // Only for WETH/<TOKEN> pairs
        if (!(fromPair.token0() == weth || fromPair.token1() == weth)) {
            revert("!eth-from");
        }
        if (!(toPair.token0() == weth || toPair.token1() == weth)) {
            revert("!eth-to");
        }

        // Get non-eth token from pairs
        address _from = fromPair.token0() != weth
            ? fromPair.token0()
            : fromPair.token1();

        address _to = toPair.token0() != weth
            ? toPair.token0()
            : toPair.token1();

        // Transfer
        IERC20(fromLP).safeTransferFrom(msg.sender, address(this), value);

        // Remove liquidity
        IERC20(fromLP).safeApprove(address(router), 0);
        IERC20(fromLP).safeApprove(address(router), value);
        router.removeLiquidity(
            fromPair.token0(),
            fromPair.token1(),
            value,
            0,
            0,
            address(this),
            now + 60
        );

        // Convert to target token
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = weth;
        path[2] = _to;

        IERC20(_from).safeApprove(address(router), 0);
        IERC20(_from).safeApprove(address(router), uint256(-1));
        router.swapExactTokensForTokens(
            IERC20(_from).balanceOf(address(this)),
            0,
            path,
            address(this),
            now + 60
        );

        // Supply liquidity
        IERC20(weth).safeApprove(address(router), 0);
        IERC20(weth).safeApprove(address(router), uint256(-1));

        IERC20(_to).safeApprove(address(router), 0);
        IERC20(_to).safeApprove(address(router), uint256(-1));
        router.addLiquidity(
            weth,
            _to,
            IERC20(weth).balanceOf(address(this)),
            IERC20(_to).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            now + 60
        );

        // Refund sender any remaining tokens
        IERC20(weth).safeTransfer(
            msg.sender,
            IERC20(weth).balanceOf(address(this))
        );
        IERC20(_to).safeTransfer(msg.sender, IERC20(_to).balanceOf(address(this)));
    }
}
