// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AddressLib} from "@devprotocol/util-contracts/contracts/utils/AddressLib.sol";
import {Base64} from "@devprotocol/util-contracts/contracts/utils/Base64.sol";
import {ISTokenManagerDescriptor} from "./interface/ISTokenManagerDescriptor.sol";
import {ISTokenManagerStruct} from "./interface/ISTokenManagerStruct.sol";

contract STokensDescriptor is ISTokenManagerDescriptor, ISTokenManagerStruct {
	using Base64 for bytes;
	using AddressLib for address;
	using Strings for uint256;

	function getTokenURI(StakingPositionV1 memory _position)
		external
		pure
		override
		returns (string memory)
	{
		string memory name = string(
			abi.encodePacked(
				"Dev Protocol sTokens - ",
				_position.property.toChecksumString(),
				" - ",
				_position.amount.toString(),
				" DEV",
				" - ",
				_position.cumulativeReward.toString()
			)
		);
		string memory description = string(
			abi.encodePacked(
				"This NFT represents a staking position in a Dev Protocol Property tokens. The owner of this NFT can modify or redeem the position.\\nProperty Address: ",
				_position.property.toChecksumString(),
				"\\n\\n\xE2\x9A\xA0 DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated."
			)
		);
		bytes memory image = bytes(
			abi
				.encodePacked(
					// solhint-disable-next-line quotes
					'<svg xmlns="http://www.w3.org/2000/svg" width="290" height="500" viewBox="0 0 290 500" fill="none"><rect width="290" height="500" fill="url(#paint0_linear)"/><path fill-rule="evenodd" clip-rule="evenodd" d="M192 203H168.5V226.5V250H145H121.5V226.5V203H98H74.5V226.5V250V273.5H51V297H74.5H98V273.5H121.5H145H168.5H192V250V226.5H215.5H239V203H215.5H192Z" fill="white"/><text fill="white" xml:space="preserve" style="white-space: pre" font-family="monospace" font-size="11" letter-spacing="0em"><tspan x="27.4072" y="333.418">',
					_position.property.toChecksumString(),
					// solhint-disable-next-line quotes
					'</tspan></text><defs><linearGradient id="paint0_linear" x1="0" y1="0" x2="290" y2="500" gradientUnits="userSpaceOnUse"><stop stop-color="#00D0FD"/><stop offset="0.151042" stop-color="#4889F5"/><stop offset="0.552083" stop-color="#D500E6"/><stop offset="1" stop-color="#FF3815"/></linearGradient></defs></svg>'
				)
				.encode()
		);
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					bytes(
						abi.encodePacked(
							// solhint-disable-next-line quotes
							'{"name":"',
							name,
							// solhint-disable-next-line quotes
							'", "description":"',
							description,
							// solhint-disable-next-line quotes
							'", "image": "',
							"data:image/svg+xml;base64,",
							image,
							// solhint-disable-next-line quotes
							'"}'
						)
					).encode()
				)
			);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

