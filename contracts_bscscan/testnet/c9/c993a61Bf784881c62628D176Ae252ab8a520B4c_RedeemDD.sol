// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract RedeemDD is Context, Ownable {
	address public holdingAddress;
	IERC721 public token;
	mapping(address => uint256) public redeemable;
	uint256 public nextID;

	constructor(address tokenAddress, uint256 startID, address _holdingAddress, address[] memory accounts, uint256[] memory amounts) {
		token = IERC721(tokenAddress);
		require(token.ownerOf(startID) == _holdingAddress, "Holding address does not own startID.");
		nextID = startID;
		holdingAddress = _holdingAddress;
		for (uint i = 0; i < accounts.length; i++)
			redeemable[accounts[i]] = amounts[i];
	}

	function setNextID(uint256 id) public onlyOwner {
		nextID = id;
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

	function redeemSome(uint256 amount) public {
		require(amount > 0, "Nothing to redeem.");
		require(amount <= redeemable[_msgSender()], "Not enough available.");
		uint256 end = nextID + amount;
		uint256 id;
		for (id = nextID; id < end; id++)
			token.safeTransferFrom(holdingAddress, _msgSender(), id);
		nextID = id;
		redeemable[_msgSender()] -= amount;
	}
}