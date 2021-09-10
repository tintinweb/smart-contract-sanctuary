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
	address public pair;

	constructor(address _router, address _token) Auth(msg.sender) {
		router = IDexRouter(_router);
		token = _token;
		pair = pairFor(router.factory(), token, router.WETH());
		IBEP20(_token).approve(_router, type(uint256).max);
		IBEP20(pair).approve(pair, type(uint256).max);
	}

	function setRouter(address _router) external authorized {
		router = IDexRouter(_router);
		IBEP20(token).approve(_router, type(uint256).max);
	}

	function setToken(address _token) external authorized {
		token = _token;
	}

	function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

	function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address _pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        _pair = address(uint160(uint256(keccak256(abi.encodePacked(
			hex'ff',
			factory,
			keccak256(abi.encodePacked(token0, token1)),
			hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074'
		)))));
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

	function removeLiquidity(uint256 amount) external {
		IDexPair t = IDexPair(pair);
		t.transferFrom(msg.sender, address(this), amount);
		t.sync();
		router.removeLiquidityETHSupportingFeeOnTransferTokens(
			token,
			amount,
			0,
			0,
			msg.sender,
			block.timestamp + 3000
		);
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