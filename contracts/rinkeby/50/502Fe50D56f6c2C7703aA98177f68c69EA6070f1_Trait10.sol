// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Mouth
contract Trait10 is TraitBase {
	constructor(address factory) TraitBase("Mouth", factory) {
		items.push(
			Item(
				"Smiling",
				'<path d="M657,504c-39,29-95-4-95-31c0-23,24-20,37-14c13.83,6.38,26.07,8.86,39-6C658,430,702,470.54,657,504z" id="c50" class="s l"/><path d="M584,501c0,0,24-24,66,5C643.36,510.88,612,523,584,501z" id="c51" class="s" style="fill:#FFA6D8"/>'
			)
		);
		items.push(
			Item(
				"Stuck Tongue Down",
				'<path d="M619.68,469.18c0,0,7.42,30.36-18.78,34.74c-26.21,4.38-29.45-29.84-29.45-29.84" id="c50" class="s" style="fill:#FFA6D8"/><line x1="557.22" y1="473.98" x2="677.13" y2="461.44" id="c51" class="s d"/>'
			)
		);
		items.push(
			Item(
				"Cigarette",
				'<style>.ape1_zb{fill:#99503D}.ape1_yb{fill:#FFE98A}</style><path d="M633.33,469.28c25.99,14.17,5.18,47.16-14.7,55.76c-18.84,8.15-48.07-3.54-49.53-20.89" class="s e d"/><path d="M602.18,485.7c0,0,146.74,44.08,161.12,46.95c21.86,4.36,38.03-31.05,15.07-41.32c-22.96-10.27-160.46-27.49-160.46-27.49L602.18,485.7z" class="l"/><path d="M602.18,485.7c0,0,22.71,6.82,51.13,15.27c0,0,7.67-25.13,12.46-30.7c-26.91-3.81-47.86-6.43-47.86-6.43L602.18,485.7z" class="ape1_zb"/><path d="M765.05,529.59c22.3,7.86,37.57-31.59,13.32-38.26C763.28,487.18,757.69,526.99,765.05,529.59z" class="ape1_yb"/><path d="M602.18,485.7c0,0,146.74,44.08,161.12,46.95c21.86,4.36,38.03-31.05,15.07-41.32c-22.96-10.27-160.9-25.31-160.9-25.31" class="s e d"/><path d="M787.12,498.76c-22.74-28.41-42.17,46.14-10.92,31.92" class="s e d"/><path d="M665.44,471.88c0,0-14.35,9.43-8.42,30.2" class="s e d"/><path d="M658,453c0,0-58,0-65,47" class="s e d"/>'
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