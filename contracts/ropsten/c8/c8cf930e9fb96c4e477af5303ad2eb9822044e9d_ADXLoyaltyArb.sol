// SPDX-License-Identifier: GPL-3.0


import "./IERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.6.0;



contract ADXLoyaltyArb is Ownable {

	IERC20 public constant UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
	IERC20 public constant DAI = IERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);


	function withdrawTokens(IERC20 token, uint amount) onlyOwner external {
		token.transfer(msg.sender, amount);
	}
}