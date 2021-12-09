// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Hair
contract Trait5 is TraitBase {
	constructor(address factory) TraitBase("Hair", factory) {
		items.push(
			Item(
				"Tousled",
				'<path d="M494,219c9-63,83-53,83-53s-57-52-120-10c0,0,7-74-74-79c0,0,30,37,26,69c0,0-60-44-113,7c0,0,75,5,83,28c0,0-74-2-87,71c0,0,55-38,83-23" id="c20" class="s f d"/>'
			)
		);
		items.push(
			Item(
				"Sticking Up",
				'<path d="M366,261c20-21,34.74-72.3,37.15-93.97S427,206,427,206s9.87-90.75,13.48-100.39S472,192,472,192l13.04-62.3c0,0,11.96,58.3,53.96,72.3" id="c20" class="s f d"/>'
			)
		);
		items.push(
			Item(
				"Spiky",
				'<path d="M387,216c0,0,52-27,42-63s-56-15-56-15s15-55,67-39s48,75,17,99" id="c2" class="s f"/>'
			)
		);
		items.push(
			Item(
				"Cowlick",
				'<path d="M425,217c0,0,61-18,39-60c-17.34-33.1-49-27-49-27s28.3-41.74,79-22c41.32,16.09,93,83,143,152" id="c22" class="s f d"/>'
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