// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
	function name() external view returns (string memory);

	function itemCount() external view returns (uint256);

	function totalItems() external view returns (uint256);

	function getTraitName(uint16 traitId) external view returns (string memory);

	function getTraitContent(uint16 traitId) external view returns (string memory);

	function getTraitByAge(uint16 age) external view returns (uint16);

	function isOverEye(uint16 traitId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
	string private constant base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function encode(bytes memory data) internal pure returns (string memory) {
		if (data.length == 0) return "";

		// load the table into memory
		string memory table = base64stdchars;

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((data.length + 2) / 3);

		// add some extra buffer at the end required for the writing
		string memory result = new string(encodedLen + 32);

		assembly {
			// set the actual output length
			mstore(result, encodedLen)

			// prepare the lookup table
			let tablePtr := add(table, 1)

			// input ptr
			let dataPtr := data
			let endPtr := add(dataPtr, mload(data))

			// result ptr, jump over length
			let resultPtr := add(result, 32)

			// run over the input, 3 bytes at a time
			for {

			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)

				// read 3 bytes
				let input := mload(dataPtr)

				// write 4 characters
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
				resultPtr := add(resultPtr, 1)
			}

			// padding with '='
			switch mod(mload(data), 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}
		}

		return result;
	}

	function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/Base64.sol";
import "../interfaces/ITrait.sol";

contract AtopiaDrawer {
	address proxyImpl_;
	address public proxyAdmin_;

	bool public initialized;
	using Base64 for *;

	ITrait[] public traits;

	function initialize(address[] memory _traits) public {
		require(!initialized);
		initialized = true;
		for (uint16 i = 0; i < _traits.length; i++) {
			traits.push(ITrait(_traits[i]));
		}
	}

	function traitCount() external view returns (uint16) {
		return uint16(traits.length - 1);
	}

	function itemCount(uint256 traitId) external view returns (uint256) {
		return traits[traitId].itemCount();
	}

	function totalItems(uint256 traitId) external view returns (uint256) {
		return traits[traitId].totalItems();
	}

	function tokenURI(
		uint256 tokenId,
		string memory name,
		uint256 tokenTrait,
		uint16 age
	) external view returns (string memory) {
		string[] memory pieces = new string[](11);

		uint256 traitHash = tokenTrait;
		uint16 traitAge = traits[11].getTraitByAge(age);
		pieces[10] = traits[11].getTraitContent(traitAge);
		string memory attributes = string(
			abi.encodePacked(
				'[{"trait_type":"Age","value":"',
				age.toString(),
				'"},{"trait_type":"Face","value":"',
				traits[11].getTraitName(traitAge),
				'"},{"',
				'trait_type":"Special","value":"',
				traits[10].getTraitName(uint16(traitHash & 0xFFFF))
			)
		);

		bool hairFirst;
		bool eyeFirst;
		for (uint256 i = 0; i < 10; i++) {
			traitHash = traitHash >> 16;
			uint256 traitType = 10 - i - 1;
			uint16 traitId = uint16(traitHash & 0xFFFF);
			attributes = string(
				abi.encodePacked(
					attributes,
					'"},{"',
					'trait_type":"',
					traits[traitType].name(),
					'","value":"',
					traits[traitType].getTraitName(traitId)
				)
			);
			if (traitType == 4) {
				hairFirst = traitId < traits[4].itemCount();
			}
			if (traitType == 9) {
				eyeFirst = traits[9].isOverEye(traitId);
			}
			pieces[traitType] = traits[traitType].getTraitContent(traitId);
		}
		attributes = string(abi.encodePacked(attributes, '"}]'));

		string memory merged = string(
			abi.encodePacked(
				pieces[3],
				'<path d="M328.12,597.47C341.57,626.7,378.15,702.47,480,716c128,17,228.28-64.02,232-195c4-141-60-279-139-319c-80.13-40.57-208-26-265,68C270.51,331.83,252,432,328.12,597.47z" class="s f"/>',
				pieces[hairFirst ? 4 : 10],
				pieces[hairFirst ? 10 : 4],
				pieces[eyeFirst ? 5 : 9],
				pieces[eyeFirst ? 6 : 5],
				pieces[eyeFirst ? 9 : 6],
				pieces[7],
				pieces[8]
			)
		);

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name":"Atopia - ',
							bytes(name).length > 0 ? name : tokenId.toString(),
							'","description":"Atopia - 100% on-chain game. Grow2Earn game play.","image":"data:image/svg+xml;base64,',
							Base64.encode(
								abi.encodePacked(
									'<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="_x31_" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">.g{width:100%;height:100%}.h{overflow:visible;}.s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}.d{stroke-linecap:round;stroke-linejoin:round}.f{fill:',
									pieces[1],
									";}.c{fill:",
									pieces[2],
									";}.e{fill:none;}.l{fill:white;}.b{fill:black;}</style>",
									pieces[0],
									'<path d="M831,1013c0,35.87,0,66-1,98c-133-1-496,1-628,0c-2-32-1-56.8-1-86c0-233.62,154.7-422,311-422S831,779.38,831,1013z" class="s f"/><path d="M403,1054c7-200,65.57-254.15,134.1-255.66C598,797,663,858,671,1061" class="s c"/><path d="M363,841c0,0-55.12,80.63-51.19,244.87" class="s e d"/><path d="M666,831c0,0,69,84,61,254" class="s e d"/>',
									merged,
									"</svg>"
								)
							),
							'","attributes":',
							attributes,
							"}"
						)
					)
				)
			);
	}
}