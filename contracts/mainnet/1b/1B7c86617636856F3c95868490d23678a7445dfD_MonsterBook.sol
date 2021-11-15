//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//////////////////////////////////////////////

///    *        )      )  (                (    (
///  (  `    ( /(   ( /(  )\ )  *   )      )\ ) )\ )
///  )\))(   )\())  )\())(()/(` )  /( (   (()/((()/(
/// ((_)()\ ((_)\  ((_)\  /(_))( )(_)))\   /(_))/(_))
/// (_()((_)  ((_)  _((_)(_)) (_(_())((_) (_)) (_))
/// |  \/  | / _ \ | \| |/ __||_   _|| __|| _ \/ __|
/// | |\/| || (_) || .` |\__ \  | |  | _| |   /\__ \
/// |_|  |_| \___/ |_|\_||___/  |_|  |___||_|_\|___/

//////////////////////////////////////////////

interface IMonsterBook {
    function getName(uint256 monsterId) external view returns (string memory);

    function getSize(uint256 monsterId) external view returns (string memory);

    function getAlignment(uint256 monsterId)
        external
        view
        returns (string memory);

    function getAction1(uint256 monsterId)
        external
        view
        returns (string memory);

    function getAction2(uint256 monsterId)
        external
        view
        returns (string memory);

    function getSpecialAbility(uint256 monsterId)
        external
        view
        returns (string memory);

    function getWeakness(uint256 monsterId)
        external
        view
        returns (string memory);

    function getLocomotion(uint256 monsterId)
        external
        view
        returns (string memory);

    function getLanguage(uint256 monsterId)
        external
        view
        returns (string memory);

    function random(string memory input) external pure returns (uint256);
}

