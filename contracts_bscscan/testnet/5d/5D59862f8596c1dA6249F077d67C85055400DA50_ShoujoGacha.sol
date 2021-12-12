/**
 * Get your random Cryptoshoujo NFT to play the game!
 *
 * Cryptoshoujo (https://cryptoshoujo.io) is a collectibles NFT game by Hibiki finance.
 * Visit us at https://hibiki.finance/ or reach us at Telegram https://t.me/hibikifinance
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";
import "./IBEP20.sol";
import "./IERC721.sol";

interface Random {
    function getRandomNumber() external returns(uint256);
}

contract ShoujoGacha is Auth {

	address public hibiki;
	address public cs;
	uint256 public rollPrice;
	uint256 public guaranteePrice;
	address randomProvider;
	uint256[] heldGirls;
	uint256[][] sets;
	uint256 burn = 10;
	uint256 burnDivisor = 100;

	constructor(address hibi, address shoujo, address r) Auth(msg.sender) {
		hibiki = hibi;
		cs = shoujo;
		randomProvider = r;
	}

	function roll() external {
		IBEP20(hibiki).transferFrom(msg.sender, address(this), rollPrice);
		getRandomCard();
	}

	function rollFive() external {
		uint256 price = rollPrice * 5 - rollPrice;
		IBEP20(hibiki).transferFrom(msg.sender, address(this), price);
		for (uint8 i = 0; i < 5; i++) {
			getRandomCard();
		}
	}

	function getRandomCard() internal {
		uint256 seed = Random(randomProvider).getRandomNumber();
		uint256 winner = seed % heldGirls.length;
		IERC721(cs).safeTransferFrom(address(this), msg.sender, heldGirls[winner]);
		removeIndexFromList(heldGirls, winner);
	}

	function rollFiveGuarantee() external {
		uint256 seed = Random(randomProvider).getRandomNumber();
		uint256 index = seed % sets.length;
		uint256[] storage set = sets[index];
		for (uint8 i = 0; i < set.length; i++) {
			IERC721(cs).safeTransferFrom(address(this), msg.sender, set[i]);
		}
		removeIndexFromList(sets, index);
	}

	function getRandomId() internal returns(uint256) {
		uint256 seed = Random(randomProvider).getRandomNumber();
		return heldGirls[seed % heldGirls.length];
	}

	function addCardToGacha(uint256 id) public {
		IERC721(cs).safeTransferFrom(msg.sender, address(this), id);
		heldGirls.push(id);
	}

	function addCardsToGacha(uint256[] calldata ids) external {
		for (uint256 i = 0; i < ids.length; i++) {
			addCardToGacha(ids[i]);
		}
	}

	function addGuaranteedSet(uint256[] calldata ids) public {
		for (uint256 i = 0; i < ids.length; i++) {
			IERC721(cs).safeTransferFrom(msg.sender, address(this), ids[i]);
		}
	}

	function rescueCard(uint256 id) external authorized {
		IERC721(cs).safeTransferFrom(address(this), msg.sender, id);
	}
	
	function rescueToken(address t) external authorized {
		IBEP20 token = IBEP20(t);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return 0x150b7a02;
    }

	function removeFromList(uint256[] storage arr, uint256 n) internal {
		uint256 index = type(uint256).max;
		for (uint256 i = 0; i < arr.length; i++) {
			if (arr[i] == n) {
				index = i;
			}
		}

		if (index < type(uint256).max) {
			removeIndexFromList(arr, index);
		}
	}

	function removeIndexFromList(uint256[] storage arr, uint256 index) internal {
		arr[index] = arr[arr.length - 1];
		arr.pop();
	}

	function removeIndexFromList(uint256[][] storage arr, uint256 index) internal {
		arr[index] = arr[arr.length - 1];
		arr.pop();
	}

	function forceRemoveCardFromList(uint256 n) external authorized {
		removeFromList(heldGirls, n);
	}
}