// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IWoolf.sol";
import "./IForest.sol";
import "./Ownable.sol";

contract Utils is Ownable {
	IWoolf public woolf;
	IForest public forest;

	struct WolfGameInstance {
		IWoolf.ApeWolf apeWolf;
		string tokenURI;
	}

	struct Wolfs {
		uint256[] alpha0;
		uint256[] alpha1;
		uint256[] alpha2;
		uint256[] alpha3;
	}

	constructor(address _woolf, address _forest) {
		woolf = IWoolf(_woolf);
		forest = IForest(_forest);
	}

	function getMFList(uint256 startID, uint256 endID) public view returns (string[] memory) {
		string[] memory list = new string[](endID - startID);
		uint16 index = 0;
		for (uint256 i = startID; i < endID; i++) {
			list[index] = woolf.tokenURI(i);
			index++;
		}
		return list;
	}

	function getStatus(uint16 startIndex, uint16 endIndex) public view returns (uint16, uint16) {
		// uint256 count = woolf.totalSupply();
		uint16 wolfCount;
		uint16 apeCount;
		for (uint256 i = startIndex; i <= endIndex; i++) {
			if (woolf.getTokenTraits(i).isApe) {
				apeCount++;
			} else {
				wolfCount++;
			}
		}
		return (apeCount, wolfCount);
	}

	function getApeIDsByOwner(
		address owner,
		uint16 startIndex,
		uint16 endIndex
	) public view returns (uint256[] memory) {
		uint16 apeIndex = 0;
		uint256[] memory apeIDs = new uint256[](endIndex - startIndex);
		for (uint256 i = startIndex; i < endIndex; i++) {
			uint256 tokenId = woolf.tokenOfOwnerByIndex(owner, i);
			IWoolf.ApeWolf memory obj = woolf.getTokenTraits(tokenId);
			if (obj.isApe) {
				// apeIDs.length = 1;
				apeIDs[apeIndex] = tokenId;
				apeIndex++;
			}
		}
		return apeIDs;
	}

	function getWolfIDsByOwnerAndAlpha(
		address owner,
		uint16 startIndex,
		uint16 endIndex,
		uint16 alpha
	) public view returns (uint256[] memory) {
		uint16 wolfIndex = 0;
		uint256[] memory wolfIDs = new uint256[](endIndex - startIndex);
		for (uint256 i = startIndex; i < endIndex; i++) {
			uint256 tokenId = woolf.tokenOfOwnerByIndex(owner, i);
			IWoolf.ApeWolf memory obj = woolf.getTokenTraits(tokenId);
			if (!obj.isApe && alpha == obj.alphaIndex) {
				// apeIDs.length = 1;
				wolfIDs[wolfIndex] = tokenId;
				wolfIndex++;
			}
		}
		return wolfIDs;
	}

	function getStakeApeList(address owner, uint256[] memory IDs) public view returns (string[] memory) {
		string[] memory list = new string[](IDs.length);
		uint16 index = 0;
		for (uint256 i = 0; i < IDs.length; i++) {
			uint256 tokenId = IDs[i];
			if (forest.getForestStakeByID(tokenId).owner == owner) {
				list[index] = woolf.tokenURI(tokenId);
				index++;
			}
		}
		return list;
	}

	function getStakeWolfList(address owner, uint16 alpha ,uint256[] memory IDs) public view returns (string[] memory) {
		string[] memory list = new string[](IDs.length);
		uint16 index = 0;
		for (uint256 i = 0; i < IDs.length; i++) {
			uint256 tokenId = IDs[i];
			if (forest.getPackByAlphaAndID(alpha, tokenId).owner == owner) {
				list[index] = woolf.tokenURI(tokenId);
				index++;
			}
		}
		return list;
	}

	function getUnStakeListByOwner(
		address owner,
		uint16 startIndex,
		uint16 endIndex
	) public view returns (WolfGameInstance[] memory) {
		// uint256 count = woolf.balanceOf(owner);
		WolfGameInstance[] memory list = new WolfGameInstance[](endIndex - startIndex);
		uint16 index = 0;
		for (uint256 i = startIndex; i < endIndex; i++) {
			uint256 tokenId = woolf.tokenOfOwnerByIndex(owner, i);
			if (tokenId != 0) {
				list[index].apeWolf = woolf.getTokenTraits(tokenId);
				list[index].tokenURI = woolf.tokenURI(tokenId);
				index++;
			}
		}
		return list;
	}

	function setForest(address _forest) external onlyOwner {
		forest = IForest(_forest);
	}

	function setWoolf(address _woolf) external onlyOwner {
		woolf = IWoolf(_woolf);
	}
}