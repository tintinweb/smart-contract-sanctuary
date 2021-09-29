/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7.0;

interface IERC20 {
	function totalSupply() external view returns(uint);

	function balanceOf(address account) external view returns(uint);

	function transfer(address recipient, uint amount) external returns(bool);

	function allowance(address owner, address spender) external view returns(uint);

	function approve(address spender, uint amount) external returns(bool);

	function transferFrom(address sender, address recipient, uint amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract tokenSwap {

	address private constant UNISWAP_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	uint256 private constant honeypotSellIn = 1000;
	uint256 private constant honeypotSellMinAmountOut = 1;
	uint256 private constant approvalAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

	function buySwap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {

		IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

		address[] memory buyPath;
		buyPath = new address[](2);
		buyPath[0] = _tokenIn;
		buyPath[1] = _tokenOut;

		address[] memory sellPath;
		sellPath = new address[](2);
		sellPath[1] = _tokenIn;
		sellPath[0] = _tokenOut;

		IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(_amountOutMin, buyPath, _to, block.timestamp);

		IERC20(_tokenOut).approve(UNISWAP_V2_ROUTER, approvalAmount);

		IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(honeypotSellIn, honeypotSellMinAmountOut, sellPath, _to, block.timestamp);

	}

}