// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NumberToString.sol";
import "./AddressToString.sol";
import "./Base64.sol";

contract StringUtils {
    function base64Encode(bytes memory data) external pure returns (string memory) {
        return Base64.encode(data);
    }

    function numberToString(uint256 value) external pure returns (string memory) {
        return NumberToString.numberToString(value);
    }

    function addressToString(address account) external pure returns(string memory) {
        return AddressToString.addressToString(account);
    }

    // This is quite inefficient, should be used only in read functions
    function split(string calldata str, string calldata delim) external pure returns(string[] memory) {
        uint numStrings = 1;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                numStrings += 1;
            }
        }

        string[] memory strs = new string[](numStrings);

        string memory current = "";
        uint strIndex = 0;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                strs[strIndex++] = current;
                current = "";
            } else {
                current = string(abi.encodePacked(current, bytes(str)[i]));
            }
        }
        strs[strIndex] = current;
        return strs;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library NumberToString {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    //Copied from Mad Dog Jones' replicator
    function numberToString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressToString {
    function addressToString(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

