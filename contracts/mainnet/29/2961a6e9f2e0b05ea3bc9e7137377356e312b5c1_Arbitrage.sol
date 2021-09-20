// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './IUniswapV3FlashCallback.sol';
import './ISwapRouter.sol';
import './IUniswapV3Pool.sol';
import './IERC20Minimal.sol';

contract Arbitrage is IUniswapV3FlashCallback {
    struct InitOptions {
        address pool;
        address token;
        uint256 amount;

        address routerAddress;
        bytes path;
    }

    function init(InitOptions calldata options) external {
        IUniswapV3Pool pool = IUniswapV3Pool(options.pool);
        address token0 = pool.token0();

        pool.flash(
            address(this),
            token0 == options.token ? options.amount : 0,
            token0 == options.token ? 0 : options.amount,
            abi.encode(options)
        );
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        InitOptions memory options = abi.decode(data, (InitOptions));
        require(msg.sender == options.pool, 'Unauthorized');

        IERC20Minimal token = IERC20Minimal(options.token);
        token.approve(options.routerAddress, options.amount);

        ISwapRouter(options.routerAddress).exactInput(
            ISwapRouter.ExactInputParams(
                options.path,
                address(this),
                block.timestamp + 60,
                options.amount,
                0
            )
        );
        
        uint256 amountOwed = options.amount + fee0 + fee1;
        uint256 balanceOwed = token.balanceOf(address(this));

        require(balanceOwed >= amountOwed, 'Insufficient balance');
        token.transfer(options.pool, amountOwed);

        uint256 profit = balanceOwed - amountOwed;
        require(profit > 0, 'No profit');
        token.transfer(tx.origin, profit);
    }
}