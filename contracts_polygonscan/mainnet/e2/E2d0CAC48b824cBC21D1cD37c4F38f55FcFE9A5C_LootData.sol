// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LootData {
    string[] public weapons = [
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

    string[] public chestArmor = [
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

    string[] public headArmor = [
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

    string[] public waistArmor = [
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

    string[] public footArmor = [
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

    string[] public handArmor = [
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

    string[] public necklaces = [
    "Necklace",
    "Amulet",
    "Pendant"
    ];

    string[] public rings = [
    "Gold Ring",
    "Silver Ring",
    "Bronze Ring",
    "Platinum Ring",
    "Titanium Ring"
    ];

    string[] public suffixes = [
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

    string[] public namePrefixes = [
    "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble",
    "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation",
    "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe",
    "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic",
    "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain",
    "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow",
    "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
    "Light's", "Shimmering"
    ];

    string[] public nameSuffixes = [
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

    function getWeapons() public view returns (string[] memory) {
        return weapons;
    }

    function getChest() public view returns (string[]  memory) {
        return chestArmor;
    }

    function getHead() public view returns (string[]  memory){
        return headArmor;
    }

    function getWaist() public view returns (string[]  memory){
        return waistArmor;
    }

    function getFoot() public view returns (string[]  memory){
        return footArmor;
    }

    function getHand() public view returns (string[]  memory){
        return handArmor;
    }

    function getNecklaces() public view returns (string[]  memory){
        return necklaces;
    }

    function getRings() public view returns (string[]  memory){
        return rings;
    }

    function getSuffixes() public view returns (string[]  memory){
        return suffixes;
    }

    function getNamePrefixes() public view returns (string[]  memory){
        return namePrefixes;
    }

    function getNameSuffixes() public view returns (string[] memory){
        return nameSuffixes;
    }
}

