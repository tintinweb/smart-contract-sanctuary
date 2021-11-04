//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './ItemTokenId.sol';
import './MaterialTokenId.sol';
import './Strings.sol';


library ItemFunctionality {

    
    function itemName(uint256 itemType, uint256 idx) public pure returns (string memory) {
        
        string[18] memory weapons = [
        "Warhammer", // 0
        "Quarterstaff", // 1
        "Maul", // 2
        "Mace", // 3
        "Club", // 4
        "Katana", // 5
        "Falchion", // 6
        "Scimitar", // 7
        "Long Sword", // 8
        "Short Sword", // 9
        "Ghost Wand", // 10
        "Grave Wand", // 11
        "Bone Wand", // 12
        "Wand", // 13
        "Grimoire", // 14
        "Chronicle", // 15
        "Tome", // 16
        "Book" // 17
    ];

    string[15] memory chestArmor = [
        "Divine Robe", // 0
        "Silk Robe", // 1
        "Linen Robe", // 2
        "Robe", // 3
        "Shirt", // 4
        "Demon Husk", // 5
        "Dragonskin Armor", // 6
        "Studded Leather Armor", // 7
        "Hard Leather Armor", // 8
        "Leather Armor", // 9
        "Holy Chestplate", // 10
        "Ornate Chestplate", // 11
        "Plate Mail", // 12
        "Chain Mail", // 13
        "Ring Mail" // 14
    ];
    string[15] memory headArmor = [
        "Ancient Helm", // 0
        "Ornate Helm", // 1
        "Great Helm", // 2
        "Full Helm", // 3
        "Helm", // 4
        "Demon Crown", // 5
        "Dragon's Crown", // 6
        "War Cap", // 7
        "Leather Cap", // 8
        "Cap", // 9
        "Crown", // 10
        "Divine Hood", // 11
        "Silk Hood", // 12
        "Linen Hood", // 13
        "Hood" // 14
    ];

    string[15] memory waistArmor = [
        "Ornate Belt", // 0
        "War Belt", // 1
        "Plated Belt", // 2
        "Mesh Belt", // 3
        "Heavy Belt", // 4
        "Demonhide Belt", // 5
        "Dragonskin Belt", // 6
        "Studded Leather Belt", // 7
        "Hard Leather Belt", // 8
        "Leather Belt", // 9
        "Brightsilk Sash", // 10
        "Silk Sash", // 11
        "Wool Sash", // 12
        "Linen Sash", // 13
        "Sash" // 14
    ];

    string[15] memory footArmor = [
        "Holy Greaves", // 0
        "Ornate Greaves", // 1
        "Greaves", // 2
        "Chain Boots", // 3
        "Heavy Boots", // 4
        "Demonhide Boots", // 5
        "Dragonskin Boots", // 6
        "Studded Leather Boots", // 7
        "Hard Leather Boots", // 8
        "Leather Boots", // 9
        "Divine Slippers", // 10
        "Silk Slippers", // 11
        "Wool Shoes", // 12
        "Linen Shoes", // 13
        "Shoes" // 14
    ];

    string[15] memory handArmor = [
        "Holy Gauntlets", // 0
        "Ornate Gauntlets", // 1
        "Gauntlets", // 2
        "Chain Gloves", // 3
        "Heavy Gloves", // 4
        "Demon's Hands", // 5
        "Dragonskin Gloves", // 6
        "Studded Leather Gloves", // 7
        "Hard Leather Gloves", // 8
        "Leather Gloves", // 9
        "Divine Gloves", // 10
        "Silk Gloves", // 11
        "Wool Gloves", // 12
        "Linen Gloves", // 13
        "Gloves" // 14
    ];

    string[3] memory necklaces = [
        "Necklace", // 0
        "Amulet", // 1
        "Pendant" // 2
    ];

    string[5] memory rings = [
        "Gold Ring", // 0
        "Silver Ring", // 1
        "Bronze Ring", // 2
        "Platinum Ring", // 3
        "Titanium Ring" // 4
    ];
        
        if (itemType == 0x0) {
            return weapons[idx];
        } else if (itemType == 0x1) {
            return chestArmor[idx];
        } else if (itemType == 0x2) {
            return headArmor[idx];
        } else if (itemType == 0x3) {
            return waistArmor[idx];
        } else if (itemType == 0x4) {
            return footArmor[idx];
        } else if (itemType == 0x5) {
            return handArmor[idx];
        } else if (itemType == 0x6) {
            return necklaces[idx];
        } else if (itemType == 0x7) {
            return rings[idx];
        } else {
            revert("Unexpected armor piece");
        }

    }

    function weaponComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "WEAPON", 18);
    }

    function chestComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "CHEST", 15);
    }

    function headComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "HEAD", 15);
    }

    function waistComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "WAIST", 15);
    }

    function footComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "FOOT", 15);
    }

    function handComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "HAND", 15);
    }

    function neckComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "NECK", 3);
    }

    function ringComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "RING", 5);
    }

    
    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function itemPluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) public pure returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength;
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % 16) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % 69) + 1;
            components[3] = (rand % 18) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }

        return components;
    }

    function _itemId(
        uint256 tokenId,
        function(uint256) view returns (uint256[5] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint256[5] memory components = componentsFn(tokenId);
        return ItemTokenId.toId(components, itemType);
    }

    function getItemId(uint recipeTokenId) public view returns(uint) {
        uint256 rand = random(string(abi.encodePacked(Strings.toString(recipeTokenId)))) % 8;
        uint256 id;

        if (rand == 0){
            id = _itemId(recipeTokenId, weaponComponents, 0x0);
        } 
        else if (rand == 1){
            id = _itemId(recipeTokenId, chestComponents, 0x1);
        }
        else if (rand == 2){
            id =_itemId(recipeTokenId, waistComponents, 0x3);
        }
        else if (rand == 3){
            id = _itemId(recipeTokenId, footComponents, 0x4);
        }
        else if (rand == 4){
            id = _itemId(recipeTokenId, headComponents, 0x2);
        }
        else if (rand == 5){
            id = _itemId(recipeTokenId, handComponents, 0x5);
        }        
        else if (rand == 6){
            id = _itemId(recipeTokenId, neckComponents, 0x6);
        }        
        else {
            id = _itemId(recipeTokenId, ringComponents, 0x7);
        }

        return id;
    }
            // Creates the token description given its components and what type it is
    function componentsToString(uint256[5] memory components, uint256 itemType)
        private
        pure
        returns (string memory)
    {

            string[16] memory suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    string[69] memory namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
        "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        "Light's", "Shimmering"  
    ];
    
    string[18] memory nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];

        // item type: what slot to get
        // components[0] the index in the array
        string memory item = itemName(itemType, components[0]);

        // We need to do -1 because the 'no description' is not part of loot copmonents

        // add the suffix
        if (components[1] > 0) {
            item = string(
                abi.encodePacked(item, " ", suffixes[components[1] - 1])
            );
        }

        // add the name prefix / suffix
        if (components[2] > 0) {
            // prefix
            string memory namePrefixSuffix = string(
                abi.encodePacked("'", namePrefixes[components[2] - 1])
            );
            if (components[3] > 0) {
                namePrefixSuffix = string(
                    abi.encodePacked(namePrefixSuffix, " ", nameSuffixes[components[3] - 1])
                );
            }

            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, "' "));

            item = string(abi.encodePacked(namePrefixSuffix, item));
        }

        // add the augmentation
        if (components[4] > 0) {
            item = string(abi.encodePacked(item, " +1"));
        }

        return item;
    }

    function tokenName(uint256 id) public pure returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = ItemTokenId.fromId(id);
        return componentsToString(components, itemType);
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