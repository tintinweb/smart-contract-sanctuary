// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Eye Wearing
contract Trait7 is TraitBase {
	constructor(address factory) TraitBase("Eye Wearing", factory) {
		items.push(Item("None", ""));
		itemCount = items.length;
		items.push(
			Item(
				"Sun Glasses",
				'<style>.za{stop-color:#F4DA5B}.ya{stop-color:#FFA6D8}.xa{fill:url(#lg)}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d l"/><linearGradient id="lg" gradientUnits="userSpaceOnUse" x1="487.0388" y1="496.7828" x2="473.9402" y2="302.9131"><stop offset="0" class="za"/><stop offset="1" class="ya"/></linearGradient><circle cx="480.49" cy="399.85" r="97.15" class="s d xa"/><circle cx="746.64" cy="369.15" r="97.15" class="s d xa"/><path d="M547,388c0,0,51-54,123-16" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Thick Rimmed Glasses",
				'<style>.za{stop-color:#A4A4F4}.ya{stop-color:#79E8B3}.xa{stop-color:#64B3FF}.wa{fill:url(#lg)}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d l"/><path d="M642,360c-47-6-71,11-71,11c0,5,1,25,1,25s32-18,70-13V360z" class="l"/><path d="M571,371c0,0,25-17,80-11" class="s e"/><path d="M571,396c0,0,41-19,82-11" class="s e"/><circle cx="480.49" cy="399.85" r="97.15" class="s l"/><linearGradient id="lg" gradientUnits="userSpaceOnUse" x1="412.483" y1="399.848" x2="548.4959" y2="399.848"><stop offset="0" class="za"/><stop offset="0.5" class="ya"/><stop offset="1" class="xa"/></linearGradient><circle cx="480.49" cy="399.85" r="68.01" class="s wa"/><circle cx="746.64" cy="369.15" r="97.15" class="s l"/><circle transform="translate(266.15,-30.7)" cx="480.49" cy="399.85" r="68.01" class="s wa"/>'
			)
		);
		items.push(
			Item(
				"Magnifying Glasses",
				'<style>.ya{opacity:0.1}.xa{opacity:0.5}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d"/><circle cx="480.49" cy="399.85" r="97.15" class="l ya"/><circle cx="746.64" cy="369.15" r="97.15" class="l ya"/><path d="M398.46,451.92l144.99-126.05c0,0-69.21-54.92-129.43,3.13C358,383,398.46,451.92,398.46,451.92z" class="l xa"/><path d="M664.46,421.92l144.99-126.05c0,0-69.21-54.92-129.43,3.13C624,353,664.46,421.92,664.46,421.92z" class="l xa"/><circle cx="480.49" cy="399.85" r="97.15" class="s e"/><circle cx="746.64" cy="369.15" r="97.15" class="s e"/><path d="M576,377c0,0,31-27,73-8" class="s e d"/>'
			)
		);
		items.push(
			Item(
				"Aviator Glasses",
				'<style>.za{fill:#F4DA5B}</style><path d="M385,378c0,0-164,30-199,54c-19.32,13.25-16,30-3,36c9.08,4.19,26-3,32-30l169-21" class="s d"/><path d="M577,374c0,0,19-17,53-7" class="s e d"/><path d="M563,343c26,28,28,114-38,146s-139-9-142-88S527.28,304.53,563,343z" class="s za"/><path d="M407.8,419.29c-13.88-1.82,21.5,63.83,72.37,47.43C499.14,460.61,443.84,424,407.8,419.29z" class="l"/><path d="M635.9,333.5c-17.15,34.14,4.93,117.28,77.24,129.59s130.96-47.44,111.79-124.14C805.76,262.26,659.46,286.59,635.9,333.5z" class="s za"/><path d="M662.8,385.29c-13.88-1.82,21.5,63.83,72.37,47.43C754.14,426.61,698.84,390,662.8,385.29z" class="l"/>'
			)
		);
		items.push(
			Item(
				"Retro Glasses",
				'<style>.za{stop-color:#69DCFF}.ya{stop-color:#A4A4F4}.xa{stop-color:#FFA6D8}.wa{fill:url(#lg)}</style><path d="M384,417l-169,21c-6,27-22.92,34.19-32,30c-13-6-16.32-22.75,3-36c35-24,199-54,199-54" class="s d l"/><path d="M619,365c-32-2-35,2-35,2c0,8,8,24,8,24s21.88-4.39,26.44-2.69C623,390,619,365,619,365z" class="l"/><path d="M577,374c0,0,19-17,53-7" class="s e d"/><path d="M577,397c0,0,19-17,53-7" class="s e d"/><ellipse transform="matrix(0.9969 -0.0789 0.0789 0.9969 -29.9948 38.1686)" cx="468.18" cy="398.79" rx="123.91" ry="76.48" class="s l"/><linearGradient id="lg" gradientUnits="userSpaceOnUse" x1="476.4846" y1="457.2211" x2="459.8737" y2="340.3547"><stop offset="0" class="za"/><stop offset="0.5" class="ya"/><stop offset="1" class="xa"/></linearGradient><path d="M563.2,391.27c2.56,32.39-37.9,62.01-90.38,66.17c-52.48,4.15-97.1-18.74-99.66-51.13c-2.56-32.39,37.9-62.01,90.38-66.17C516.02,335.99,560.64,358.88,563.2,391.27z" class="s wa"/><ellipse transform="matrix(0.9969 -0.0789 0.0789 0.9969 -26.9871 59.59)" cx="740.86" cy="371.42" rx="123.91" ry="76.48" class="s l"/><path transform="translate(273,-27)" d="M563.2,391.27c2.56,32.39-37.9,62.01-90.38,66.17c-52.48,4.15-97.1-18.74-99.66-51.13c-2.56-32.39,37.9-62.01,90.38-66.17C516.02,335.99,560.64,358.88,563.2,391.27z" class="s wa"/>'
			)
		);
		items.push(
			Item(
				"Scifi Glasses",
				'<path d="M384,417l-169,21c-6,27-22.92,34.19-32,30c-13-6-16.32-22.75,3-36c35-24,199-54,199-54" class="s d l"/><path d="M573,375c-4.49,4.01,20.49-12.68,50-4" class="s e"/><path d="M490.5,446.5c-24,0-119.01-30.07-124.67-51.5c-3.24-12.27,1.33-25.42,9.78-27.98c38.63-11.69,144.31-18.69,184.15-12.19c8.71,1.42,14.97,13.86,13.38,26.45C570.35,403.26,514.5,446.5,490.5,446.5z" class="s"/><path d="M711.45,429.64c23.82-2.96,114.39-44.54,117.36-66.5c1.7-12.58-4.45-25.06-13.16-26.56c-39.78-6.84-145.52-0.73-184.24,10.63c-8.47,2.49-13.15,15.6-10.01,27.9C626.87,396.59,687.64,432.6,711.45,429.64z" class="s"/><circle cx="388" cy="386" r="14" class="l"/><circle cx="644" cy="364" r="14" class="l"/>'
			)
		);
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