// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC721.sol";

contract RedeemDD is Context {
	address public holdingAddress;
	IERC721 public token;
	mapping(address => uint256) public redeemable;
	uint256 nextID;

	constructor(address tokenAddress, address _holdingAddress, address[] memory accounts, uint256[] memory amounts) {
		token = IERC721(tokenAddress);
		holdingAddress = _holdingAddress;
		for (uint i = 0; i < accounts.length; i++)
			redeemable[accounts[i]] = amounts[i];
	}

	function redeem() public {
		uint256 amount = redeemable[_msgSender()];
		require(amount > 0, "Nothing to redeem.");
		uint256 end = nextID + amount;
		uint256 id;
		for (id = nextID; id < end; id++)
			token.safeTransferFrom(holdingAddress, _msgSender(), id);
		nextID = id;
		delete redeemable[_msgSender()];
	}
}