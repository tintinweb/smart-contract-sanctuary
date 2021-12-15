// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Body Color
contract Trait2 is TraitBase {
	constructor(address factory) TraitBase("Body Color", factory) {
		items.push(Item("Brown", "#FDA78B"));
		items.push(Item("Pink", "#F9BBDC"));
		items.push(Item("Blue", "#A4A4F4"));
		items.push(Item("Sky", "#69DCFF"));
		items.push(Item("Green", "#79E8B3"));
		items.push(Item("Yellow", "#F4DA5B"));
		items.push(Item("Black", "#4F4F4F"));
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

	function totalItems() external view returns (uint256) {
		return items.length;
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

	function updateItem(uint16 traitId, string memory traitName, string memory traitContent) external {
		require(msg.sender == factory.owner());
		require(traitId < items.length);
		items[traitId].name = traitName;
		items[traitId].content = traitContent;
	}

	function setFactory(address _factory) external {
		require(msg.sender == factory.owner());
		factory = IFactory(_factory);
	}
}