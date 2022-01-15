/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BirbRarity {

	address owner;
	mapping (uint256 => uint8) public idToRarity;
	mapping (uint8 => uint256[]) public rarityToIds;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	constructor() {
		owner = msg.sender;
	}

	function setRarityIds(uint8 rarity, uint256[] calldata ids) external onlyOwner {
		rarityToIds[rarity] = ids;
	}

	function setIdRarity(uint256 id, uint8 rarity) public onlyOwner {
		idToRarity[id] = rarity;
	}

	function setIdsRarities(uint256[] calldata id, uint8[] calldata rarities) public onlyOwner {
		require(id.length == rarities.length, "array mismatch");
		for (uint256 i = 0; i < id.length; i++) {
			setIdRarity(id[i], rarities[i]);
		}
	}

	function getIdRarity(uint256 id) external view returns (uint8) {
		return idToRarity[id];
	}

	function getRarityIds(uint8 rarity) external view returns (uint256[] memory) {
		return rarityToIds[rarity];
	}
}