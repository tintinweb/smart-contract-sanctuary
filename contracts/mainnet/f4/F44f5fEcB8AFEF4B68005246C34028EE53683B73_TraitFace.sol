// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
	function owner() external view returns (address);
}

// Face
contract TraitFace {
	struct Item {
		string name;
		uint16 age;
		string content;
	}

	string public constant name = "Face";
	IFactory public factory;

	Item[] items;

	constructor(address _factory) {
		factory = IFactory(_factory);

		items.push(
			Item(
				"Baby",
				0,
				'<path d="M712,521c-0.65,22.91-4.38,44.93-11,65c-5.1,5.18-10.88,10.56-17.39,15.96c-10.79,8.93-21.29,15.99-30.77,21.55c-14.58,7.63-56.05,26.85-107.84,17.5c-61.08-11.04-94.96-54.34-108-71c0,0-53.93-72.01-37-199c7.3-54.76,48.75-76.3,66-83c37.56-14.59,128-22,162.51-20.82c7.73,0.26,15.27,2.08,19.41,8.61c9.41,14.81,18.31,31.73,26.08,49.21C700.35,384.34,713.89,454.46,712,521z" class="s c d"/>'
			)
		);
		items.push(
			Item(
				"Elder",
				2,
				'<path d="M712,521c-0.65,22.91-4.38,44.93-11,65c-6.86,6.99-23.46,23.06-48.16,37.5c-14.73,8.61-53.57,30.63-96.75,27.75C492.05,646.98,448.52,591.43,437,570c-43-80-39-184-37-199c7.3-54.76,48.75-76.3,66-83c43.3-16.82,99.8,19.13,127,1c36.7-24.46,30-15.67,47-25c12.31,17.26,24.08,38.68,34,61C700.35,384.34,713.89,454.46,712,521z" class="s c d"/>'
			)
		);
		items.push(
			Item(
				"Child",
				5,
				'<path d="M712,521c-0.65,22.91-4.38,44.93-11,65c-13.72,13.98-66.41,64.28-144.91,65.25c-22.24,0.28-69.96-1.1-109.09-38.25c-51.51-48.91-43.24-120.09-42-128c-3.61-4.76-34.16-55.06-14-116c15.94-48.17,50.42-69.76,63-76c62.68-31.07,132,1,135-1c36.7-24.46,34-18.67,51-28c12.31,17.26,24.08,38.68,34,61C700.35,384.34,713.89,454.46,712,521z" class="s c d"/>'
			)
		);
		items.push(
			Item(
				"Young",
				10,
				'<path d="M712,521c-0.65,22.91-5.38,46.93-12,67c-86.1,98.34-214,64-255,27c-50.14-45.25-33.88-121.26-29.8-137.07c0.47-1.81-0.04-3.73-1.35-5.07C359.52,417.57,379.96,324.59,454,293c58.38-24.91,106.46-1.95,127.73,13.22c5.11,3.64,12.34,1.41,14.45-4.5c4.4-12.33,20.28-30.22,44.81-36.73c12.31,17.26,23.08,36.68,33,59C700.35,383.34,713.89,454.46,712,521z" class="s c d"/>'
			)
		);
		items.push(
			Item(
				"Youth",
				15,
				'<path d="M712,521c-0.65,22.91-4.38,43.93-11,64c-86.1,98.34-215,67-256,30c-56.17-50.69-29-140-29-140c-57-55-37-150,38-182s133,15,139,23c0,0,6.34-41.22,47-52c12.31,17.26,24.08,38.68,34,61C700.35,384.34,713.89,454.46,712,521z" class="s c d"/>'
			)
		);
		string
			memory adultBase = '<path d="M712,521c-0.65,22.91-5.38,47.93-12,68c-86.1,98.34-213,63-254,26c-56.17-50.69-5-139-5-139c-88-49-61-151,14-183s133,15,139,23c0,0,4.34-42.22,45-53c12.31,17.26,25.08,40.68,35,63C700.35,385.34,713.89,454.46,712,521z" class="s c d"/>';
		items.push(Item("Adult", 20, adultBase));
		items.push(
			Item(
				"Old",
				30,
				string(abi.encodePacked(adultBase, '<path d="M578,341c0,0,25,7,42-7" class="s e d"/>'))
			)
		);
		items.push(
			Item(
				"Jr. Grand",
				40,
				string(abi.encodePacked(adultBase, '<path d="M562,344c0,0,44,12,63-11" class="s e d"/>'))
			)
		);
		items.push(
			Item(
				"The Grands",
				50,
				string(
					abi.encodePacked(
						adultBase,
						'<path d="M562,344c0,0,44,12,63-11" id="c11" class="s e d"/><path d="M579,371c0,0,30,11,46-8" class="s e d"/>'
					)
				)
			)
		);
	}

	function getTraitByAge(uint16 age) external view returns (uint16) {
		uint16 id = uint16(items.length - 1);
		for (; id >= 0; id--) {
			if (age >= items[id].age) {
				return id;
			}
		}
		return 0;
	}

	function getTraitName(uint16 traitId) external view returns (string memory traitName) {
		traitName = items[traitId].name;
	}

	function getTraitContent(uint16 traitId) external view returns (string memory traitContent) {
		traitContent = items[traitId].content;
	}

	function addItems(
		string[] memory names,
		uint16[] memory ages,
		string[] memory contents
	) external {
		require(msg.sender == factory.owner());
		require(names.length == ages.length);
		require(names.length == contents.length);
		for (uint16 i = 0; i < names.length; i++) {
			items.push(Item(names[i], ages[i], contents[i]));
		}
	}

	function updateItem(
		uint16 traitId,
		string memory traitName,
		uint16 age,
		string memory traitContent
	) external {
		require(traitId < items.length);
		items[traitId].name = traitName;
		items[traitId].age = age;
		items[traitId].content = traitContent;
	}

	function setFactory(address _factory) external {
		require(msg.sender == factory.owner());
		factory = IFactory(_factory);
	}
}