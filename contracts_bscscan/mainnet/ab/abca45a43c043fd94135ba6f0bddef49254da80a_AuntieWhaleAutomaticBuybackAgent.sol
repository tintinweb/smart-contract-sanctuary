pragma solidity ^0.8.6;

// SPDX-License-Identifier: UNLICENSED

import "./IERC20.sol";
import "./IPancakeRouter.sol";
import "./Ownable.sol";

contract AuntieWhaleAutomaticBuybackAgent is Ownable {
	address constant DEAD_ADDRESS = address(57005);
	uint256 constant BUY_ROUNDS = 3;

	IPancakeRouter router;
	IERC20 token;

	bool isBuybackEnabled = false;

	uint256 buybackAmountMin = 0;
	uint256 buybackAmountMax = 0;
	uint256 public timesBought = 0;
	uint256 public amountSpent = 0;
	uint256 public amountBought = 0;

	uint256 public errorCount = 0;

	event BuybackOccured(uint256 amountIn, uint256 amountOut);

	constructor(address tokenAddress) {
		router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		token = IERC20(tokenAddress);
	}

	function getIsBuybackEnabled() public view returns (bool) {
		return isBuybackEnabled;
	}

	function setIsBuybackEnabled(bool isEnabled) public onlyOwner {
		isBuybackEnabled = isEnabled;
	}

	function setBuybackParameters(uint256 amountMin, uint256 amountMax) public onlyOwner {
		buybackAmountMin = amountMin;
		buybackAmountMax = amountMax;
	}

	function generateArbitraryNumber() private view returns (uint256) {
		// This will not generate a random number, but it doesn't matter for this use case.
		// All we need is for it to be somewhat arbitrary, it being deterministic doesn't matter for us.

		uint256 seed = uint256(keccak256(abi.encodePacked(
			block.timestamp + block.difficulty +
			((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
			block.gaslimit +
			((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
			block.number * (timesBought + 1)
		)));

		return 1 + (seed - ((seed / 10) * 10));
	}

	function getBuybackAmount() private view returns (uint256) {
		require(buybackAmountMin > 0, "Minimum buyback amount must be greater than zero.");
		require(buybackAmountMax > buybackAmountMin, "Maximum buyback amount must be greater than minimum buyback amount.");

		uint256 spread = buybackAmountMax - buybackAmountMin;
		return buybackAmountMin + (spread / generateArbitraryNumber());
	}

	function _swap(uint256 amountIn) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = address(token);

		uint256 initialTokenBalance = token.balanceOf(DEAD_ADDRESS);

		try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(0, path, DEAD_ADDRESS, block.timestamp) {
			return token.balanceOf(DEAD_ADDRESS) - initialTokenBalance;
		} catch {
			errorCount++;
			return 0;
		}
	}

	function _splitBuys(uint256 amountIn, uint256 chunks) private pure returns (uint256[] memory buys) {
		uint256 amount = 0;

		buys = new uint256[](chunks);

		for (uint256 i = 0; i < chunks; i++) {
			uint256 amountToBuy = i < (chunks - 1) ? amountIn / chunks : (amountIn - amount);
			amount += amountToBuy;
			buys[i] = amountToBuy;
		}

		return buys;
	}

	function buyback() public {
		require(msg.sender == address(token), "Only the token itself can initiate buyback.");
		require(isBuybackEnabled, "Buyback is disabled.");

		uint256 amountIn = getBuybackAmount();
		if (address(this).balance < amountIn) return;

		uint256 amountOut = 0;

		uint256[] memory buys = _splitBuys(amountIn, BUY_ROUNDS);

		for (uint256 i = 0; i < buys.length; i++) {
			if (buys[i] == 0) continue;

			uint256 out = _swap(buys[i]);

			if (out > 0) {
				amountOut += out;
			} else {
				return;
			}
		}

		timesBought++;
		amountSpent += amountIn;
		amountBought += amountOut;

		emit BuybackOccured(amountIn, amountOut);
	}

	receive() external payable {}
}