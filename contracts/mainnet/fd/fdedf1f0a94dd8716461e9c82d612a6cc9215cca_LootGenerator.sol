// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Random.sol";

contract LootGenerator{
    using Strings for uint256;

    string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Falchion",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Book"
    ];
    
    string[] private chestArmor = [
        "Divine Robe",
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt",
        "Demon Husk",
        "Dragonskin Armor",
        "Studded Leather Armor",
        "Hard Leather Armor",
        "Leather Armor",
        "Holy Chestplate",
        "Ornate Chestplate",
        "Plate Mail",
        "Chain Mail",
        "Ring Mail"
    ];
    
    string[] private headArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm",
        "Full Helm",
        "Helm",
        "Demon Crown",
        "Dragon's Crown",
        "War Cap",
        "Leather Cap",
        "Cap",
        "Crown",
        "Divine Hood",
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];
    
    string[] private waistArmor = [
        "Ornate Belt",
        "War Belt",
        "Plated Belt",
        "Mesh Belt",
        "Heavy Belt",
        "Demonhide Belt",
        "Dragonskin Belt",
        "Studded Leather Belt",
        "Hard Leather Belt",
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];
    
    string[] private footArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Demonhide Boots",
        "Dragonskin Boots",
        "Studded Leather Boots",
        "Hard Leather Boots",
        "Leather Boots",
        "Divine Slippers",
        "Silk Slippers",
        "Wool Shoes",
        "Linen Shoes",
        "Shoes"
    ];
    
    string[] private handArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Gauntlets",
        "Chain Gloves",
        "Heavy Gloves",
        "Demon's Hands",
        "Dragonskin Gloves",
        "Studded Leather Gloves",
        "Hard Leather Gloves",
        "Leather Gloves",
        "Divine Gloves",
        "Silk Gloves",
        "Wool Gloves",
        "Linen Gloves",
        "Gloves"
    ];
    
    string[] private necklaces = [
        "Necklace",
        "Amulet",
        "Pendant"
    ];
    
    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];
    
    string[] private suffixes = [
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
    
    string[] private namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
        "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        "Light's", "Shimmering"  
    ];
    
    string[] private nameSuffixes = [
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

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (int8[5] memory) {
        uint256 rand = Random.toKeccak256(string(abi.encodePacked(keyPrefix, tokenId.toString())));

        int8[5] memory armor = [int8(-1),-1,-1,-1,-1];
        armor[2] = int8(uint8(rand % sourceArray.length));
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            armor[3] = int8(uint8(rand % suffixes.length));
        }
        if (greatness >= 19) {
            armor[0] = int8(uint8(rand % namePrefixes.length));
            armor[1] = int8(uint8(rand % nameSuffixes.length));
            if (greatness != 19) {
               armor[4] = 0;
            }
        }
        return armor;
    }

    function getEquipmentName(int8[5] memory equipment, string[] memory sourceArray) internal view returns(string memory) {
        string memory output = string(abi.encodePacked(sourceArray[uint8(equipment[2])]));
        if (equipment[3] != -1) {
            output = string(abi.encodePacked(output, " ", suffixes[uint8(equipment[3])]));
        }

        if ((equipment[0] != -1) && (equipment[1] != -1)) {
             output = string(abi.encodePacked('"', namePrefixes[uint8(equipment[0])], ' ', nameSuffixes[uint8(equipment[1])], '" ', output));
        }

        if (equipment[4] != -1) {
            output = string(abi.encodePacked(output, " +1"));
        }
        return output;
    }   

    function mint(uint256 tokenId, uint8 idx) external view returns (int8[5] memory) {
        if (idx == 0) {
            return pluck(tokenId, "WEAPON", weapons);
        }

        if (idx == 1) {
            return pluck(tokenId, "CHEST", chestArmor);
        }

        if (idx == 2) {
            return pluck(tokenId, "HEAD", headArmor);
        }

        if (idx == 3) {
            return pluck(tokenId, "WAIST", waistArmor);
        }

        if (idx == 4) {
            return pluck(tokenId, "FOOT", footArmor);
        }

        if (idx == 5) {
            return pluck(tokenId, "HAND", handArmor);
        }

        if (idx == 6) {
            return  pluck(tokenId, "NECK", necklaces);
        }

        if (idx == 7) {
            return pluck(tokenId, "RING", rings);
        }

        return [int8(-1),-1,-1,-1,-1];
    }

    function validateEquipmentIdx(int8[5] memory equipment, uint8 idx) external pure returns(bool){
        if ((idx == 0) && (equipment[2] < 0 || equipment[2] > 17)) {
            return false;
        }

        if ((idx == 6) && (equipment[2] < 0 || equipment[2] > 2)) {
            return false;
        }

        if ((idx == 7) && (equipment[2] < 0 || equipment[2] > 4)) {
            return false;
        }

        if (equipment[2] < 0 || equipment[2] > 14) {
            return false;
        }

        if ((equipment[0] < -1) || (equipment[0] > 68)) {
            return false;
        }

        if ((equipment[1] < -1) || (equipment[1] > 17)) {
            return false;
        }

        if ((equipment[3] < -1) || (equipment[3] > 15)) {
            return false;
        } 

        if ((equipment[4] != -1) && (equipment[4] != 0)) {
            return false;
        }

        return true; 
    }

    function getEquipment(int8[5] memory equipment, uint8 idx) external view returns(string memory){
        if (idx == 0) {
            return getEquipmentName(equipment, weapons);
        }

        if (idx == 1) {
            return getEquipmentName(equipment, chestArmor);
        }

        if (idx == 2) {
            return getEquipmentName(equipment, headArmor);
        }

        if (idx == 3) {
            return getEquipmentName(equipment, waistArmor);
        }

        if (idx == 4) {
            return getEquipmentName(equipment, footArmor);
        }

        if (idx == 5) {
            return getEquipmentName(equipment, handArmor);
        }

        if (idx == 6) {
            return getEquipmentName(equipment, necklaces);
        }

        if (idx == 7) {
            return getEquipmentName(equipment, rings);
        }
        return "";
    }

    function getFieldNamePrefix(uint8 idx) external view returns(string memory){
        if ((idx >= 0) && (idx <= 68)) {
            return namePrefixes[idx];
        }
        return "";
    }

    function getFieldNameSuffix(uint8 idx) external view returns(string memory){
        if ((idx >= 0) && (idx <= 17)) {
            return nameSuffixes[idx];
        }
        return "";
    }

    function getFieldSuffix(uint8 idx) external view returns(string memory){
        if ((idx >= 0) && (idx <= 15)) {
            return suffixes[idx];
        }
        return "";
    }
}