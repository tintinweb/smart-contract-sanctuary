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