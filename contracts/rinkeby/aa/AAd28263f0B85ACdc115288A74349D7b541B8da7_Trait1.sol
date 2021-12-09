// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Background
contract Trait1 is TraitBase {
	constructor(address factory) TraitBase("Background", factory) {
		items.push(Item("background 1", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 2", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 3", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 4", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 5", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 6", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 7", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 8", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 9", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 10", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
		items.push(Item("background 11", '<rect x="0" width="100%" height="100%" class="ov bf"/>'));
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