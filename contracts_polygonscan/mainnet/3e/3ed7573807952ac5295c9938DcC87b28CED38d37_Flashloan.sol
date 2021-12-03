// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

import "IUniswapV2Router02.sol";

import "IDODO.sol";
import "IDODOProxy.sol";

contract Flashloan {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event WithdrawToken(address recipient, uint256 amount);
    event SentProfit(address recipient, uint256 profit);
    event SwapFinished(address token, uint256 amount);

	struct Route {
		address[] path;
		IUniswapV2Router02 router;
	}

    struct FlashParams {
        address flashLoanPool;
        uint256 loanAmount;
        Route[] firstRoutes;
        Route[] secondRoutes;
    }

    struct FlashCallbackData {
        address me;
        address flashLoanPool;
        uint256 loanAmount;
        Route[] firstRoutes;
        Route[] secondRoutes;
    }

    function dodoFlashLoan(FlashParams memory params) external {
        bytes memory data = abi.encode(
            FlashCallbackData({
                me: msg.sender,
                flashLoanPool: params.flashLoanPool,
                loanAmount: params.loanAmount,
                firstRoutes: params.firstRoutes,
                secondRoutes: params.secondRoutes
            })
        );
        address flashLoanBase = IDODO(params.flashLoanPool)._BASE_TOKEN_();
        if (flashLoanBase == params.firstRoutes[0].path[0]) {
            IDODO(params.flashLoanPool).flashLoan(
                params.loanAmount,
                0,
                address(this),
                data
            );
        } else {
            IDODO(params.flashLoanPool).flashLoan(
                0,
                params.loanAmount,
                address(this),
                data
            );
        }
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address sender,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        address loanToken = decoded.firstRoutes[0].path[0];

        require(
            sender == address(this) && msg.sender == decoded.flashLoanPool,
            "HANDLE_FLASH_NENIED"
        );


        for (uint256 i = 0; i < decoded.firstRoutes.length; i++) {
            uniswapV2(decoded.firstRoutes[i]);
        }

        for (uint256 i = 0; i < decoded.secondRoutes.length; i++) {
            uniswapV2(decoded.secondRoutes[i]);
        }

        emit SwapFinished(loanToken, IERC20(loanToken).balanceOf(address(this)));

        require(
            IERC20(loanToken).balanceOf(address(this)) >=
                decoded.loanAmount,
            "Not enough amount to return loan"
        );
        //Return funds
        IERC20(loanToken).transfer(
            decoded.flashLoanPool,
            decoded.loanAmount
        );

        // send all loanToken to msg.sender
        uint256 remained = IERC20(loanToken).balanceOf(address(this));
        IERC20(loanToken).transfer(decoded.me, remained);
        emit SentProfit(decoded.me, remained);
    }

    function uniswapV2(
        Route memory route
    ) internal returns (uint256[] memory) {
        uint256 amountIn = IERC20(route.path[0]).balanceOf(address(this));
        require(
            IERC20(route.path[0]).approve(address(route.router), amountIn),
            "approve failed."
        );
        return
            route.router.swapExactTokensForTokens(
                amountIn,
                1,
                route.path,
                address(this),
                block.timestamp + 200
            );
    }
}