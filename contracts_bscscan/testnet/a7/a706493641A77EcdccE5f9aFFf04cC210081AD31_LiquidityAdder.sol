/**
 * Contract to add liquidity with an arbitrary router for a token without having to go through the dex interface.
 * Made by @fuwafuwataimu from https://hibiki.finance/
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IBEP20.sol";
import "./Auth.sol";
import "./IDexRouter.sol";

contract LiquidityAdder is Auth {

	IDexRouter router;
	address public token;

	constructor(address _router, address _token) Auth(msg.sender) {
		router = IDexRouter(_router);
		token = _token;
		IBEP20(_token).approve(_router, type(uint256).max);
	}

	function setRouter(address _router) external authorized {
		router = IDexRouter(_router);
	}

	function setToken(address _token) external authorized {
		token = _token;
	}

	receive() external payable {}

	function addLiquidityWithBnb() external payable {
		uint256 buyBnb = msg.value / 2;
		IBEP20 t = IBEP20(token);
		uint256 balanceBefore = t.balanceOf(address(this));
		buyTokens(buyBnb);
		addLiquidity(msg.value - buyBnb, t.balanceOf(address(this)) - balanceBefore);
	}

	function addLiquidityWithTokens(uint256 tokens) external {
		IBEP20 t = IBEP20(token);
		require(t.balanceOf(msg.sender) >= tokens, "You do not own enough tokens.");
		require(t.transferFrom(msg.sender, address(this), tokens), "We didn't receive the tokens :(");
		uint256 balanceBefore = address(this).balance;
		uint256 tokensToSell = tokens / 2;
		sellTokens(tokensToSell);
		addLiquidity(address(this).balance - balanceBefore, tokens - tokensToSell);
	}

	function addLiquidityTokensAndBnb(uint256 tokens) external payable {
		IBEP20 t = IBEP20(token);
		require(t.balanceOf(msg.sender) >= tokens, "You do not own enough tokens.");
		require(t.transferFrom(msg.sender, address(this), tokens), "We didn't receive the tokens :(");
		addLiquidity(msg.value, tokens);
	}

	function buyTokens(uint256 bnb) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb} (
            0,
            path,
            address(this),
            block.timestamp
        );
    }

	function sellTokens(uint256 amount) internal {
		address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
	}

	function addLiquidity(uint256 bnb, uint256 tokens) internal {
		router.addLiquidityETH{value: bnb}(
			token,
			tokens,
			0,
			0,
			msg.sender,
			block.timestamp
		);
	}
}