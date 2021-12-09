// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Eye Wearing
contract Trait7 is TraitBase {
	constructor(address factory) TraitBase("Eye Wearing", factory) {
		items.push(Item("None", ""));
		items.push(
			Item(
				"Sun Glass",
				'<style>.ape1_za{stop-color:#F4DA5B}.ape1_ya{stop-color:#FFA6D8}.ape1_xa{fill:url(#ape1_lg)}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d l"/><linearGradient id="ape1_lg" gradientUnits="userSpaceOnUse" x1="487.0388" y1="496.7828" x2="473.9402" y2="302.9131"><stop offset="0" class="ape1_za"/><stop offset="1" class="ape1_ya"/></linearGradient><circle cx="480.49" cy="399.85" r="97.15" class="s d ape1_xa"/><circle cx="746.64" cy="369.15" r="97.15" class="s d ape1_xa"/><path d="M547,388c0,0,51-54,123-16" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Thick-Rimmed",
				'<style>.ape2_za{stop-color:#A4A4F4}.ape2_ya{stop-color:#79E8B3}.ape2_xa{stop-color:#64B3FF}.ape2_wa{fill:url(#ape2_lg)}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d l"/><path d="M642,360c-47-6-71,11-71,11c0,5,1,25,1,25s32-18,70-13V360z" class="l"/><path d="M571,371c0,0,25-17,80-11" class="s e"/><path d="M571,396c0,0,41-19,82-11" class="s e"/><circle cx="480.49" cy="399.85" r="97.15" class="s l"/><linearGradient id="ape2_lg" gradientUnits="userSpaceOnUse" x1="412.483" y1="399.848" x2="548.4959" y2="399.848"><stop offset="0" class="ape2_za"/><stop offset="0.5" class="ape2_ya"/><stop offset="1" class="ape2_xa"/></linearGradient><circle cx="480.49" cy="399.85" r="68.01" class="s ape2_wa"/><circle cx="746.64" cy="369.15" r="97.15" class="s l"/><circle transform="translate(266.15,-30.7)" cx="480.49" cy="399.85" r="68.01" class="s ape2_wa"/>'
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