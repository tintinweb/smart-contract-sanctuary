// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Eyes
contract Trait6 is TraitBase {
	constructor(address factory) TraitBase("Eyes", factory) {
		items.push(Item("Black", '<circle cx="467.8" cy="414.72" r="23.12" id="a40" class="b"/><circle cx="760.88" cy="383.23" r="23.12" id="b40" class="b"/>'));
		items.push(Item("Big", '<circle cx="481.64" cy="400.89" r="36.95" id="a40" class="s e"/><circle cx="492.37" cy="405.65" r="17.65" id="a41" class="b"/><circle cx="762.64" cy="372.89" r="36.95" id="b40" class="s e"/><circle cx="773.37" cy="377.65" r="17.65" id="b41" class="b"/>'));
		items.push(Item("Glare", '<circle cx="481.64" cy="400.89" r="36.95" id="a40" class="b"/><circle cx="490.42" cy="388.31" r="8.42" id="a41" class="l"/><circle cx="762.64" cy="370.89" r="36.95" id="b40" class="b"/><circle cx="771.42" cy="358.31" r="8.42" id="b41" class="l"/>'));
		items.push(Item("Heart", '<path d="M522.05,459.55c0,0-117.05-30.55-93.35-83.3c21.16-47.1,67.02-8.52,67.02-8.52 s20.1-51.54,59.23-25.92C598.75,370.49,522.05,459.55,522.05,459.55z" id="a40" class="s d" fill="#FFA6D8"/><path d="M771.39,433.39c0,0-95.71-73.98-53.24-113.22c37.92-35.04,65,18.42,65,18.42 s38.69-39.54,64.65-0.64C876.86,381.51,771.39,433.39,771.39,433.39z" id="b40" class="s d" fill="#FFA6D8"/>'));
		items.push(Item("Inverted Heart", '<circle cx="493.68" cy="403.55" r="58" id="a40"/><path d="M483.88,376.3c0,0,54.22,11.15,44.66,35.83c-8.54,22.03-30.42,5.5-30.42,5.5s-7.95,24.03-26.44,13.26 C450.96,418.84,483.88,376.3,483.88,376.3z" id="a41" class="l"/><circle cx="777.99" cy="368" r="58" id="b40"/><path d="M780.36,339.05c0,0,46.1,30.65,27.99,49.95c-16.17,17.23-30.27-6.29-30.27-6.29s-16.37,19.31-29.49,2.4 C733.91,366.17,780.36,339.05,780.36,339.05z" id="b41" class="l"/>'));
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