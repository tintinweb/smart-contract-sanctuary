// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IGOOPsDescriptor} from './IGOOPsDescriptor.sol';
import {IGOOPsSeeder} from './IGOOPsSeeder.sol';
import {IGorfDecorator} from './IGorfDecorator.sol';
import {Base64} from 'base64-sol/base64.sol';
import {Strings} from './Strings.sol';

contract GoopMetadataProxy is IGOOPsDescriptor {
    using Strings for uint256;

    address public descriptorAddress = 0x53cB482c73655D2287AE3282AD1395F82e6a402F;
    IGOOPsDescriptor nounsDescriptor = IGOOPsDescriptor(descriptorAddress);

    address public decoratorAddress = 0x3753f5072FCFdd557085A199A7581aE56F8B991A;
    IGorfDecorator gorfDecorator = IGorfDecorator(decoratorAddress);

    function genericDataURI(string memory name, string memory description, IGOOPsSeeder.Seed memory seed) public view override returns (string memory) {
        string memory attributes = generateAttributesList(seed);
        string memory image = nounsDescriptor.generateSVGImage(seed);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name": "', name, '", "description": "', description, '", "attributes": [', attributes, '], "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    function generateAttributesList(IGOOPsSeeder.Seed memory seed) public view returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type":"Background","value":"', gorfDecorator.backgroundMapping(seed.background), '"},',
                '{"trait_type":"Body","value":"', gorfDecorator.bodyMapping(seed.body), '"},',
                '{"trait_type":"Accessory","value":"', gorfDecorator.accessoryMapping(seed.accessory), '"},',
                '{"trait_type":"Head","value":"', gorfDecorator.headMapping(seed.head), '"},',
                '{"trait_type":"Glasses","value":"', gorfDecorator.glassesMapping(seed.glasses), '"}'
            )
        );
    }

    function arePartsLocked() external override returns (bool) {return nounsDescriptor.arePartsLocked();}

    function isDataURIEnabled() external override returns (bool) {return nounsDescriptor.isDataURIEnabled();}

    function baseURI() external override returns (string memory) {return nounsDescriptor.baseURI();}

    function palettes(uint8 paletteIndex, uint256 colorIndex) external override view returns (string memory) {return nounsDescriptor.palettes(paletteIndex, colorIndex);}

    function backgrounds(uint256 index) external override view returns (string memory) {return nounsDescriptor.backgrounds(index);}

    function bodies(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.bodies(index);}

    function accessories(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.accessories(index);}

    function heads(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.heads(index);}

    function glasses(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.glasses(index);}

    function backgroundCount() external override view returns (uint256) {return nounsDescriptor.backgroundCount();}

    function bodyCount() external override view returns (uint256) {return nounsDescriptor.bodyCount();}

    function accessoryCount() external override view returns (uint256) {return nounsDescriptor.accessoryCount();}

    function headCount() external override view returns (uint256) {return nounsDescriptor.headCount();}

    function glassesCount() external override view returns (uint256) {return nounsDescriptor.glassesCount();}

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override {}

    function addManyBackgrounds(string[] calldata backgrounds) external override {}

    function addManyBodies(bytes[] calldata bodies) external override {}

    function addManyAccessories(bytes[] calldata accessories) external override {}

    function addManyHeads(bytes[] calldata heads) external override {}

    function addManyGlasses(bytes[] calldata glasses) external override {}

    function addColorToPalette(uint8 paletteIndex, string calldata color) external override {}

    function addBackground(string calldata background) external override {}

    function addBody(bytes calldata body) external override {}

    function addAccessory(bytes calldata accessory) external override {}

    function addHead(bytes calldata head) external override {}

    function addGlasses(bytes calldata glasses) external override {}

    function lockParts() external override {}

    function toggleDataURIEnabled() external override {}

    function setBaseURI(string calldata baseURI) external override {}

    function tokenURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.tokenURI(tokenId, seed);}

    function dataURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.dataURI(tokenId, seed);}

    function generateSVGImage(IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.generateSVGImage(seed);}
}

// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.6;

import { IGOOPsSeeder } from './IGOOPsSeeder.sol';

interface IGOOPsDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IGOOPsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IGOOPsSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.6;

import { IGOOPsDescriptor } from './IGOOPsDescriptor.sol';

interface IGOOPsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 GOOPId, IGOOPsDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { IGOOPsSeeder } from './IGOOPsSeeder.sol';

interface IGorfDecorator {
    function backgroundMapping(uint256) external view returns (string memory);
    function bodyMapping(uint256) external view returns (string memory);
    function accessoryMapping(uint256) external view returns (string memory);
    function headMapping(uint256) external view returns (string memory);
    function glassesMapping(uint256) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IGOOPsSeeder.Seed memory seed
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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