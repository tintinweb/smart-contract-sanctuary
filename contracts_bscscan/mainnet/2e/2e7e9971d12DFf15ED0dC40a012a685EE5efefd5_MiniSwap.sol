/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
	function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract MiniSwap {
	address public owner = msg.sender;
	address public CA;
	address public ROUTER;
	IRouter private IROUTER;
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	receive() external payable {}
	
	constructor(address router) {
		ROUTER = router;
		IROUTER = IRouter(ROUTER);
		CA = address(this);
	}
	
	function buy(address[] memory path, uint8 maxFee) external payable {
		require(msg.value > 0, "Broke");
		
		if (msg.sender == owner) {
			IERC20(path[0]).approve(ROUTER, msg.value);
			IROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(IROUTER.getAmountsOut(msg.value, path)[path.length - 1] * (100 - maxFee) / 100, path, CA, block.timestamp);
		}
	}
	
	function sell(address[] memory path, uint8 maxFee, uint16 percent) external onlyOwner {
		uint256 amountIn = IERC20(path[0]).balanceOf(CA) * percent / 1000;
		require(amountIn > 0, "Broke");
		
		IERC20(path[0]).approve(ROUTER, amountIn);
		IROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, IROUTER.getAmountsOut(amountIn, path)[path.length - 1] * (100 - maxFee) / 100, path, owner, block.timestamp);
	}
	
	function trade(address[] memory path, uint8 maxFee, uint256 amountIn) external onlyOwner {
		uint256 currentTokenBalance = IERC20(path[0]).balanceOf(CA);
		if (currentTokenBalance < amountIn) {
			IERC20(path[0]).transferFrom(msg.sender, CA, amountIn - currentTokenBalance); // This requires an approve before the tx.
			amountIn = IERC20(path[0]).balanceOf(CA);
		}
		require(amountIn > 0, "Broke");
		
		IERC20(path[0]).approve(ROUTER, amountIn);
		IROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, IROUTER.getAmountsOut(amountIn, path)[path.length - 1] * (100 - maxFee) / 100, path, CA, block.timestamp);
	}
	
	function transferOwnership(address new_owner) external onlyOwner {
		owner = new_owner;
	}
	
	function withdraw() external onlyOwner {
		payable(owner).transfer(CA.balance);
	}
	
	function withdrawToken(address token) external onlyOwner {
		IERC20(token).transfer(owner, IERC20(token).balanceOf(CA));
	}
}