// see https://ethereum.stackexchange.com/questions/63908/address-checksum-solidity-implementation
library AddressLib {
	function toChecksumString(address account)
		internal
		pure
		returns (string memory asciiString)
	{
		// convert the account argument from address to bytes.
		bytes20 data = bytes20(account);

		// create an in-memory fixed-size bytes array.
		bytes memory asciiBytes = new bytes(40);

		// declare variable types.
		uint8 b;
		uint8 leftNibble;
		uint8 rightNibble;
		bool leftCaps;
		bool rightCaps;
		uint8 asciiOffset;

		// get the capitalized characters in the actual checksum.
		bool[40] memory caps = _toChecksumCapsFlags(account);

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i = 0; i < data.length; i++) {
			// locate the byte and extract each nibble.
			b = uint8(uint160(data) / (2**(8 * (19 - i))));
			leftNibble = b / 16;
			rightNibble = b - 16 * leftNibble;

			// locate and extract each capitalization status.
			leftCaps = caps[2 * i];
			rightCaps = caps[2 * i + 1];

			// get the offset from nibble value to ascii character for left nibble.
			asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

			// add the converted character to the byte array.
			asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset)[0];

			// get the offset from nibble value to ascii character for right nibble.
			asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

			// add the converted character to the byte array.
			asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset)[0];
		}

		return string(abi.encodePacked("0x", string(asciiBytes)));
	}

	function _toChecksumCapsFlags(address account)
		private
		pure
		returns (bool[40] memory characterCapitalized)
	{
		// convert the address to bytes.
		bytes20 a = bytes20(account);

		// hash the address (used to calculate checksum).
		bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

		// declare variable types.
		uint8 leftNibbleAddress;
		uint8 rightNibbleAddress;
		uint8 leftNibbleHash;
		uint8 rightNibbleHash;

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i; i < a.length; i++) {
			// locate the byte and extract each nibble for the address and the hash.
			rightNibbleAddress = uint8(a[i]) % 16;
			leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
			rightNibbleHash = uint8(b[i]) % 16;
			leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

			characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
				leftNibbleHash > 7);
			characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
				rightNibbleHash > 7);
		}
	}

	function _getAsciiOffset(uint8 nibble, bool caps)
		private
		pure
		returns (uint8 offset)
	{
		// to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
		if (nibble < 10) {
			offset = 48;
		} else if (caps) {
			offset = 55;
		} else {
			offset = 87;
		}
	}

	function _toAsciiString(bytes20 data)
		private
		pure
		returns (string memory asciiString)
	{
		// create an in-memory fixed-size bytes array.
		bytes memory asciiBytes = new bytes(40);

		// declare variable types.
		uint8 b;
		uint8 leftNibble;
		uint8 rightNibble;

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i = 0; i < data.length; i++) {
			// locate the byte and extract each nibble.
			b = uint8(uint160(data) / (2**(8 * (19 - i))));
			leftNibble = b / 16;
			rightNibble = b - 16 * leftNibble;

			// to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
			asciiBytes[2 * i] = bytes1(
				leftNibble + (leftNibble < 10 ? 48 : 87)
			)[0];
			asciiBytes[2 * i + 1] = bytes1(
				rightNibble + (rightNibble < 10 ? 48 : 87)
			)[0];
		}

		return string(asciiBytes);
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

// see https://github.com/Brechtpd/base64/blob/main/base64.sol
library Base64 {
	string internal constant TABLE =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function encode(bytes memory data) internal pure returns (string memory) {
		if (data.length == 0) return "";

		// load the table into memory
		string memory table = TABLE;

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((data.length + 2) / 3);

		// add some extra buffer at the end required for the writing
		string memory result = new string(encodedLen + 32);

		// solhint-disable-next-line no-inline-assembly
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
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(input, 0x3F))))
				)
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
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import {ISTokenManagerStruct} from "./ISTokenManagerStruct.sol";

interface ISTokenManagerDescriptor {
	/*
	 * @dev get toke uri from position information.
	 * @param _position The struct of positon information
	 */
	function getTokenURI(
		ISTokenManagerStruct.StakingPositionV1 memory _position
	) external pure returns (string memory);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

interface ISTokenManagerStruct {
	/*
	 * @dev Struct to declares a staking position.
	 * @param owner The address of the owner of the new staking position
	 * @param property The address of the Property as the staking destination
	 * @param amount The amount of the new staking position
	 * @param price The latest unit price of the cumulative staking reward
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param pendingReward The pending withdrawal reward amount amount
	 */
	struct StakingPositionV1 {
		address property;
		uint256 amount;
		uint256 price;
		uint256 cumulativeReward;
		uint256 pendingReward;
	}

	/*
	 * @dev Struct to customize token uri.
	 * @param isFreezed Whether the descriptor can be changed or not
	 * @param freezingUser Authors who have done the Freeze process
	 * @param descriptor File Contents
	 */
	struct DescriptorsV1 {
		bool isFreezed;
		address freezingUser;
		string descriptor;
	}
}