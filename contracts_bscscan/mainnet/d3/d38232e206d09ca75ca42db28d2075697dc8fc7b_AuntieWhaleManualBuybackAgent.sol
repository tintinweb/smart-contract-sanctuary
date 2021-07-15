pragma solidity ^0.8.6;

// SPDX-License-Identifier: UNLICENSED

import "./IERC20.sol";
import "./IPancakeRouter.sol";
import "./Ownable.sol";

contract AuntieWhaleManualBuybackAgent is Ownable {
	address constant DEAD_ADDRESS = address(57005);

	IPancakeRouter router;
	IERC20 token;

	uint256 public timesBought = 0;
	uint256 public amountSpent = 0;
	uint256 public amountBought = 0;

	event BuybackOccured(uint256 amountIn, uint256 amountOut);

	constructor(address tokenAddress) {
		router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		token = IERC20(tokenAddress);
	}

	function buyback(uint256 amountIn) public onlyOwner {
		require(amountIn >= address(this).balance, "Insufficient balance for buyback.");

		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = address(token);

		uint256 initialTokenBalance = token.balanceOf(DEAD_ADDRESS);
		router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(0, path, DEAD_ADDRESS, block.timestamp);
		uint256 amountOut = token.balanceOf(DEAD_ADDRESS) - initialTokenBalance;

		timesBought++;
		amountSpent += amountIn;
		amountBought += amountOut;

		emit BuybackOccured(amountIn, amountOut);
	}

	receive() external payable {}
}