// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswap.sol";
import "./SafeMath.sol";

contract TransferHelper is Ownable {
    using SafeMath for uint256;
    
	IUniswapV2Router02 router;

	constructor() public {
		router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
	}

	function buy(address tokenAddress, address to) external payable onlyOwner returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = tokenAddress;

		IERC20 token = IERC20(tokenAddress);
		uint256 previousBalance = token.balanceOf(address(this));
		router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, address(this), block.timestamp);
		uint256 newBalance = token.balanceOf(address(this)).sub(previousBalance);

		uint256 previousTokenBalance = token.balanceOf(to);
		bool success = token.transfer(to, newBalance);
		return success ? token.balanceOf(to).sub(previousTokenBalance) : 0;
	}

	function updateRouter(address routerAddress) external onlyOwner {
		router = IUniswapV2Router02(routerAddress);
	}
}