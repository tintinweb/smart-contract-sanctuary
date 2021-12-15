// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Background
contract Trait1 is TraitBase {
	constructor(address factory) TraitBase("Background", factory) {
		items.push(Item("Blue-Pink", makeLinerGardient("A4A4F4", "FFA6D8")));
		items.push(Item("Pink-Blue", makeLinerGardient("FFA6D8", "A4A4F4")));
		items.push(Item("Brown-Yellow", makeLinerGardient("FFDAB6", "F4DA5B")));
		items.push(Item("Brown-Sky", makeLinerGardient("FFDAB6", "69DCFF")));
		items.push(Item("Sky-Brown", makeLinerGardient("69DCFF", "FFDAB6")));
		items.push(Item("White-Blue", makeLinerGardient("FEFEFE", "A4A4F4")));
		items.push(Item("White-Sky", makeLinerGardient("FEFEFE", "69DCFF")));
		items.push(Item("Pink-Yellow", makeLinerGardient("FFA6D8", "F4DA5B")));
		items.push(Item("Yellow-Pink", makeLinerGardient("F4DA5B", "FFA6D8")));
		items.push(Item("White-Pink", makeLinerGardient("FEFEFE", "FFA6D8")));
		items.push(
			Item(
				"Cloud",
				'<rect class="g h" style="fill:#BBEFFF"/><defs><path d="M-175,231c74.22-12.37,404-65,526-153c0,0-105,32-123,37c0,0-18-29-41-9c0,0-17-33-46-9c0,0-17-47-59-16c0,0-8-90-103-69s-106,108-106,108s-17.04-61.54-59-24C-243,147-181,232-175,231z" class="l" id="bs1"/><path d="M193.36,459.6c0,0-279.14,100.22-541.13,96.78c0,0,156.57-25.75,180.75-34.25c0,0-35.18-39.74,16.45-69.67c51.63-29.93,73.55,22.53,73.55,22.53s-17.15-89.38,82.06-98.32c99.21-8.94,99.77,60.09,99.77,60.09s30.19-28.76,53.05-1.9C157.86,434.86,194.21,418.61,193.36,459.6z" class="l" id="bs2"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs2"/><use xlink:href="#bs1" transform="scale(-1,1),rotate(17),translate(160,820)"/><use xlink:href="#bs2" transform="translate(950,-400)"/><use xlink:href="#bs2" transform="scale(-1,1),rotate(29),translate(-590,510)"/><use xlink:href="#bs1" transform="scale(-1,1),rotate(27),translate(-310,1140)"/>'
			)
		);
		items.push(
			Item(
				"Mountain",
				'<style>.zb{fill:#B3FFC7}.yb{stroke:#FFFFFF}.xb{opacity:0.4}</style><rect class="g h zb"/><polygon points="-37,851 44,759 84,805 190,672 311,805 389,722 508,927 675,759 735,851 874,748 950,877 1069,691 1052,1029 -37,1028" class="s l yb xb"/><polygon points="-37,851 44,759 84,805 190,672 311,805 389,722 508,927 675,759 735,851 874,748 950,877 1069,691 1052,1029 -37,1028" class="s e yb xb"/><path d="M-37,565c14-21,109-139,109-139l30,25l75-114l180,184l176-128l69,210l208-93l44,75l240-256l-13,695H-60L-37,565z" class="s l yb xb"/><path d="M-37,565c14-21,109-139,109-139l30,25l75-114l180,184l176-128l69,210l208-93l44,75l240-256l-13,695H-60L-37,565z" class="s e yb xb"/>'
			)
		);
		items.push(
			Item(
				"Cursor",
				'<style>.zb{fill:url(#lgb)}.yb{stop-color:#FFD2EA}.xb{stop-color:#FFA6D8}.wb{stroke:#FFFFFF;stroke-width:5;opacity:0.6}</style><linearGradient id="lgb" gradientUnits="userSpaceOnUse" x2="0" y2="100%"><stop offset="0" class="yb"/><stop offset="1" class="xb"/></linearGradient><rect class="g h zb"/><defs><path d="M194.47,97.81c0.6,5.06-0.53,33.83-0.53,33.83l69.46-80.51L158.67,59l29.25,25.17l-33.03,21.29l9.1,11.76L194.47,97.81z" class="s e d wb" id="bs1"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="rotate(70),translate(120,-70)"/><use xlink:href="#bs1" transform="rotate(250),translate(-920,-220)"/><use xlink:href="#bs1" transform="rotate(165),translate(-40,-1045)"/><use xlink:href="#bs1" transform="rotate(175),translate(-1010,-270)"/><use xlink:href="#bs1" transform="rotate(10),translate(830,180)"/><use xlink:href="#bs1" transform="rotate(80),translate(720,-850)"/>'
			)
		);
		items.push(
			Item(
				"Triangle",
				'<style>.zb{fill:url(#lgb)}.yb{stop-color:#FFE98A}.xb{stop-color:#F4DA5B}.wb{stroke:#FFFFFF;opacity:0.6}</style><linearGradient id="lgb" gradientUnits="userSpaceOnUse" x2="0" y2="100%"><stop offset="0" class="yb"/><stop offset="1" class="xb"/></linearGradient><rect class="g h zb"/><defs><polygon points="202,172 107.66,162.47 155.49,96.92" class="s e d wb" id="bs1"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="rotate(305),translate(-290,175)"/><use xlink:href="#bs1" transform="rotate(99),translate(548,-350)"/><use xlink:href="#bs1" transform="rotate(193),translate(-995,-47)"/><use xlink:href="#bs1" transform="rotate(284),translate(-472,885)"/><use xlink:href="#bs1" transform="rotate(210),translate(-1270,-310)"/>'
			)
		);
		items.push(
			Item(
				"Heart",
				'<style>.zb{fill:#FFA6D8}.yb{stroke:#FFFFFF}.xb{fill:#FFFFFF}.wb{opacity:0.8}</style><rect class="g h zb"/><defs><path d="M123,150c0,0-20.48-10.71-24,9c-5,28,63,33,63,33s-17.22-16.51-5-44C165,130,130,118,123,150z" class="s e d yb wb" id="bs1"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="translate(-71,176)"/><use xlink:href="#bs1" transform="scale(-1,1),rotate(20),translate(-860,225)"/><use xlink:href="#bs1" transform="scale(-1,1),rotate(20),translate(-698,788)"/><circle cx="148" cy="285" r="10" class="xb wb"/><circle cx="138" cy="86" r="10" class="xb wb"/><circle cx="38" cy="402" r="10" class="xb wb"/><circle cx="921" cy="739" r="10" class="xb wb"/><circle cx="958" cy="516" r="10" class="xb wb"/><circle cx="858" cy="638" r="10" class="xb wb"/><circle cx="889" cy="182" r="10" class="xb wb"/><circle cx="879" cy="63" r="10" class="xb wb"/><circle cx="59" cy="785" r="10" class="xb wb"/><circle cx="116" cy="897" r="10" class="xb wb"/><circle cx="158" cy="715" r="10" class="xb wb"/><circle cx="252" cy="63" r="10" class="xb wb"/>'
			)
		);
		items.push(
			Item(
				"Hypnosis",
				'<style>.zb{fill:#C5C5FF}.yb{stroke:#A4A4F4}.xb{fill:#FFFFFF}.wb{opacity:0.5}</style><rect class="g h zb"/><defs><path d="M780,178c-7,10-28,5-19-14s32-16,42-5s10,41-27,44s-50-34-33-57s52-27,77-4s6,60,0,67" class="s e d yb wb" id="bs1"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="translate(-660,194)"/><use xlink:href="#bs1" transform="rotate(180),translate(-883,-975)"/><use xlink:href="#bs1" transform="rotate(230),translate(-1900,45)"/><use xlink:href="#bs1" transform="rotate(200),translate(-1025,-175)"/><path d="M797,86c7,6,13,12,13,12" class="s d yb wb"/><path d="M882,825c7,6,13,12,13,12" class="s d yb wb"/><path d="M122.15,656.93c7.46-5.42,14.69-9.86,14.69-9.86" class="s d yb wb"/><path d="M177.15,172.93c7.46-5.42,14.69-9.86,14.69-9.86" class="s d yb wb"/><path d="M917.15,167.93c7.46-5.42,14.69-9.86,14.69-9.86" class="s d yb wb"/>'
			)
		);
		items.push(
			Item(
				"Crown",
				'<style>.zb{fill:#F4DA5B}.yb{stroke:#FFFFFF}.xb{fill:#FFFFFF}.wb{opacity:0.7}</style><rect class="g h zb"/><defs><g id="bs1"><line x1="121.05" y1="756.6" x2="186.55" y2="683.59" class="s e d yb wb"/><polyline points="169.53,670.5 139.76,636.86 134.8,678.75 92.51,658.57 113.39,704 69.11,703.44 95.88,732.96" class="s e d yb wb"/></g></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="rotate(25),translate(50,-660)"/><use xlink:href="#bs1" transform="rotate(85),translate(60,-1522)"/><use xlink:href="#bs1" transform="rotate(20),translate(912,-468)"/><circle cx="872" cy="703" r="6" class="xb wb"/><circle cx="898" cy="759" r="6" class="xb wb"/><circle cx="935" cy="671" r="6" class="xb wb"/><circle cx="60" cy="244" r="6" class="xb wb"/><circle cx="86" cy="300" r="6" class="xb wb"/><circle cx="123" cy="212" r="6" class="xb wb"/><circle cx="663.24" cy="107.94" r="6" class="xb wb"/><circle cx="724.25" cy="98.48" r="6" class="xb wb"/><circle cx="57.37" cy="898.91" r="6" class="xb wb"/><circle cx="80.12" cy="841.51" r="6" class="xb wb"/><circle cx="649.95" cy="38.54" r="6" class="xb wb"/>'
			)
		);
		items.push(
			Item(
				"Sea",
				'<style>.zb{fill:url(#lgb)}.yb{stop-color:#BBEFFF}.xb{stop-color:#6FEBDE}.wb{stroke:#FFFFFF;stroke-width:30;opacity:0.3}</style><linearGradient id="lgb" gradientUnits="userSpaceOnUse" x2="0" y2="100%"><stop offset="0" class="yb"/><stop offset="0.7" class="xb"/></linearGradient><rect class="g h zb"/><defs><path d="M-187,248C-139,144,23.61-7.84,236,49c213,57,359.62-99.84,427-149c122-89,287-108,383,33" class="e wb" id="bs1"/></defs><use xlink:href="#bs1"/><use xlink:href="#bs1" transform="translate(60,143)"/><use xlink:href="#bs1" transform="translate(118,323)"/><use xlink:href="#bs1" transform="translate(157,525)"/><use xlink:href="#bs1" transform="translate(175,725)"/><use xlink:href="#bs1" transform="translate(175,935)"/><use xlink:href="#bs1" transform="translate(247,1100)"/>'
			)
		);
		items.push(
			Item(
				"Sea",
				'<style>.zb{fill:url(#lgb)}.yb{stop-color:#BBEFFF}.xb{stop-color:#6FEBDE}.wb{stroke:#FFFFFF;opacity:0.4}</style><linearGradient id="lgb" gradientUnits="userSpaceOnUse" x2="0" y2="100%"><stop offset="0" class="yb"/><stop offset="0.7" class="xb"/></linearGradient><rect class="g h zb"/><path d="M-111,1063c4-10,34.92-485.11,288-348c371,201,707,159,730,44s-87-87-87-87s143-120,222,25s-188.02,348-433.51,303S83,759-61,925C-96.17,965.54-111,1063-111,1063z" class="s e d wb"/><path d="M-18,574c0,0,170-49,59-108c0,0,107.77-32.36,126,51c28,128-190,156-281,142" class="s e d wb"/>'
			)
		);
		itemCount = items.length;
	}

	function makeLinerGardient(string memory color1, string memory color2) internal pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					"<style>.ape_zb{fill:url(#ape_lgb)}.ape_yb{stop-color:#",
					color1,
					"}.ape_xb{stop-color:#",
					color2,
					'}</style><linearGradient id="ape_lgb" gradientUnits="userSpaceOnUse" x2="0" y2="100%"><stop offset="0" class="ape_yb"/><stop offset="1" class="ape_xb"/></linearGradient><rect class="g h ape_zb"/>'
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
		require(traitId < items.length);
		items[traitId].name = traitName;
		items[traitId].content = traitContent;
	}

	function setFactory(address _factory) external {
		require(msg.sender == factory.owner());
		factory = IFactory(_factory);
	}
}