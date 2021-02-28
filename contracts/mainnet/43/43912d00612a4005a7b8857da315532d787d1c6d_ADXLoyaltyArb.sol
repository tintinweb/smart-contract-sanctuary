// SPDX-License-Identifier: GPL-3.0


import "./IERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.6.0;



contract ADXLoyaltyArb is Ownable {
	ISimpleUniswap public constant uniswap = ISimpleUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IERC20 public constant ADX = IERC20(0xADE00C28244d5CE17D72E40330B1c318cD12B7c3);
	IERC20 public constant ADXL = IERC20(0xd9A4cB9dc9296e111c66dFACAb8Be034EE2E1c2C);

	constructor() public {
		ADX.approve(address(uniswap), uint(-1));
		ADX.approve(address(ADXL), uint(-1));
		ADXL.approve(address(uniswap), uint(-1));
		ADXL.approve(address(ADXL), uint(-1));
	}

	// No need to check success here, no safeerc20
	function withdrawTokens(IERC20 token, uint amount) onlyOwner external {
		token.transfer(msg.sender, amount);
	}

	function tradeOnUni(address input, address output, uint amount) internal {
		address[] memory path = new address[](3);
		path[0] = input;
		// WETH
		path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
		path[2] = output;
		uniswap.swapExactTokensForTokens(amount, uint(0), path, address(this), block.timestamp);
	}

	function loyaltyTradesHigher(uint amountToSell) external {
		require(ADX.balanceOf(address(this)) == 0, 'must not have adx');
		uint initial = ADXL.balanceOf(address(this));
		// sell adx-loyalty on uniswap
		tradeOnUni(address(ADXL), address(ADX), amountToSell);
		// mint adx-loyalty with the ADX (profit adx-loyalty)
		ILoyaltyPool(address(ADXL)).enter(ADX.balanceOf(address(this)));
		// safety check
		require(ADXL.balanceOf(address(this)) > initial, 'did not make profit');
	}

	function loyaltyTradesLower(uint amountToBurn) external {
		require(ADX.balanceOf(address(this)) == 0, 'must not have adx');
		uint initial = ADXL.balanceOf(address(this));
		// burn adx-loyalty to receive adx
		ILoyaltyPool(address(ADXL)).leave(amountToBurn);
		// buy adx-loyalty with adx (profit adx-loyalty)
		tradeOnUni(address(ADX), address(ADXL), ADX.balanceOf(address(this)));
		// safety check
		require(ADXL.balanceOf(address(this)) > initial, 'did not make profit');
	}
}