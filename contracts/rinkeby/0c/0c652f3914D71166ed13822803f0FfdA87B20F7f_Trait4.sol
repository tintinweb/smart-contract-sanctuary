// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Clothe
contract Trait4 is TraitBase {
	constructor(address factory) TraitBase("Clothe", factory) {
		items.push(
			Item(
				"Rain Coat",
				'<g><style>.as1_z7{fill:#303030}.as1_y7{fill:#FFA6D8}</style><path d="M385,731c0,0,151,75,277-9l65,330l-386,5L385,731z" class="s as1_y7"/><g><path d="M409,627c-261,140-253,415-253,415l281,25L409,627z" class="s d as1_z7"/><path d="M432.5,617.5l-65.91,45.22c-10.05,6.89-10.66,21.5-1.23,29.21l90.57,93.59c8.15,8.42,13.24,19.32,14.47,30.97l27.08,255.78L354,1061c0,0-66.53-158.07-77.27-186.85c-10.74-28.78,52.77-51.65,46.77-67.65c-4.1-10.94-46-91-61-126C248.64,648.15,411.36,597.65,432.5,617.5z" class="s as1_z7"/></g><g><path d="M617,615l27,446l237-20C853,763,714.7,663.85,617,615C609,611,617,615,617,615" class="s as1_z7"/><path d="M599.64,617.74l65.91,45.22c10.05,6.89,10.66,21.5,1.23,29.21l-89.37,90.29c-8.36,8.45-13.6,19.48-14.88,31.29l-27.87,258.75L697,1058c0,0,47.67-154.82,58.41-183.6c10.74-28.78-52.77-51.65-46.77-67.65c4.1-10.94,46-91,61-126C783.51,648.4,620.78,597.9,599.64,617.74z" class="s as1_z7"/></g></g>'
			)
		);
		items.push(
			Item(
				"Long Sleeve T-Shirt",
				'<g><style>.as2_z7{fill:#FFFFFF}.as2_y7{fill:#A4A4F4}.as2_x7{fill:#F4DA5B}</style><path d="M795,1034c0,0,98-414-277-409c-377.97,5.04-276,414-276,414" class="s d as2_z7"/><g><path d="M299,690c0,0-101.77,102.83-134,201c-25.63,78.05-29,151-29,151l203-5l22-148" class="s d as2_z7"/></g><g><path d="M755,700c0,0,53.86,46.13,103,167c37,91,46,167,46,167H696l-22-146" class="s d as2_z7"/></g><path d="M293,1037l23-123l-193-16c0,0,71.73-229,215.37-228.5c0,0,185.63,173.5,350.13-8C725,655,835,693,896,873l-166,36l22,125L293,1037z" class="s d as2_y7"/><path d="M351,887c0,0-22,63-28,148" class="s e d"/><path d="M690,883c0,0,22,50,24,147" class="s e d"/><path d="M522,816c7.77,15.12,78-50,43,37c0,0,76,25,4,51c0,0,18,84-44,27c0,0-50,67-54-3c0,0-90,24-23-50c0,0-65.12-75,22.44-55C470.44,823,486,746,522,816z" class="s d as2_z7"/><circle cx="511" cy="873" r="31" class="s d as2_x7"/></g>'
			)
		);
		items.push(
			Item(
				"Hoody",
				'<g><style>.as3_z7{fill:#00FFEC}.as3_y7{fill:#FFFFFF}</style><path d="M793,1051c0,0,35.53-437.52-278-432c-297,5.23-265,430.95-265,430.95" class="s d as3_z7"/><g><path d="M371,857c17,122-34,194-34,194H111c0,0,18-255,176-370c64.25-46.76,57.55,106.58,213,97.35" class="s d as3_z7"/></g><g><path d="M533.09,774.45C699.88,747.17,698.55,637.31,721,662c40,44,198,150,186,389H769c0.01,0,5-124-44-208" class="s d as3_z7"/></g><path d="M526,798c126-1,186.69-50.58,236-74c40-19,30-63,0-63c0,0,17.93-81.64-65-63c0,0-18,94-154,118s-202-93-202-93s-84-15-78,58c0,0-56,0-46,50c6.45,32.26,50.68,20.87,89,30C381.6,779.02,480.19,798.36,526,798z" class="s d as3_z7"/><path d="M577.5,755.5c0,0,34,37,26,87s10,77,10,77" class="s e d"/><path d="M487.5,762.5c0,0-26,53,0,100c20.21,36.54,0,66,0,66" class="s e d"/><path d="M499.21,953.29c-4.87,12.33-13.7,10.46-23.21,6.71s-16.07-7.96-11.21-20.29s16.51-19.28,26.02-15.53C500.31,927.93,504.07,940.96,499.21,953.29z" class="s d as3_y7"/><path d="M638.02,917.25c6.63,11.48-1.17,16.64-10.02,21.75s-15.39,8.23-22.02-3.25c-6.63-11.48-4.83-24.93,4.02-30.03S631.39,905.77,638.02,917.25z" class="s d as3_y7"/></g>'
			)
		);
		items.push(
			Item(
				"Sweater",
				'<g><style>.as4_z7{fill:#64B3FF}.as4_y7{fill:#FFFFFF}.as4_x7{stroke:#FFFFFF}</style><path d="M793,1032c0,0,35.53-410.13-278-404.95c-297,4.9-265,403.97-265,403.97" class="s d as4_z7"/><path d="M366,944c0,0,146,64,288,0" class="s e d as4_x7"/><circle cx="406" cy="860" r="9" style="fill:#FFFFFF"/><circle cx="444" cy="923" r="9" style="fill:#FFFFFF"/><circle cx="502" cy="869" r="9" style="fill:#FFFFFF"/><circle cx="565" cy="923" r="9" style="fill:#FFFFFF"/><circle cx="616" cy="862" r="9" style="fill:#FFFFFF"/><g><path d="M349,836c13,124-34.18,196-34,196s-192.96,0-192.94,0c0.06,0-29.75-188.09,65-233c75.94-36,55-83,110-135s145,0,211,0" class="s d as4_z7"/></g><g><path d="M532.18,664c66,0,156-52,211,0s34.06,99,110,135c94.75,44.91,65.18,233,65,233c-0.06,0-197.89,0-198.18,0c0,0-45-60-33-196" class="s d as4_z7"/></g><path d="M371,785c0,0,113,99,286,12" class="s e d as4_x7"/><path d="M506,627c-76,1-171.84-52.99-180,47c-8,98,156,113,195,112s204-29,193-118S616.99,625.54,506,627z" class="s d as4_z7"/></g>'
			)
		);
		items.push(
			Item(
				"Jacket",
				'<g><style>.as5_z7{fill:#69DCFF}</style><path d="M790,1033c0,0,37.53-417.28-276-412c-297,5-265,412-265,412" class="s d as5_z7"/><g><path d="M320,685c-24-8-105,49-106,92c0,0-57,69-58,122c0,0-57,72-45,136l205.86-0.93C345,975,348,929,348,929" class="s d as5_z7"/><path d="M214,777c0,0,30,34,82,35" class="s e d"/><path d="M156,899c0,0,33,35,85,31" class="s e d"/></g><g><path d="M710.26,691c24-8,105,49,106,92c0,0,57,69,58,122c0,0,54,64,42,128H726c0-61-22-106-22-106" class="s d as5_z7"/><path d="M816,783c0,0-27,32-64,40" class="s e d"/><path d="M874,905c0,0-41,37-69,38" class="s e d"/></g><line x1="501" y1="750" x2="509.57" y2="1030.5" class="s e d"/><path d="M350.19,642C340,656,391,685,459,704c38.57,10.78,63,18.93,63,46c0,37-57,36-145,11s-109.86-110-38.93-143.5L350.19,642z" class="s d as5_z7"/><path d="M677,637c4,15-53,56-104,60s-83,13-83,34c0,39,0,85,164,19c135.54-54.55,56.1-134,34.05-132.5L677,637z" class="s d as5_z7"/></g>'
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