// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Ear Wearing
contract Trait9 is TraitBase {
	constructor(address factory) TraitBase("Ear Wearing", factory) {
		items.push(Item("None", ""));
		items.push(
			Item(
				"Green Pearl",
				'<style>.ape1_z9{fill:#B3FFC7}</style><circle cx="212.58" cy="671.03" r="25" class="s ape1_z9"/><path d="M228.13,649.44c0,0,49.87-57.44,24.87-74.44" class="s e d"/><path d="M225.33,588.24c0,0-8.76,4.77-16.72,30.12" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Paper Clip",
				'<path d="M222,586l-16.6,59.84c-1.14,4.44-0.17,9.25,2.91,12.64c2.76,3.03,7.12,5.04,13.73,1.66c3.32-1.69,5.74-4.73,6.82-8.29c6.04-19.78,32.02-97.18,22.37-103.8" class="s e d"/><path d="M213,567l-26.14,88.38c-5.42,18.85,10.24,37.42,29.65,34.66c0.5-0.07,1-0.15,1.51-0.25c9.93-1.87,17.83-9.42,20.65-19.12L246,645" class="s e d"/>'
			)
		);
		items.push(Item("White Clips", '<circle cx="277.5" cy="599" r="34" class="s" style="fill:#FFFFFF"/>'));
		items.push(
			Item(
				"Yellow Hanging",
				'<style>.ape2_z9{fill:#FFE87A}</style><circle cx="283.5" cy="604" r="34" class="s ape2_z9"/><circle cx="283.63" cy="664" r="25" class="s ape2_z9"/><circle cx="281.98" cy="707.25" r="18.25" class="s ape2_z9"/>'
			)
		);
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