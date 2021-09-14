/**
 *Submitted for verification at polygonscan.com on 2021-09-14
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
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function weaponComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WEAPON", weapons);
    }
    
    function chestComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "CHEST", chestArmor);
    }
    
    function headComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HEAD", headArmor);
    }
    
    function waistComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WAIST", waistArmor);
    }

    function footComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "FOOT", footArmor);
    }
    
    function handComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HAND", handArmor);
    }
    
    function neckComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "NECK", necklaces);
    }
    
    function ringComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "RING", rings);
    }
    
    function getWeapon(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WEAPON", weapons);
    }
    
    function getChest(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "CHEST", chestArmor);
    }
    
    function getHead(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HEAD", headArmor);
    }
    
    function getWaist(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WAIST", waistArmor);
    }

    function getFoot(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "FOOT", footArmor);
    }
    
    function getHand(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HAND", handArmor);
    }
    
    function getNeck(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "NECK", necklaces);
    }
    
    function getRing(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "RING", rings);
    }
    
    function pluckName(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
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

    function pluck(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (uint256[5] memory) {
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
    
    function tokenURI(address walletAddress) public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(walletAddress);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(walletAddress);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(walletAddress);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(walletAddress);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(walletAddress);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(walletAddress);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(walletAddress);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(walletAddress);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag 0x', toAsciiString(walletAddress), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

pragma solidity ^0.8.0;
interface Activity {
    function activityName() external returns (string memory);
    function activityDescription() external returns (string memory);
    function xpName() external returns (string memory);
    function xpForAdventurer(address) external returns (uint256);
}


contract HelloDungeon is Activity, SyntheticLoot {
    struct BossInstance {
        int32 hp;
        uint256 spawnBlock;
        uint256 killBlock;
    }

    struct Mechanics {
        uint256 purityLevel;
        uint256 weaknessLevel;
        uint256 damageLevel;
        uint256 stunLevel;
        bool bossSpawned;
        uint256 currentBossId;
        uint256 lastBossSpawnTime;
    }

    struct Spoils {
        uint256 fang;
        uint256 tail;
        uint256 mantle;
        uint256 horn;
        uint256 claw;
        uint256 eye;
        uint256 heart;
    }
    

    Mechanics public mechanics;

    mapping(address => uint256) internal _xpMap;
    mapping(address => uint256) internal _lastActionMap;
    mapping(address => uint256) internal _lastBossActionMap;
    mapping(address => Spoils) internal _spoilsMap;
    mapping(uint256 => mapping(address => uint256)) internal _bossActionsTakenMap;
    mapping(uint256 => BossInstance) public bosses;

    function activityName() override pure external returns (string memory) {
        return "Hello Dungeon";
    }

    function activityDescription() override pure external returns (string memory) {
        return "Proof of concept public dungeon";
    }

    function xpName() override pure external returns (string memory) {
        return "Dungeoneering (Prototype) I";
    }

    function xpForAdventurer(address adventurer) override view external returns (uint256) {
        return _xpMap[adventurer];
    }

    function fight() public {
        require(block.timestamp - _lastActionMap[msg.sender] >= 6 hours, "too soon");

        uint256 weaponId = SyntheticLoot.weaponComponents(msg.sender)[0];
        uint8 amount = 1;
        if (_xpMap[msg.sender] >= 48) {
            amount = 3;
        } else if (_xpMap[msg.sender] >= 12) {
            amount = 2;
        }

        if (weaponId >= 14) {
            // book
            mechanics.purityLevel += amount;
            _xpMap[msg.sender]++;
        } else if (weaponId >= 10) {
            // wand
            mechanics.weaknessLevel += amount;
            _xpMap[msg.sender]++;
        } else if (weaponId >= 5) {
            // blade
            mechanics.damageLevel += amount;
            _xpMap[msg.sender]++;
        } else {
            // bludgeon
            mechanics.stunLevel += amount;
            _xpMap[msg.sender]++;
        }

        _lastActionMap[msg.sender] = block.timestamp;
    }

    function spawnBoss() public {
        require(
            mechanics.purityLevel > 100 &&
            mechanics.weaknessLevel > 100 &&
            mechanics.damageLevel > 100 &&
            mechanics.stunLevel > 100,
            "conditions not met"
        );
        require(mechanics.bossSpawned == false, "already spawned");
        require(block.timestamp - mechanics.lastBossSpawnTime >= 3 hours, "last boss too recent");

        BossInstance memory boss;
        boss.hp = 1000;
        boss.spawnBlock = block.number;
        mechanics.currentBossId++;
        mechanics.bossSpawned = true;
        mechanics.lastBossSpawnTime = block.timestamp;

        bosses[mechanics.currentBossId] = boss;
    }

    function fightBoss() public {
        require(mechanics.bossSpawned == true, "boss not spawned");
        require(block.timestamp - _lastBossActionMap[msg.sender] >= 10 minutes, "too soon");

        bosses[mechanics.currentBossId].hp--;
        _bossActionsTakenMap[mechanics.currentBossId][msg.sender]++;

        _lastBossActionMap[msg.sender] = block.timestamp;

        if (bosses[mechanics.currentBossId].hp <= 0) {
            mechanics.bossSpawned = false;
            bosses[mechanics.currentBossId].killBlock = block.number;
        }
    }

    function spoilsUnclaimed(address owner, uint256 bossId) public view returns (uint256) {
        return _bossActionsTakenMap[bossId][owner];
    }

    function spoilsInventory(address owner) public view returns (Spoils memory) {
        return _spoilsMap[owner];
    }

    function claimSpoils(uint256 bossId, uint8 amount) public {
        require(bossId <= mechanics.currentBossId, "invalid boss id");
        require(bosses[bossId].hp <= 0, "boss not dead");
        require(_bossActionsTakenMap[bossId][msg.sender] > 0, "no spoils to claim");

        if (amount > 10) {
            amount = 10;
        }

        require(_bossActionsTakenMap[bossId][msg.sender] >= amount, "can't claim that many");

        for (uint8 i = 0; i < amount; ++i) {
            _bossActionsTakenMap[bossId][msg.sender]--;

            uint256 rng = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _bossActionsTakenMap[bossId][msg.sender],
                        bosses[bossId].spawnBlock,
                        bosses[bossId].killBlock
                    )
                )
            );

            rng = rng % 100;
            if (rng > 98) {
                _spoilsMap[msg.sender].heart++;
            } else if (rng > 90) {
                _spoilsMap[msg.sender].eye++;
            }

            rng = rng % 5;
            if (rng == 0) { _spoilsMap[msg.sender].fang++; }
            if (rng == 1) { _spoilsMap[msg.sender].tail++; }
            if (rng == 2) { _spoilsMap[msg.sender].mantle++; }
            if (rng == 3) { _spoilsMap[msg.sender].horn++; }
            if (rng == 4) { _spoilsMap[msg.sender].claw++; }
        }
    }
}