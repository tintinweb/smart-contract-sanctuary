// SPDX-License-Identifier: CC0-1.0

/// @title Seed and configuration for Crypts and Caverns

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

contract dungeonsSeeder {

    /* Names */
    string[29] prefixes = [
        "Abyssal",
        "Ancient",
        "Bleak",
        "Bright",
        "Burning",
        "Collapsed",
        "Corrupted",
        "Dark",
        "Decrepid",
        "Desolate",
        "Dire",
        "Divine",
        "Emerald",
        "Empyrean",
        "Fallen",
        "Glowing",
        "Grim",
        "Heaven's",
        "Hidden",
        "Holy",
        "Howling",
        "Inner",
        "Morbid",
        "Murky",
        "Outer",
        "Shimmering",
        "Siren's",
        "Sunken",
        "Whispering"
    ];
  
    string[38] land = [
        "Canyon",
        "Catacombs",
        "Cavern",
        "Chamber",
        "Cloister",
        "Crypt",
        "Den",
        "Dunes",
        "Field",
        "Forest",
        "Glade",
        "Gorge",
        "Graveyard",
        "Grotto",
        "Grove",
        "Halls",
        "Keep",
        "Lair",
        "Labyrinth",
        "Landing",
        "Maze",
        "Mountain",
        "Necropolis",
        "Oasis",
        "Passage",
        "Peak",
        "Prison",
        "Scar",
        "Sewers",
        "Shrine",
        "Sound",
        "Steppes",
        "Temple",
        "Tundra",
        "Tunnel",
        "Valley",
        "Waterfall",
        "Woods"
    ];
  
    string[60] suffixes = [
        "Agony",
        "Anger",
        "Blight",
        "Bone",
        "Brilliance",
        "Brimstone",
        "Corruption",
        "Despair",
        "Dread",
        "Dusk",
        "Enlightenment",
        "Fury",
        "Fire",
        "Giants",
        "Gloom",
        "Hate",
        "Havoc",
        "Honour",
        "Horror",
        "Loathing",
        "Mire",
        "Mist",
        "Needles",
        "Pain",
        "Pandemonium",
        "Pine",
        "Rage",
        "Rapture",
        "Sand",
        "Sorrow",
        "the Apocalypse",
        "the Beast",
        "the Behemoth",
        "the Brood",
        "the Fox",
        "the Gale",
        "the Golem",
        "the Kraken",
        "the Leech",
        "the Moon",
        "the Phoenix",
        "the Plague",
        "the Root",
        "the Song",
        "the Stars",
        "the Storm",
        "the Sun",
        "the Tear",
        "the Titans",
        "the Twins",
        "the Willows",
        "the Wisp",
        "the Viper",
        "the Vortex",
        "Torment",
        "Vengeance",
        "Victory",
        "Woe",
        "Wisdom",
        "Wrath"
    ];
    
    string[17] unique = [
        "'Armageddon'",
        "'Mind's Eye'",
        "'Nostromo'",
        "'Oblivion'",
        "'The Chasm'",
        "'The Crypt'",
        "'The Depths'",
        "'The End'",
        "'The Expanse'",
        "'The Gale'",
        "'The Hook'",
        "'The Maelstrom'",
        "'The Mouth'",
        "'The Muck'",
        "'The Shelf'",
        "'The Vale'",
        "'The Veldt'"
    ];
    
    string[12] people = [
        "Fate's",
        "Fohd's",
        "Gremp's",
        "Hate's",
        "Kali's",
        "Kiv's",
        "Light's",
        "Shub's",
        "Sol's",
        "Tish's",
        "Viper's",
        "Woe's"
    ];

    function getSeed(uint256 tokenId) external view returns(uint256) {
    /* Generates a random seed from a tokenId + blockhash for each mint. 
       There are more unpredictable approaches but this should be sufficient for initial mint/claim.
       We'll bitshift this seed to get pseudorandom numbers */
        uint256 seed = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, tx.gasprice))
        );
        return(seed);
    }

    function getSize(uint256 seed) external pure returns (uint8) {
    // Returns a size for the dungeon that determines the layout. Size can be between 8x8 -> 25x25 and dungeons are always square.
        return uint8(random(seed << 4, 8, 25));
    }

    function getEnvironment(uint256 seed) external pure returns (uint8) {
    /* Returns a random environment which suggests a tone/mood for the dungeon.
    * 0 - Stone Temple (30%)
    * 1 - Mountain Deep (25%)
    * 2 - Desert Oasis (20%)
    * 3 - Forest Ruins (12%)
    * 4 - Underwater Keep (7%)
    * 5 - Ember's Glow (5%) */
        uint256 rand = random(seed << 8, 0, 100);

        if(rand >= 70) {
            return 0;
        } else if(rand >= 45) {
            return 1;
        } else if(rand >= 25) {
            return 2;
        } else if(rand >= 13) {
            return 3;
        } else if(rand >= 4) {
            return 4;
        } else {
            return 5;
        }
    }


    /* Generates and returns a random name for the dungeon */
    function getName(uint256 seed) external view returns(string memory, string memory, uint8) {
        string memory output;
        string memory affinity;
        uint8 legendary;
        
        uint256 uniqueSeed = random(seed << 15, 0, 10000);
        if(uniqueSeed < 17) {
            // Unique name
            legendary = 1;
            affinity = "none";
            output = unique[uniqueSeed];            
        } else {
            string[5] memory nameParts;
            uint256 baseSeed = random(seed << 16, 0, 38);
            
            if(uniqueSeed <= 300) {
                // Person's Name + Base Land
                legendary = 0;
                affinity = "none";
                nameParts[0] = people[random(seed << 23, 0, 12)];
                nameParts[1] = " ";
                nameParts[2] = land[baseSeed];
                output = string(abi.encodePacked(nameParts[0], nameParts[1], nameParts[2]));
            } else if(uniqueSeed <= 1800) {
                // Prefix + Base Land + Suffix
                legendary = 0;
                nameParts[0] = prefixes[random(seed << 42, 0, 29)];
                nameParts[1] = " ";
                nameParts[2] = land[baseSeed];
                nameParts[3] = " of ";
                affinity = suffixes[random(seed << 27, 0, 59)];
                nameParts[4] = affinity;
                output = string(abi.encodePacked(nameParts[0], nameParts[1], nameParts[2], nameParts[3], nameParts[4]));
            } else if(uniqueSeed <= 4000) {
                // Base Land + Suffix
                legendary = 0;
                nameParts[0] = land[baseSeed];
                nameParts[1] = " of ";
                affinity = suffixes[random(seed << 51, 0, 59)];
                nameParts[2] = affinity;
                output = string(abi.encodePacked(nameParts[0], nameParts[1], nameParts[2]));
            } else if(uniqueSeed <= 6500) {
                // Prefix + Base Land 
                legendary = 0;
                affinity = "none";
                nameParts[0] = prefixes[random(seed << 59, 0, 29)];
                nameParts[1] = " ";
                nameParts[2] = land[baseSeed];
                output = string(abi.encodePacked(nameParts[0], nameParts[1], nameParts[2]));
            } else {
                // Base Land
                legendary = 0;
                affinity = "none";
                output = land[baseSeed];
            }
        }
        return (output, affinity, legendary);
    }

    /* Utility Functions */
    function random(uint256 input, uint256 min, uint256 max) internal pure returns (uint256) {
    // Returns a random (deterministic) seed between 0-range based on an arbitrary set of inputs
        uint256 output = uint256(keccak256(abi.encodePacked(input))) % (max-min) + min;
        return output;
    }
}