/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: Unlicense

/*

    Synthetic Loot

    This contract creates a "virtual NFT" of Loot based
    on a given wallet address.

    Because the wallet address is used as the deterministic
    seed, there can only be one Loot bag per wallet.

    Because it's not a real NFT, there is no
    minting, transferability, etc.

    Creators building on top of Loot can choose to recognize
    Synthetic Loot as a way to allow a wider range of
    adventurers to participate in the ecosystem, while
    still being able to differentiate between
    "original" Loot and Synthetic Loot.

    Anyone with an Ethereum wallet has Synthetic Loot.

    -----

    Also optionally returns data in LootComponents format:

    Call weaponComponents(), chestComponents(), etc. to get
    an array of attributes that correspond to the item.

    The return format is:

    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)

    See the item and attribute tables below for corresponding IDs.

    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

pragma solidity ^0.8.4;

contract SyntheticLoot {

    string[] private weapons = [
    "Warhammer",            // 0
    "Quarterstaff",         // 1
    "Maul",                 // 2
    "Mace",                 // 3
    "Club",                 // 4
    "Katana",               // 5
    "Falchion",             // 6
    "Scimitar",             // 7
    "Long Sword",           // 8
    "Short Sword",          // 9
    "Ghost Wand",           // 10
    "Grave Wand",           // 11
    "Bone Wand",            // 12
    "Wand",                 // 13
    "Grimoire",             // 14
    "Chronicle",            // 15
    "Tome",                 // 16
    "Book"                  // 17
    ];

    string[] private chestArmor = [
    "Divine Robe",          // 0
    "Silk Robe",            // 1
    "Linen Robe",           // 2
    "Robe",                 // 3
    "Shirt",                // 4
    "Demon Husk",           // 5
    "Dragonskin Armor",     // 6
    "Studded Leather Armor",// 7
    "Hard Leather Armor",   // 8
    "Leather Armor",        // 9
    "Holy Chestplate",      // 10
    "Ornate Chestplate",    // 11
    "Plate Mail",           // 12
    "Chain Mail",           // 13
    "Ring Mail"             // 14
    ];

    string[] private headArmor = [
    "Ancient Helm",         // 0
    "Ornate Helm",          // 1
    "Great Helm",           // 2
    "Full Helm",            // 3
    "Helm",                 // 4
    "Demon Crown",          // 5
    "Dragon's Crown",       // 6
    "War Cap",              // 7
    "Leather Cap",          // 8
    "Cap",                  // 9
    "Crown",                // 10
    "Divine Hood",          // 11
    "Silk Hood",            // 12
    "Linen Hood",           // 13
    "Hood"                  // 14
    ];

    string[] private waistArmor = [
    "Ornate Belt",          // 0
    "War Belt",             // 1
    "Plated Belt",          // 2
    "Mesh Belt",            // 3
    "Heavy Belt",           // 4
    "Demonhide Belt",       // 5
    "Dragonskin Belt",      // 6
    "Studded Leather Belt", // 7
    "Hard Leather Belt",    // 8
    "Leather Belt",         // 9
    "Brightsilk Sash",      // 10
    "Silk Sash",            // 11
    "Wool Sash",            // 12
    "Linen Sash",           // 13
    "Sash"                  // 14
    ];

    string[] private footArmor = [
    "Holy Greaves",         // 0
    "Ornate Greaves",       // 1
    "Greaves",              // 2
    "Chain Boots",          // 3
    "Heavy Boots",          // 4
    "Demonhide Boots",      // 5
    "Dragonskin Boots",     // 6
    "Studded Leather Boots",// 7
    "Hard Leather Boots",   // 8
    "Leather Boots",        // 9
    "Divine Slippers",      // 10
    "Silk Slippers",        // 11
    "Wool Shoes",           // 12
    "Linen Shoes",          // 13
    "Shoes"                 // 14
    ];

    string[] private handArmor = [
    "Holy Gauntlets",       // 0
    "Ornate Gauntlets",     // 1
    "Gauntlets",            // 2
    "Chain Gloves",         // 3
    "Heavy Gloves",         // 4
    "Demon's Hands",        // 5
    "Dragonskin Gloves",    // 6
    "Studded Leather Gloves",// 7
    "Hard Leather Gloves",  // 8
    "Leather Gloves",       // 9
    "Divine Gloves",        // 10
    "Silk Gloves",          // 11
    "Wool Gloves",          // 12
    "Linen Gloves",         // 13
    "Gloves"                // 14
    ];

    string[] private necklaces = [
    "Necklace",             // 0
    "Amulet",               // 1
    "Pendant"               // 2
    ];

    string[] private rings = [
    "Gold Ring",            // 0
    "Silver Ring",          // 1
    "Bronze Ring",          // 2
    "Platinum Ring",        // 3
    "Titanium Ring"         // 4
    ];

    string[] private suffixes = [
    // <no suffix>          // 0
    "of Power",             // 1
    "of Giants",            // 2
    "of Titans",            // 3
    "of Skill",             // 4
    "of Perfection",        // 5
    "of Brilliance",        // 6
    "of Enlightenment",     // 7
    "of Protection",        // 8
    "of Anger",             // 9
    "of Rage",              // 10
    "of Fury",              // 11
    "of Vitriol",           // 12
    "of the Fox",           // 13
    "of Detection",         // 14
    "of Reflection",        // 15
    "of the Twins"          // 16
    ];

    string[] private namePrefixes = [
    // <no name>            // 0
    "Agony",                // 1
    "Apocalypse",           // 2
    "Armageddon",           // 3
    "Beast",                // 4
    "Behemoth",             // 5
    "Blight",               // 6
    "Blood",                // 7
    "Bramble",              // 8
    "Brimstone",            // 9
    "Brood",                // 10
    "Carrion",              // 11
    "Cataclysm",            // 12
    "Chimeric",             // 13
    "Corpse",               // 14
    "Corruption",           // 15
    "Damnation",            // 16
    "Death",                // 17
    "Demon",                // 18
    "Dire",                 // 19
    "Dragon",               // 20
    "Dread",                // 21
    "Doom",                 // 22
    "Dusk",                 // 23
    "Eagle",                // 24
    "Empyrean",             // 25
    "Fate",                 // 26
    "Foe",                  // 27
    "Gale",                 // 28
    "Ghoul",                // 29
    "Gloom",                // 30
    "Glyph",                // 31
    "Golem",                // 32
    "Grim",                 // 33
    "Hate",                 // 34
    "Havoc",                // 35
    "Honour",               // 36
    "Horror",               // 37
    "Hypnotic",             // 38
    "Kraken",               // 39
    "Loath",                // 40
    "Maelstrom",            // 41
    "Mind",                 // 42
    "Miracle",              // 43
    "Morbid",               // 44
    "Oblivion",             // 45
    "Onslaught",            // 46
    "Pain",                 // 47
    "Pandemonium",          // 48
    "Phoenix",              // 49
    "Plague",               // 50
    "Rage",                 // 51
    "Rapture",              // 52
    "Rune",                 // 53
    "Skull",                // 54
    "Sol",                  // 55
    "Soul",                 // 56
    "Sorrow",               // 57
    "Spirit",               // 58
    "Storm",                // 59
    "Tempest",              // 60
    "Torment",              // 61
    "Vengeance",            // 62
    "Victory",              // 63
    "Viper",                // 64
    "Vortex",               // 65
    "Woe",                  // 66
    "Wrath",                // 67
    "Light's",              // 68
    "Shimmering"            // 69
    ];

    string[] private nameSuffixes = [
    // <no name>            // 0
    "Bane",                 // 1
    "Root",                 // 2
    "Bite",                 // 3
    "Song",                 // 4
    "Roar",                 // 5
    "Grasp",                // 6
    "Instrument",           // 7
    "Glow",                 // 8
    "Bender",               // 9
    "Shadow",               // 10
    "Whisper",              // 11
    "Shout",                // 12
    "Growl",                // 13
    "Tear",                 // 14
    "Peak",                 // 15
    "Form",                 // 16
    "Sun",                  // 17
    "Moon"                  // 18
    ];

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pluckName(address walletAddress, string memory keyPrefix, string[] memory sourceArray) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function pluck(address walletAddress, string memory keyPrefix, string[] memory sourceArray) public view returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));

        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % suffixes.length) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % namePrefixes.length) + 1;
            components[3] = (rand % nameSuffixes.length) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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