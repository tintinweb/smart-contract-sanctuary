// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
	function name() external view returns (string memory);

	function itemCount() external view returns (uint256);

	function getTraitName(uint16 traitId) external view returns (string memory);

	function getTraitContent(uint16 traitId) external view returns (string memory);
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

	// function encode(string memory _str) internal pure returns (string memory) {
	// 	bytes memory _bs = bytes(_str);
	// 	uint256 rem = _bs.length % 3;

	// 	uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
	// 	bytes memory res = new bytes(res_length);

	// 	uint256 i = 0;
	// 	uint256 j = 0;

	// 	for (; i + 3 <= _bs.length; i += 3) {
	// 		(res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(uint8(_bs[i]), uint8(_bs[i + 1]), uint8(_bs[i + 2]));

	// 		j += 4;
	// 	}

	// 	if (rem != 0) {
	// 		uint8 la0 = uint8(_bs[_bs.length - rem]);
	// 		uint8 la1 = 0;

	// 		if (rem == 2) {
	// 			la1 = uint8(_bs[_bs.length - 1]);
	// 		}

	// 		(bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
	// 		res[j] = b0;
	// 		res[j + 1] = b1;
	// 		if (rem == 2) {
	// 			res[j + 2] = b2;
	// 		}
	// 	}

	// 	return string(res);
	// }

	// function encode3(
	// 	uint256 a0,
	// 	uint256 a1,
	// 	uint256 a2
	// )
	// 	private
	// 	pure
	// 	returns (
	// 		bytes1 b0,
	// 		bytes1 b1,
	// 		bytes1 b2,
	// 		bytes1 b3
	// 	)
	// {
	// 	uint256 n = (a0 << 16) | (a1 << 8) | a2;

	// 	uint256 c0 = (n >> 18) & 63;
	// 	uint256 c1 = (n >> 12) & 63;
	// 	uint256 c2 = (n >> 6) & 63;
	// 	uint256 c3 = (n) & 63;

	// 	b0 = base64urlchars[c0];
	// 	b1 = base64urlchars[c1];
	// 	b2 = base64urlchars[c2];
	// 	b3 = base64urlchars[c3];
	// }

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
	using Base64 for *;

	ITrait[] public traits;

	constructor(address[] memory _traits) {
		require(traits.length == 0);
		for (uint8 i = 0; i < _traits.length; i++) {
			traits.push(ITrait(_traits[i]));
		}
	}

	function traitCount() external view returns (uint8) {
		return uint8(traits.length);
	}

	function itemCount(uint256 traitId) external view returns (uint256) {
		return traits[traitId].itemCount();
	}

	function tokenURI(
		uint256 tokenId,
		string memory name,
		uint256 tokenTrait
	) external view returns (string memory) {
		uint256 special = traits.length - 1;
		string memory attributes = '[{"';
		string[] memory pieces = new string[](special);

		uint256 traitHash = tokenTrait;
		uint16 specialTrait = uint16(traitHash & 0xFFFF);
		for (uint256 i = 0; i < special; i++) {
			traitHash = traitHash >> 16;
			uint256 traitType = special - i - 1;
			uint16 traitId = uint16(traitHash & 0xFFFF);
			attributes = string(
				abi.encodePacked(
					attributes,
					'trait_type":"',
					traits[traitType].name(),
					'","value":"',
					traits[traitType].getTraitName(traitId),
					'"},{"'
				)
			);
			pieces[traitType] = traits[traitType].getTraitContent(traitId);
		}
		attributes = string(
			abi.encodePacked(
				attributes,
				'trait_type":"',
				traits[special].name(),
				'","value":"',
				traits[special].getTraitName(specialTrait)
			)
		);
		attributes = string(abi.encodePacked(attributes, '"}]'));

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name":"Atopia - ',
							bytes(name).length > 0 ? name : tokenId.toString(),
							'","description":"Atopia description","image":"data:image/svg+xml;base64,',
							Base64.encode(
								abi.encodePacked(
									'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" id="_x31_" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">',
									".bf{fill:#FFA6D8;}",
									".ov{overflow:visible;}",
									".s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}",
									".d{stroke-linecap:round;}",
									".f{fill:",
									pieces[1],
									";}",
									".c{fill:",
									pieces[2],
									";}",
									".e{fill:none;}",
									"#c0,#c1,#c2,#a30,#a31,#b30,#b31 {",
									"position: relative;",
									"animation: hd 3s infinite;",
									"}",
									"#a40,#b40,#c50 {",
									"position: relative;",
									"animation: hd2 3s infinite;",
									"}",
									"@keyframes hd {",
									"0% { transform:translate(0,0) }",
									"40% { transform:translate(0,-7px) }",
									"100% { transform:translate(0,0) }",
									"}",
									"@keyframes hd2 {",
									"0% { transform:translate(0,0) }",
									"40% { transform:translate(0,-5px) }",
									"100% { transform:translate(0,0) }",
									"}",
									"@keyframes bd {",
									"0% { transform:scale(1) translate(0,0) }",
									"50% { transform:scale(1.03) translate(-15px,-30px) }",
									"100% { transform:scale(1) translate(0,0) }",
									"}",
									"</style>",
									pieces[0],
									'<path d="M794,1016c0,0-28.49-210.27-50.25-236.13S679,662,626,665s-216.3-32.26-258.65,10.37S297.19,749.4,269.6,810.2C242,871,206,1032,206,1032s460,10,474,11S794,1016,794,1016z" id="c60" class="s f"/><path d="M641.92,1013.92c0,0,33.83-239.66-93.1-235.25c-126.93,4.41-102.43,203.55-100.57,270.53S641.92,1013.92,641.92,1013.92z" id="c61" class="s c"><animateTransform attributeName="transform" dur="2s" type="scale" values="1;1.02;1" additive="sum" repeatCount="indefinite"/><animateTransform attributeName="transform" dur="2s" type="skewX" values="0;-0.8;0" additive="sum" repeatCount="indefinite"/><animateTransform attributeName="transform" dur="2s" type="skewY" values="0;-2;0" additive="sum" repeatCount="indefinite"/></path>',
									pieces[3],
									'<path d="M333,662c18,36,83,45.5,147,54c64.49,8.57,186.19-6.71,210-85c23.44-77.08-50.52-216.94-51-241c-1-50,0,0-2-61c-0.39-11.99,9-79-60-124c-75.23-49.06-201.25-29.84-266,59c-43,59-38,96-30,131c0,0,46.04,81.83,45,143C325,597,306.92,609.85,333,662z" id="c0" class="s f"/><path d="M615,241c-4.61-3.57-32-24-58-21c-60.73,7.01-58,55-58,55c-63-25-119,15-136,49s-34,131,87,170c0,0-137,68.8-43.75,183.3C428,704,470,713,470,713c83,24,225.54-24.31,282-109c14-21,31-58,24-105c-5.07-34.07-12-58-44-79c-30.62-20.09-62-21-93-30c-5.37-1.56,3-36,1-69C640,321,646,265,615,241z" id="c1" class="s c"/>',
									pieces[4],
									pieces[5],
									pieces[6],
									pieces[7],
									pieces[8],
									pieces[9],
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