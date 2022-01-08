// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IWoolf.sol";
import "./IForest.sol";
import "./Ownable.sol";

contract Utils is Ownable {
	IWoolf woolf;
	IForest forest;

	struct WolfGameInstance {
		IWoolf.ApeWolf apeWolf;
		string tokenURI;
	}

	constructor(address _woolf, address _forest) {
		woolf = IWoolf(_woolf);
		forest = IForest(_forest);
	}

	function getStakeList(address owner) public view returns (WolfGameInstance[] memory) {
		IForest.Stake[] memory stakeList = forest.getStakeList(owner);
		WolfGameInstance[] memory list = new WolfGameInstance[](stakeList.length);

		for (uint256 i = 0; i < stakeList.length; i++) {
			list[i].tokenURI = woolf.tokenURI(stakeList[i].tokenId);
			list[i].apeWolf = woolf.getTokenTraits(stakeList[i].tokenId);
		}

		return list;
	}

	function getUnStakeList(address owner) public view returns (WolfGameInstance[] memory) {
		uint256 count = woolf.balanceOf(owner);
		WolfGameInstance[] memory list = new WolfGameInstance[](count);
		for (uint256 i = 0; i < count; i++) {
			uint256 tokenId = woolf.tokenOfOwnerByIndex(owner, i);
			list[i].apeWolf = woolf.getTokenTraits(tokenId);
			list[i].tokenURI = woolf.tokenURI(tokenId);
		}
		return list;
	}

	function getWoolfGameList(address owner) public view returns (WolfGameInstance[] memory list) {
		WolfGameInstance[] memory stakeList = getStakeList(owner);
		// WolfGameInstance[] memory unStakeList = getUnStakeList(owner);
		WolfGameInstance[] memory unStakeList;
		uint256 index = 0;
		for (uint256 i = 0; i < stakeList.length; i++) {
			list[index] = stakeList[i];
			index++;
		}
		for (uint256 i = 0; i < unStakeList.length; i++) {
			list[index] = unStakeList[i];
			index++;
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