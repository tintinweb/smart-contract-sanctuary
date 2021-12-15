// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
	function owner() external view returns (address);
}

contract TraitSpecial {
	string public constant name = "Special";
	IFactory public factory;

	uint256 public itemCount;
	string[] items;

	constructor(address _factory) {
		factory = IFactory(_factory);
		items.push("None");
		items.push("Furry");
		itemCount = items.length;
		items.push("Gang");
		items.push("Sports");
		items.push("Traveler");
		items.push("Adventurer");
		items.push("Model");
		items.push("Singer");
		items.push("Dancer");
		items.push("Engineer");
		items.push("Entrepreneur");
		items.push("General");
	}

	function totalItems() external view returns (uint256) {
		return items.length;
	}

	function getTraitName(uint16 traitId) external view returns (string memory traitName) {
		traitName = items[traitId];
	}

	function addTraits(string[] memory names) external {
		require(msg.sender == factory.owner());
		for (uint16 i = 0; i < names.length; i++) {
			items.push(names[i]);
		}
	}
}