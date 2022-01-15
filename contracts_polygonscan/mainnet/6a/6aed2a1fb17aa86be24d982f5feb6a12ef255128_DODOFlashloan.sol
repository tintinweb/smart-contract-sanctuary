/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

/*

    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;
// import {IERC20} from "./intf/IERC20.sol";
// import "./uniswap/IUniswapV2Router02.sol";

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
}


contract DODOFlashloan {

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

    function dodoBase(FlashParams memory params) public returns(address)
    {
        return IDODO(params.flashLoanPool)._QUOTE_TOKEN_();
    }

    function dodoFlashLoan(FlashParams memory params) external  {
        //Note: The data can be structured with any variables required by your logic. The following code is just an example
        bytes memory data = abi.encode(
            FlashCallbackData({
                me: msg.sender,
                flashLoanPool: params.flashLoanPool,
                loanAmount: params.loanAmount,
                firstRoutes: params.firstRoutes,
                secondRoutes: params.secondRoutes
            })
        );
    
        address loanToken = params.firstRoutes[0].path[0];
        address flashLoanBase = IDODO(params.flashLoanPool)._BASE_TOKEN_();
        // if(flashLoanBase == loanToken) {
        //     IDODO(params.flashLoanPool).flashLoan(params.loanAmount, 0, address(this), data);
        // } else {
        //     IDODO(params.flashLoanPool).flashLoan(0, params.loanAmount, address(this), data);
        // }
        IDODO(address(params.flashLoanPool)).flashLoan(params.loanAmount, 0, address(this), data);
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount,bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    function _flashLoanCallBack(address sender, uint256, uint256, bytes calldata data) internal {
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        //Note: Realize your own logic using the token from flashLoan pool.
        address loanToken = decoded.firstRoutes[0].path[0];
        require(
            IERC20(loanToken).balanceOf(address(this)) >= decoded.loanAmount,
            "Failed to borrow loan token"
        );

        for (uint256 i = 0; i < decoded.firstRoutes.length; i++) {
            uniswapV2(decoded.firstRoutes[i]);
        }

        for (uint256 i = 0; i < decoded.secondRoutes.length; i++) {
            uniswapV2(decoded.secondRoutes[i]);
        }

        emit SwapFinished(
            loanToken,
            IERC20(loanToken).balanceOf(address(this))
        );
        //Return funds
        require(
            IERC20(loanToken).balanceOf(address(this)) >= decoded.loanAmount,
            "Not enough amount to return loan"
        );
        IERC20(loanToken).transfer(decoded.flashLoanPool, decoded.loanAmount);

        // send all loanToken to msg.sender
        uint256 remained = IERC20(loanToken).balanceOf(address(this));
        IERC20(loanToken).transfer(decoded.me, remained);
        emit SentProfit(decoded.me, remained);
    }


    function uniswapV2(Route memory route) public returns(uint256[] memory) {
        route.router = IUniswapV2Router02(address(route.router));
		IERC20 tokenA = IERC20(address(route.path[0]));		
		uint256 amountIn = tokenA.balanceOf(address(this));
		require(tokenA.approve(address(route.router), amountIn), 'approve failed.');
        
        
		uint256[] memory amountOut = route.router.getAmountsOut(amountIn, route.path);
        require(tokenA.balanceOf(address(this)) > 0,"Token A in contract not Enough");
		return route.router.swapExactTokensForTokens(
			amountIn,
			amountOut[1],
			route.path,
			msg.sender,
			block.timestamp + 200
		);
	}
}

interface IUniswapV2Router02 {
 function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}