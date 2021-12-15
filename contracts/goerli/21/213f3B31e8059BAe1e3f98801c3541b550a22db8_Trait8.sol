// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Ears
contract Trait8 is TraitBase {
	constructor(address factory) TraitBase("Ears", factory) {
		items.push(
			Item(
				"Circle",
				'<path d="M355.43,565.9c-6,14.4-40.8,61.2-102,42c-54.73-17.17-68.4-124.8-5.4-159c60.73-32.97,88.2,10.2,88.2,10.2" class="s f d"/><path d="M271.43,501.1c13.2,1.2,43.2,8.4,36,46.8" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Bitten Off",
				'<path d="M355.43,565.9c-6,14.4-40.8,61.2-102,42c-20.25-6.35-34.88-25.09-42.08-47.9c-3.87-12.25-5.6-25.68-4.91-39c0.71-13.77,4.02-27.43,10.21-39.55c4.03-7.89,22.31,34.63,26.35,26.55c2.58-5.16,8.13-14.8,8-26c-0.17-14.82-6.28-31.3-2.97-33.1c60.73-32.97,88.2,10.2,88.2,10.2" class="s f d"/><path d="M271.43,501.1c13.2,1.2,43.2,8.4,36,46.8" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Sewn",
				'<path d="M355.43,565.9c-4.33,10.4-23.67,37.68-57.13,44.82C289.69,612.57,299,563,275,553c-16.84-7.02-30.33,51.45-34.28,48.89c-43.76-28.44-50.49-121.61,7.3-152.98c60.73-32.97,88.2,10.2,88.2,10.2" class="s f d"/><path d="M271.43,501.1c13.2,1.2,43.2,8.4,36,46.8" class="s e d"/><path d="M235,573c0,0,29,35,72,19" class="s e d"/><path d="M246,553c0,0,20,33,57,18" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Elf",
				'<path d="M355.43,565.9c-6,14.4-40.8,61.2-102,42c-25.66-8.05-45.49-35.97-49.43-66.9c-4.46-35.04-4-117,14-158c13,24,40,55,66.19,53.84c35.73-1.58,52.03,22.27,52.03,22.27" class="s f d"/><path d="M271.43,501.1c13.2,1.2,43.2,8.4,36,46.8" class="s e d"/>'
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
		require(traitId < items.length);
		items[traitId].name = traitName;
		items[traitId].content = traitContent;
	}

	function setFactory(address _factory) external {
		require(msg.sender == factory.owner());
		factory = IFactory(_factory);
	}
}