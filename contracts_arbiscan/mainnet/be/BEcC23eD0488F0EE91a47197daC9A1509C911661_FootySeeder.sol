// SPDX-License-Identifier: GPL-3.0

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./Base64.sol";

import {IFootyDescriptor} from "./IFootyDescriptor.sol";

pragma solidity ^0.8.0;

interface IFootySeeder {
    struct FootySeed {
        uint256 background;
        uint256 kit;
        uint256 head;
        uint256 glasses;
        uint256 number;
    }

    function generateFootySeed(uint256 tokenId, IFootyDescriptor descriptor)
        external
        view
        returns (FootySeed memory);
}

contract FootySeeder is IFootySeeder {
    function generateFootySeed(uint256 tokenId, IFootyDescriptor descriptor)
        external
        view
        override
        returns (FootySeed memory)
    {
        uint256 pseudoRandom = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        uint256 headIndex;

        if ((pseudoRandom % 100) < 3) {
            headIndex = descriptor.getLegendaryHead(
                (pseudoRandom / 6) % descriptor.legendaryHeadCount()
            );
        } else if ((pseudoRandom % 100) < 15) {
            headIndex = descriptor.getRareHead(
                (pseudoRandom / 7) % descriptor.rareHeadCount()
            );
        } else {
            headIndex = descriptor.getCommonHead(
                (pseudoRandom / 8) % descriptor.commonHeadCount()
            );
        }

        return
            FootySeed({
                background: (pseudoRandom) % descriptor.backgroundCount(),
                kit: (pseudoRandom >> 96) % descriptor.kitCount(),
                head: headIndex,
                glasses: (pseudoRandom >> 144) % descriptor.glassesCount(),
                number: ((pseudoRandom >> 192) % 11) + 1
            });
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

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IFootySeeder} from "./IFootySeeder.sol";

interface IFootyDescriptor {
    function heads(uint256 index) external view returns (bytes memory);

    function colorCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function kitCount() external view returns (uint256);

    function commonHeadCount() external view returns (uint256);

    function rareHeadCount() external view returns (uint256);

    function legendaryHeadCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function getCommonHead(uint256 index) external view returns (uint256);

    function getRareHead(uint256 index) external view returns (uint256);

    function getLegendaryHead(uint256 index) external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(string[] calldata manyColors) external;

    function addManyBackgrounds(string[] calldata manyBackgrounds) external;

    function addManyKits(bytes[] calldata manyKits) external;

    function addManyCommonHeads(bytes[] calldata manyHeads) external;

    function addManyRareHeads(bytes[] calldata manyHeads) external;

    function addManyLegendaryHeads(bytes[] calldata manyHeads) external;

    function addManyGlasses(bytes[] calldata manyGlasses) external;

    function tokenURI(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        external
        view
        returns (string memory);

    function renderFooty(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IFootyDescriptor} from "./IFootyDescriptor.sol";

interface IFootySeeder {
    struct FootySeed {
        uint32 background;
        uint32 kit;
        uint32 head;
        uint32 glasses;
        uint32 number;
    }

    function generateFootySeed(uint256 tokenId, IFootyDescriptor descriptor)
        external
        view
        returns (FootySeed memory);
}