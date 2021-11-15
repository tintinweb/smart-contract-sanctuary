// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library LibMetadata {
    using Strings for uint256;

    function _capitalize(string memory _string)
        internal
        pure
        returns (string memory)
    {
        bytes memory _bytes = bytes(_string);
        if (_bytes[0] >= 0x61 && _bytes[0] <= 0x7A) {
            _bytes[0] = bytes1(uint8(_bytes[0]) - 32);
        }
        return string(_bytes);
    }

    function constructMetadata(
        string calldata _color,
        string calldata _object,
        uint256 _generation,
        string calldata _imageURI
    ) external pure returns (string memory metadata) {
        // Name
        metadata = string(
            abi.encodePacked(
                '{\n  "name": "',
                _capitalize(_color),
                " ",
                _capitalize(_object),
                '",\n'
            )
        );

        // Description
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "description": "Unique combos of basic colors and objects that form universally recognizable NFT identities. Visit hexo.codes to learn more.",\n'
            )
        );

        // Image URI
        metadata = string(
            abi.encodePacked(metadata, '  "image": "', _imageURI, '",\n')
        );

        // Attributes
        metadata = string(abi.encodePacked(metadata, '  "attributes": [\n'));
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "trait_type": "Color",\n      "value": "',
                _capitalize(_color),
                '"\n',
                "    },\n"
            )
        );
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "trait_type": "Object",\n      "value": "',
                _capitalize(_object),
                '"\n',
                "    },\n"
            )
        );
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "display_type": "number",\n      "trait_type": "Generation",\n      "value": ',
                _generation.toString(),
                "\n",
                "    }\n"
            )
        );
        metadata = string(abi.encodePacked(metadata, "  ]\n}"));
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

