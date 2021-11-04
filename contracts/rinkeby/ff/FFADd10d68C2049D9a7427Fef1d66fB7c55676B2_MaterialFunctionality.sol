//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './ItemTokenId.sol';
import './MaterialTokenId.sol';
import './Strings.sol';
import './Base64.sol';


library MaterialFunctionality {

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function materialTokenName(uint256 id) public pure returns (string memory) {
        (uint256[1] memory components, uint256 itemType) = MaterialTokenId.fromId(id);
        return materialItemName(itemType, components[0]);
    }  

    function materialItemName(uint256 itemType, uint256 idx) public pure returns (string memory) {
        
        string[7] memory gems = [
            'Amethyst',
            'Topaz',
            'Sapphire',
            'Emerald',
            'Ruby',
            'Diamond',
            'Skull'
        ];
        string[36] memory runes = [	
            'El Rune',
            'Eld Rune',
            'Tir Rune',	
            'Nef Rune',	
            'Ith Rune',	
            'Tal Rune',	
            'Ral Rune',	
            'Ort Rune',	
            'Thul Rune',	
            'Amn Rune',	
            'Shael Rune',	
            'Dol Rune',	
            'Hel Rune',	
            'Io Rune',	
            'Lum Rune',	
            'Ko Rune',	
            'Fal Rune',	
            'Lem Rune',	
            'Pul Rune',	
            'Um Rune',	
            'Mal Rune',	
            'Ist Rune',	
            'Gul Rune',	
            'Vex Rune',	
            'Lo Rune',	
            'Sur Rune',	
            'Ber Rune',	
            'Jah Rune',	
            'Cham Rune',	
            'Zod Rune',	
            'Eth Rune',	
            'Sol Rune',	
            'Ohm Rune',	
            'Avax Rune',	
            'Fantom Rune',	
            'Dot Rune'	
        ];	
        string[16] memory materials = [
            'Tin',
            'Iron',
            'Copper',
            'Bronze',
            'Silver',
            'Gold',
            'Leather Hide',
            'Silk',
            'Wool',
            'Obsidian',
            'Flametal',
            'Black Metal',
            'Dragon Skin',
            'Demon Hide',
            'Holy Water',
            'Force Crystals'
        ];
        
        string[34] memory charms = [
            'Arcing Charm',
            'Azure Charm',
            'Beryl Charm',
            'Bloody Charm',
            'Bronze Charm',
            'Burly Charm',
            'Burning Charm',
            'Chilling Charm',
            'Cobalt Charm',
            'Coral Charm',
            'Emerald Charm',
            'Entrapping Charm',
            'Fanatic Charm',
            'Fine Charm',
            'Forked Charm',
            'Foul Charm',
            'Hibernal Charm',
            'Iron Charm',
            'Jade Charm',
            'Lapis Charm',
            'Toxic Charm',
            'Amber Charm',
            'Boreal Charm',
            'Crimson Charm',
            'Ember Charm',
            'Ethereal Charm',
            'Flaming Charm',
            'Fungal Charm',
            'Garnet Charm',
            'Hexing Charm',
            'Jagged Charm',
            'Russet Charm',
            'Sanguinary Charm',
            'Tangerine Charm'
        ];

        string[7] memory tools = [
            'Anvil',
            'Fermenter',
            'Hanging Brazier',
            'Bronze Nails',
            'Adze',
            'Hammer',
            'Cultivator'
        ];

        string[12] memory elements = [		
            'Earth',		
            'Fire',		
            'Wind',		
            'Water',		
            'Mist',		
            'Shadow',		
            'Spirit',		
            'Power',		
            'Time',		
            'Infinity',		
            'Space',
            'Reality'		
        ];	

        string[7] memory requirements= [	
            'Strength',	
            'Intelligence',	
            'Wisdom',	
            'Dexterity',	
            'Constitution',	
            'Charisma',	
            'Mana'	
        ];

        
        
        
        if (itemType == 0x0) {
            return gems[idx];
        } else if (itemType == 0x1) {
            return runes[idx];
        } else if (itemType == 0x2) {
            return materials[idx];
        } else if (itemType == 0x3) {
            return charms[idx];
        } else if (itemType == 0x4) {
            return tools[idx];
        } else if (itemType == 0x5) {
            return elements[idx];
        } else if (itemType == 0x6) {
            return requirements[idx];
        } else {
            revert("Unexpected material item");
        }
    }

    function gemComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "GEM", 7);
    }

    function runeComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "RUNE", 35);
    }

    function materialComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "MATERIAL", 16);
    }

    function charmComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "CHARM", 34);
    }

    function toolComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "TOOL", 7);
    }

    function elementComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "ELEMENT", 12);
    }

    function requirementComponents(uint256 tokenId)
        public
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "REQUIREMENT", 7);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) public pure returns (uint256[1] memory) {
        uint256[1] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength;
        return components;
    }

    // View helpers for getting the item ID that corresponds to a bag's items
    function gemId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(gemComponents(tokenId), 0x0);
    }

    function runeId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(runeComponents(tokenId), 0x1);
    }

    function materialId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(materialComponents(tokenId), 0x2);
    }

    function charmId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(charmComponents(tokenId), 0x3);
    }

    function toolId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(toolComponents(tokenId), 0x4);
    }

    function elementId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(elementComponents(tokenId), 0x5);
    }

    function requirementId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(requirementComponents(tokenId), 0x6);
    }

    function _tokenURI(uint256 tokenId) public pure returns (string memory) {
        string[15] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = materialTokenName(gemId(tokenId));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = materialTokenName(runeId(tokenId));

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = materialTokenName(materialId(tokenId));

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = materialTokenName(charmId(tokenId));

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = materialTokenName(toolId(tokenId));

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = materialTokenName(elementId(tokenId));

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = materialTokenName(requirementId(tokenId));

        parts[14] = '</text></svg>';


        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "Material Bag #', Strings.toString(tokenId),'", ', 
                        '"description" : ', '"MaterialBag is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use MaterialBag in any way you want.", ',
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '", ' 
                        '"attributes": ', '[',
                                            '{',
                                                '"trait_type": "', 'Gem', '", ',
                                                '"value": "', parts[1], '"',
                                            '}',
                                            '{',
                                                '"trait_type": "', 'Rune', '", ',
                                                '"value": "', parts[3], '"',
                                            '}',
                                            '{',
                                                '"trait_type": "', 'Material', '", ',
                                                '"value": "', parts[5], '"',
                                            '}',
                                                                                        '{',
                                                '"trait_type": "', 'Charm', '", ',
                                                '"value": "', parts[7], '"',
                                            '}',
                                            '{',
                                                '"trait_type": "', 'Tool', '", ',
                                                '"value": "', parts[9], '"',
                                            '}',
                                            '{',
                                                '"trait_type": "', 'Element', '", ',
                                                '"value": "', parts[11], '"',
                                            '}',
                                                                                        '{',
                                                '"trait_type": "', 'Requirement', '", ',
                                                '"value": "', parts[13], '"',
                                            '}',
                                        ']',
                        '}'
                    )
                )
            )
        )));

        return output;
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;



library ItemTokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of Loot components and an item type (weapon, chest etc.)
    /// to a token id
    function toId(uint256[5] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[5] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/*
TOKEN ID FOR MATERIALS

Library to generate tokenIDs for different components, based on token type and attributes. 

*/

library MaterialTokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of CrafterLodge components and an item type (gem, rune etc.)
    /// to a token id
    function toId(uint256[1] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);

        return id;
    }

    /// Decodes a token id to an array of CrafterLodge components and an item type (gem, rune etc.) 
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[1] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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