/// @title A ERC721 contract to generate random monsters for adventurers to encounter
/// @author Isaac Patka, Dekan Brown, Sam Kuhlmann, arentweall
/// @notice This contract is heavily inspired by Sam Mason de Caires' Maps contract which in turn was...
///  heavily inspired by Dom Hofmann's Loot Project and allows for the on chain creation of maps and there various waypoints along the journey.
contract MonsterBook is IMonsterBook {
    /// @notice Pseudo random number generator based on input
    /// @dev Not really random
    /// @param input The seed value
    function random(string memory input)
        public
        pure
        override
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    string[] private languages = [
        "Understands all but can't speak",
        "Can't understand language at all",
        "Demon, Devil, Undead, Monstrosity",
        "Bearfolk, Beast, Burrowling, Telepathy",
        "Gnome, Goblin, Swarm, Erina, Fey",
        "Dragon, Abberation, Merfolk, Simian",
        "Dwarf, Giant, Titan",
        "Elf, Elemental, Lizardfolk, Plant, Trollkin, Orc",
        "Ratfolk, Roachling, Beast, Shoth, Kryt",
        "Gearforged, Humanoid, Noctiny, Shapechanger"
    ];

    string[] private names = [
        "Acid Ant",
        "Akyishigal",
        "Baal",
        "Balor",
        "Bilwis",
        "Buraq",
        "Cauldronborn",
        "Chuul",
        "Dark Eye",
        "Deathwisp",
        "Dogmole",
        "Droth",
        "Efreeti",
        "Fate Eater",
        "Firegeist",
        "Gargoctopus",
        "Ghoulsteed",
        "Gloomflower",
        "Gorgon",
        "Grimlock",
        "Hezrou",
        "Jinmenju",
        "Karakura",
        "Lystrosaurus",
        "Manticore",
        "Moloch",
        "Nachzehrer",
        "Nightgarm",
        "Oozasis",
        "Oth",
        "Putrid Haunt",
        "Qwyllion",
        "Rageipede",
        "Rattok",
        "Ravenfolk Doom Croaker",
        "Razorleaf",
        "Rimewing",
        "Sea Hag",
        "Serpentfolk of Yig",
        "Shrieker",
        "Sooze",
        "Soul Eater",
        "Spawn of Akyishigal",
        "Tosculi Hive-Queen",
        "Voidling",
        "Xenabsorber",
        "Xorn",
        "Yek",
        "Zaratan",
        "Zimwi",
        "Zoog"
    ];

    string[] private types = [
        "Aberration",
        "Bearfolk",
        "Beast",
        "Burrowling",
        "Construct",
        "Demon",
        "Devil",
        "Dhampir",
        "Dragon",
        "Dwarf",
        "Elemental",
        "Elf",
        "Erina",
        "Fey",
        "Fiend",
        "Gearforged",
        "Giant",
        "Gnoll",
        "Gnome",
        "Goblin",
        "Grimlock",
        "Humanoid",
        "Kenku",
        "Kobold",
        "Kryt",
        "Lemurfolk",
        "Lizardfolk",
        "Merfolk",
        "Monstrosity",
        "Noctiny",
        "Ooze",
        "Orc",
        "Plant",
        "Ramag",
        "Ratfolk",
        "Roachling",
        "Sahuagin",
        "Shapechanger",
        "Shoth",
        "Simian",
        "Subek",
        "Swarm of Tiny Aberrations",
        "Swarm of Tiny Beasts",
        "Swarm of Tiny Monstrosities",
        "Swarm of Tiny Undead",
        "Titan",
        "Tosculi",
        "Trollkin",
        "Undead",
        "Yakirian"
    ];

    string[] private locations = [
        "Forest",
        "Swamp",
        "Sea",
        "Burrows",
        "Catacombs",
        "Desert",
        "Mountains",
        "Village",
        "Dungeon",
        "Void"
    ];

    string[] private alignments = [
        "Chaotic",
        "Chaotic Evil",
        "Chaotic Good",
        "Chaotic Neutral",
        "Good",
        "Lawful Evil",
        "Lawful Good",
        "Lawful Neutral",
        "Neutral",
        "Neutral Evil",
        "Neutral Good",
        "Unaligned"
    ];

    string[] private action1 = [
        "Absorb",
        "Acid Spray",
        "Aura of Drunkenness",
        "Bite",
        "Blinding Gaze",
        "Claw",
        "Club",
        "Constrict",
        "Desiccating Touch",
        "Eldritch Singularity",
        "Embers",
        "Enforced Diplomacy",
        "Fey Charm",
        "Fiery Fangs",
        "Fiery Greatsword",
        "Flame Breath",
        "Kiss",
        "Lightning Strike",
        "Moon Bolt",
        "Morningstar",
        "Multiattack",
        "Paralyzing Touch",
        "Poison Breath",
        "Psychic Stab",
        "Read Thoughts",
        "Shadow Sword",
        "Strength Drain",
        "Telekinesis"
    ];

    string[] private action2 = [
        "Breath Weapon",
        "Charge",
        "Cold Breath",
        "Devour",
        "Enslave",
        "Ethereal Lure",
        "Fear Aura",
        "Fey Charm",
        "Fist",
        "Flame Breath",
        "Form Swap",
        "Ghost Breath",
        "Glitter Dust",
        "Gore",
        "Grasp of the Grave",
        "Halberd",
        "Lightning Breath",
        "Magical Burble",
        "Shifting Flames",
        "Shriek",
        "Slam",
        "Tail",
        "Talons",
        "Thorny Lash",
        "Thrall Enslavement",
        "Warhammer",
        "Whirlwind",
        "Withering Touch"
    ];

    string[] private specialAbility = [
        "Blood Frenzy",
        "Charge",
        "Deadly Precision",
        "Defensive Zone",
        "Ethereal Jaunt",
        "Evasive",
        "False Appearance",
        "Fire Absorption",
        "Fire Form",
        "Foul Odor",
        "Groundbreaker",
        "Hellish Rejuvenation",
        "Ingest Magic",
        "Ingest Weapons",
        "Keen Senses",
        "Know Thoughts",
        "Levitate",
        "Mighty Leap",
        "Peaceful Creature",
        "Pheromones",
        "Prismatic Glow",
        "Regeneration",
        "Resize",
        "Shadow Stealth",
        "Shapechanger",
        "Sneak Attack",
        "Spider Climb",
        "Sure-Footed",
        "Two-Headed"
    ];

    string[] private size = [
        "Tiny",
        "Scrawny",
        "Stout",
        "Tall",
        "Gigantic",
        "Colossal"
    ];

    string[] private weakness = [
        "Light",
        "Flames",
        "Physical Damage",
        "Freeze",
        "Poison",
        "Sunlight",
        "Magic",
        "Noise",
        "Darkness",
        "Mind Control"
    ];

    string[] private locomotion = [
        "Fly",
        "Hop",
        "Prowl",
        "Gallop",
        "Glide",
        "Leap",
        "Sneak",
        "Slither",
        "Pound",
        "Trample"
    ];

    function pluck(
        uint256 monsterId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(monsterId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function getLanguage(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "LANGUAGE", languages);
    }

    function getName(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        string[3] memory monsterName;
        monsterName[0] = pluck(monsterId, "NAME", names);
        monsterName[1] = pluck(monsterId, "TYPE", types);
        monsterName[2] = pluck(monsterId, "LOCATION", locations);
        return
            string(
                abi.encodePacked(
                    monsterName[0],
                    " The ",
                    monsterName[1],
                    " of The ",
                    monsterName[2]
                )
            );
    }

    function getAlignment(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "ALIGNMENT", alignments);
    }

    function getAction1(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "ACTION1", action1);
    }

    function getAction2(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "ACTION2", action2);
    }

    function getSpecialAbility(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "SPECIALABILITY", specialAbility);
    }

    function getSize(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "SIZE", size);
    }

    function getWeakness(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "WEAKNESS", weakness);
    }

    function getLocomotion(uint256 monsterId)
        external
        view
        override
        returns (string memory)
    {
        return pluck(monsterId, "LOCOMOTION", locomotion);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
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

