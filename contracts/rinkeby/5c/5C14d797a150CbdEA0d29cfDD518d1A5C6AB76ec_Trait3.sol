// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Face Color
contract Trait3 is TraitBase {
	constructor(address factory) TraitBase("Face Color", factory) {
		items.push(Item("face color 1", "#FFDAB6"));
		items.push(Item("face color 2", "#FFD2EA"));
		items.push(Item("face color 3", "#C5C5FF"));
		items.push(Item("face color 4", "#BBEFFF"));
		items.push(Item("face color 5", "#B3FFC7"));
		items.push(Item("face color 6", "#FFE98A"));
		items.push(Item("face color 7", "#FFFFFF"));
		itemCount = items.length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
	function owner() external view returns (address);
}

contract TraitBase {
	struct Item {
		string name;
		string content;
	}

	string public name;
	IFactory public factory;

	uint256 public itemCount;
	Item[] items;

	constructor(string memory _name, address _factory) {
		name = _name;
		factory = IFactory(_factory);
	}

	function getTraitName(uint16 traitId) external view returns (string memory traitName) {
		traitName = items[traitId].name;
	}

	function getTraitContent(uint16 traitId) external view returns (string memory traitContent) {
		traitContent = items[traitId].content;
	}

	function addItems(string[] memory names, string[] memory contents) external {
		require(msg.sender == factory.owner());
		require(names.length == contents.length);
		for (uint16 i = 0; i < names.length; i++) {
			items.push(Item(names[i], contents[i]));
		}
	}

	function setFactor(address _factory) external {
		require(msg.sender == factory.owner());
		factory = IFactory(_factory);
	}
}