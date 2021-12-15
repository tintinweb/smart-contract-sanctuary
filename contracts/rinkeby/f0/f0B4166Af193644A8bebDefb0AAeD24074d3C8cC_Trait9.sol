// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Ear Wearing
contract Trait9 is TraitBase {
	constructor(address factory) TraitBase("Ear Wearing", factory) {
		items.push(
			Item(
				"Green Pearl",
				'<style>.z9{fill:#B3FFC7}</style><circle cx="212.58" cy="671.03" r="25" class="s z9"/><path d="M228.13,649.44c0,0,49.87-57.44,24.87-74.44" class="s e d"/><path d="M225.33,588.24c0,0-8.76,4.77-16.72,30.12" class="s e d"/>'
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
				'<style>.z9{fill:#FFE87A}</style><circle cx="283.5" cy="604" r="34" class="s z9"/><circle cx="283.63" cy="664" r="25" class="s z9"/><circle cx="281.98" cy="707.25" r="18.25" class="s z9"/>'
			)
		);
		items.push(
			Item(
				"Yellow Cuff",
				'<style>.z9{fill:#F4DA5B}</style><path d="M195,583c0,0,9,39,34,56c35.18,23.92,37.36-27.93,37.36-27.93" class="s e d"/><path d="M195.16,583.3c-21.42-57.4,17.14-44.34,17.14-44.34c0.45-9.21,4.38-45.4,4.38-45.4c-28.59-10.51-38.57-14.75-45.36-2.97c-23.6,40.99,7.6,72.46,19.43,87.17C194.93,582.95,195.16,583.3,195.16,583.3z" class="s d z9"/><circle cx="274" cy="580" r="15" class="s d z9"/>'
			)
		);
		items.push(Item("Yellow Stud", '<circle cx="278" cy="575" r="15" class="s" style="fill:#FFE87A"/>'));
		items.push(
			Item(
				"Yellow Asterisk",
				'<polygon points="246.68,646.84 239.76,613.21 208.13,599.85 237.97,582.87 240.9,548.66 266.27,571.8 299.71,564.01 285.55,595.29 303.28,624.69 269.16,620.88" class="s d" style="fill:#F4DA5B"/>'
			)
		);
		items.push(
			Item(
				"Airpods",
				'<path d="M275.81,565.44C287.35,563,296,552.76,296,540.5c0-14.08-11.42-25.5-25.5-25.5S245,526.42,245,540.5c0,4.23,1.04,8.21,2.86,11.72c6.09,13.15,38.2,81.1,48.14,74.78C306.72,620.18,288.22,585.89,275.81,565.44z" class="s d" style="fill:#FFFFFF"/><line x1="268" y1="553" x2="276.06" y2="565.85" class="s d"/>'
			)
		);
		items.push(
			Item(
				"Green Big Ring",
				'<path d="M257,614c0,0-19.79,83.5-10,117c12.42,42.49,91.79,43.86,106-35c20-111-57-131-67-131s-18,16-1,22c41.43,14.62,38.12,52.71,22,104c-11,35-33.43,42.68-37,21c-5.44-33,2-95,2-95" class="s d" style="fill:#B3FFC7"/>'
			)
		);
		items.push(
			Item(
				"Yellow Crescent",
				'<path d="M257,614c0,0-26,57-8,89c32.38,57.56,108.02,37.23,120-42c13-86-57-93-67-93s-17.44,14.6-1,22c20,9,13.16,36.11,7,45c-9,13-29.76,14.14-34,0c-3-10-2-18-2-18" class="s d" style="fill:#F4DA5B"/><circle cx="278.5" cy="678.5" r="7.5"/><circle cx="315.5" cy="696.5" r="7.5"/><circle cx="330.5" cy="655.5" r="7.5"/>'
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