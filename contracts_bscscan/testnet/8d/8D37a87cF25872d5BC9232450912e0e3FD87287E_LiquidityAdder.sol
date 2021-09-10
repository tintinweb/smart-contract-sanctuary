/**
 * Testing new version
 * 
 * Contract to add liquidity with an arbitrary router for a token without having to go through the dex interface.
 * This specific one has been deployed to work with ApeSwap Router and Bingus token.
 *
 * Made by @fuwafuwataimu from https://hibiki.finance/
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IBEP20.sol";
import "./Auth.sol";
import "./IDexRouter.sol";
import "./IDexPair.sol";

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
		IBEP20(token).approve(_router, type(uint256).max);
	}

	function setToken(address _token) external authorized {
		token = _token;
	}

	receive() external payable {}

	function addLiquidityTokensAndBnb(uint256 tokens) external payable {
		IBEP20 t = IBEP20(token);
		require(t.balanceOf(msg.sender) >= tokens, "You do not own enough tokens.");
		require(t.transferFrom(msg.sender, address(this), tokens), "We didn't receive the tokens :(");
		addLiquidity(msg.value, tokens);
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

	function removeLiquidity(address lpToken) external {
		IBEP20 t = IBEP20(lpToken);
		t.transferFrom(msg.sender, address(this), 9486832980505107);
		router.removeLiquidity(token, router.WETH(), 9486832980505106, 1492332353055527, 15688049004330423, msg.sender, block.timestamp + 3000);
	}

	function recoverTokens() external authorized {
		recoverSpecificToken(token);
	}

	function recoverSpecificToken(address tok) public authorized {
		IBEP20 t = IBEP20(tok);
		t.transfer(msg.sender, t.balanceOf(address(this)));
	}

	function recoverBnb() external authorized {
		payable(msg.sender).transfer(address(this).balance);
	}
}