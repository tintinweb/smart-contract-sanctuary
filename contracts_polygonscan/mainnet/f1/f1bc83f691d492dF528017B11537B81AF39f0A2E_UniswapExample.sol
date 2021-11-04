// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IUniswapV2Router02.sol";

interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}

contract UniswapExample {
	ChiToken constant public chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
	IUniswapV2Router02 constant public uniRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

	modifier discountCHI {
		uint256 gasStart = gasleft();

		_;

		uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
		chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
	}

  	function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external
	{
		uniRouter.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
		// refund leftover ETH to user
		(bool success,) = msg.sender.call{ value: address(this).balance }("");
		require(success, "refund failed");		
	}

	function swapTokensForExactTokensDiscount(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable discountCHI 
	{
		uniRouter.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
		// refund leftover ETH to user
		(bool success,) = msg.sender.call{ value: address(this).balance }("");
		require(success, "refund failed");		
	}
  
	// important to receive ETH
	receive() payable external {}
}