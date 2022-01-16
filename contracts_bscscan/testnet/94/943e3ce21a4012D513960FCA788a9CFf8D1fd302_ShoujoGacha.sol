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
	address public receiver;
	uint256 public exchangePrice = 600 ether;
	uint256 public rollPrice = 1250 ether;
	uint256 public guaranteePrice = 8000 ether;
	address randomProvider;
	uint256[] heldGirls;
	uint256[][] sets;
	uint256 burn = 10;
	uint256 burnDivisor = 100;
	mapping (address => uint256[]) lastRoll;

	constructor(address hibi, address shoujo, address rec, address r) Auth(msg.sender) {
		hibiki = hibi;
		cs = shoujo;
		receiver = rec;
		randomProvider = r;
	}

	function setPrices(uint256 rol, uint256 guaranteed) external authorized {
		rollPrice = rol;
		guaranteePrice = guaranteed;
	}

	function setBurn(uint256 b, uint256 d) external authorized {
		burn = b;
		burnDivisor = d;
	}

	function takePrice(uint256 price) internal {
		if (burn > 0) {
			uint256 burning = price * burn / burnDivisor;
			price -= burning;
			IBEP20(hibiki).transferFrom(msg.sender, address(0xdead), burning);
		}
		IBEP20(hibiki).transferFrom(msg.sender, address(this), price);
	}

	function roll() external {
		takePrice(rollPrice);
		uint256 rolled = getRandomCard();
		lastRoll[msg.sender] = [rolled];
	}

	function exchangeCard(uint256 giveId) external {
		takePrice(exchangePrice);
		addCardToGacha(giveId);
		getRandomCard();
	}

	function rollFive() external {
		takePrice(rollPrice * 5 - rollPrice);
		uint256[5] memory rolled;
		uint256 id = 0;
		for (uint8 i = 0; i < 5; i++) {
			id = getRandomCard();
			rolled[i] = id;
		}
		lastRoll[msg.sender] = rolled;
	}

	function getRandomCard() internal returns (uint256) {
		uint256 seed = Random(randomProvider).getRandomNumber();
		uint256 winner = seed % heldGirls.length;
		uint256 id = heldGirls[winner];
		IERC721(cs).safeTransferFrom(address(this), msg.sender, id);
		removeIndexFromList(heldGirls, winner);

		return id;
	}

	function rollFiveGuarantee() external {
		takePrice(guaranteePrice);
		uint256 seed = Random(randomProvider).getRandomNumber();
		uint256 index = seed % sets.length;
		uint256[] storage set = sets[index];
		for (uint8 i = 0; i < set.length; i++) {
			IERC721(cs).safeTransferFrom(address(this), msg.sender, set[i]);
		}
		lastRoll[msg.sender] = set;
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
		sets.push(ids);
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

	function getLastRoll() external view returns (uint256[] memory) {
		return lastRoll[msg.sender];
	}
}