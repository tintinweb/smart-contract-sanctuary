// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts Curve LP Tokens to UNI LP Tokens
contract UniswapV2ProxyLogic {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory public constant factory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    UniswapRouterV2 public constant router = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getSwapAmt(uint256 amtA, uint256 resA)
        internal
        pure
        returns (uint256)
    {
        return
            sqrt(amtA.mul(resA.mul(3988000).add(amtA.mul(3988009))))
                .sub(amtA.mul(1997))
                .div(1994);
    }

    // https://blog.alphafinance.io/onesideduniswap/
    // https://github.com/AlphaFinanceLab/alphahomora/blob/88a8dfe4d4fa62b13b40f7983ee2c646f83e63b5/contracts/StrategyAddETHOnly.sol#L39
    // AlphaFinance is gripbook licensed
    function optimalOneSideSupply(
        IUniswapV2Pair pair,
        address from,
        address to
    ) public {
        address[] memory path = new address[](2);

        // 1. Compute optimal amount of WETH to be converted
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 rIn = pair.token0() == from ? r0 : r1;
        uint256 aIn = getSwapAmt(rIn, IERC20(from).balanceOf(address(this)));

        // 2. Convert that from -> to
        path[0] = from;
        path[1] = to;

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(address(router), aIn);

        router.swapExactTokensForTokens(aIn, 0, path, address(this), now + 60);
    }

    function swapUniswap(address from, address to) public {
        require(to != address(0));

        address[] memory path;

        if (from == weth || to == weth) {
            path = new address[](2);
            path[0] = from;
            path[1] = to;
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = weth;
            path[2] = to;
        }

        uint256 amount = IERC20(from).balanceOf(address(this));

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(address(router), amount);
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            now + 60
        );
    }

    function removeLiquidity(IUniswapV2Pair pair) public {
        uint256 _balance = pair.balanceOf(address(this));
        pair.approve(address(router), _balance);

        router.removeLiquidity(
            pair.token0(),
            pair.token1(),
            _balance,
            0,
            0,
            address(this),
            now + 60
        );
    }

    function supplyLiquidity(
        address token0,
        address token1
    ) public returns (uint256) {
        // Add liquidity to uniswap
        IERC20(token0).safeApprove(address(router), 0);
        IERC20(token0).safeApprove(
            address(router),
            IERC20(token0).balanceOf(address(this))
        );

        IERC20(token1).safeApprove(address(router), 0);
        IERC20(token1).safeApprove(
            address(router),
            IERC20(token1).balanceOf(address(this))
        );

        (, , uint256 _to) = router.addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            address(this),
            now + 60
        );

        return _to;
    }

    function refundDust(IUniswapV2Pair pair, address recipient) public {
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(token0).safeTransfer(
            recipient,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).safeTransfer(
            recipient,
            IERC20(token1).balanceOf(address(this))
        );
    }

    function lpTokensToPrimitive(
        IUniswapV2Pair from,
        address to
    ) public {
        if (from.token0() != weth && from.token1() != weth) {
            revert("!from-weth-pair");
        }

        address fromOther = from.token0() == weth ? from.token1() : from.token0();

        // Removes liquidity
        removeLiquidity(from);

        // Swap from WETH to other
        swapUniswap(weth, to);

        // If from is not to, we swap them too
        if (fromOther != to) {
            swapUniswap(fromOther, to);
        }
    }

    function primitiveToLpTokens(
        address from,
        IUniswapV2Pair to,
        address dustRecipient
    ) public {
        if (to.token0() != weth && to.token1() != weth) {
            revert("!to-weth-pair");
        }

        address toOther = to.token0() == weth ? to.token1() : to.token0();

        // Swap to WETH
        swapUniswap(from, weth);

        // Optimal supply from WETH to
        optimalOneSideSupply(to, weth, toOther);

        // Supply tokens
        supplyLiquidity(weth, toOther);

        // Dust
        refundDust(to, dustRecipient);
    }

    function swapUniLPTokens(
        IUniswapV2Pair from,
        IUniswapV2Pair to,
        address dustRecipient
    ) public {
        if (from.token0() != weth && from.token1() != weth) {
            revert("!from-weth-pair");
        }

        if (to.token0() != weth && to.token1() != weth) {
            revert("!to-weth-pair");
        }

        address fromOther = from.token0() == weth
            ? from.token1()
            : from.token0();

        address toOther = to.token0() == weth ? to.token1() : to.token0();

        // Remove weth-<token> pair
        removeLiquidity(from);

        // Swap <token> to WETH
        swapUniswap(fromOther, weth);

        // Optimal supply from WETH to <other-token>
        optimalOneSideSupply(to, weth, toOther);

        // Supply weth-<other-token> pair
        supplyLiquidity(weth, toOther);

        // Refund dust
        refundDust(to, dustRecipient);
    }
}
