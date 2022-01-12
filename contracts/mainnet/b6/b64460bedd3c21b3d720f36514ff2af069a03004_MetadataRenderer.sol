// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMetadataRenderer.sol";
import "./utils/Base64.sol";

contract MetadataRenderer is IMetadataRenderer {
    string public constant DESCRIPTION = "Synesthesia is a collaborative NFT art project in partnership with well-known generative artist @Hyperglu. Synesthesia enables users to use their Color NFTs to participant in the creation of new generative artworks.";
    string public constant UNREVEAL_IMAGE_URL = "https://www.synesspace.com/synesspace-unreveal.svg";

    function renderInternal(
        bytes memory tokenName,
        bytes memory imageURL,
        bytes memory attributes
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{"name":"', tokenName, '",',
                '"description":"', DESCRIPTION, '",',
                '"image":"', imageURL, '",',
                '"attributes":[', attributes, ']}'))));
    }

    function renderUnreveal(uint16 tokenId) external pure returns (string memory) {
        return renderInternal(
            abi.encodePacked("Synesthesia #", Strings.toString(tokenId)),
            bytes(UNREVEAL_IMAGE_URL),
            "");
    }

    function render(uint16 tokenId, Color memory color) external pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(abi.encodePacked(
                "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' width='512' height='512'><rect x='0' y='0' width='512' height='512' style='fill:#",
                color.rgb,
                "'/><rect x='0' y='376' width='512' height='50' style='fill:#FFFFFF;'/><text x='26' y='413' class='name-label' style='fill:#231815;font-family:Arial;font-weight:bold;font-size:32px;'>",
                color.name,
                "</text><text x='370' y='411' class='color-label' style='fill:#898989;font-family:Arial;font-weight:bold;font-style:italic;font-size: 28px;'>#",
                color.rgb,
                "</text></svg>")));

        bytes memory attributes = abi.encodePacked('{"trait_type":"Name","value":"', color.name, '"},{"trait_type":"RGB","value":"#', color.rgb, '"}');

        return renderInternal(
            abi.encodePacked(color.name, ' #', Strings.toString(tokenId)),
            svg,
            attributes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./colors/Color.sol";

interface IMetadataRenderer {
    function renderUnreveal(uint16 tokenId) external view returns (string memory);
    function render(uint16 tokenId, Color memory color) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Base64 {
    string constant private B64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = B64_ALPHABET;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            
            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Color {
    string rgb;
    string name;
}