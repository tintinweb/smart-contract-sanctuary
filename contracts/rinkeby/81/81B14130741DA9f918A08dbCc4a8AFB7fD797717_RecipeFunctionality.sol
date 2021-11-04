//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './ItemTokenId.sol';
import './MaterialTokenId.sol';
import './MaterialFunctionality.sol';
import './ItemFunctionality.sol';
import './Strings.sol';


library RecipeFunctionality {

    struct RecipeFeatures {
        string recipeName;
        string gemName;
        string runeName;
        string materialName; 
        string charmName; 
        string toolName;
        string elementName; 
        string requirementName;
        uint recipeId;
        uint gemId;
        uint runeId;
        uint materialId; 
        uint charmId; 
        uint toolId;
        uint elementId; 
        uint requirementId;
    }

    function compareStrings(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function _itemId(
        uint256 tokenId,
        function(uint256) view returns (uint256[5] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint256[5] memory components = componentsFn(tokenId);
        return ItemTokenId.toId(components, itemType);
    }

    
    function weaponComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "WEAPON", 18);
    }

    function chestComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "CHEST", 15);
    }

    function headComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "HEAD", 15);
    }

    function waistComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "WAIST", 15);
    }

    function footComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "FOOT", 15);
    }

    function handComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "HAND", 15);
    }

    function neckComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "NECK", 3);
    }

    function ringComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return ItemFunctionality.itemPluck(tokenId, "RING", 5);
    }


    function getRecipeName(uint tokenId, bool vanilla) public view returns(string memory) {
        uint256 rand = MaterialFunctionality.random(string(abi.encodePacked(Strings.toString(tokenId)))) % 8;
        string memory vanillaOutput;
        string memory fullOutput;
        uint256[5] memory components;
        uint256 itemType;

        if (rand == 0){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, weaponComponents, 0x0));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, weaponComponents, 0x0));
        } 
        else if (rand == 1){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, chestComponents, 0x1));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, chestComponents, 0x1));
        }
        else if (rand == 2){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, waistComponents, 0x3));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, waistComponents, 0x3));
        }
        else if (rand == 3){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, footComponents, 0x4));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, footComponents, 0x4));
        }
        else if (rand == 4){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, headComponents, 0x2));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, headComponents, 0x2));
        }
        else if (rand == 5){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, handComponents, 0x5));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, handComponents, 0x5));
        }        
        else if (rand == 6){
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, neckComponents, 0x6));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, neckComponents, 0x6));
        }        
        else {
            (components, itemType) = ItemTokenId.fromId(_itemId(tokenId, ringComponents, 0x7));
            fullOutput = ItemFunctionality.tokenName(_itemId(tokenId, ringComponents, 0x7));
        }

        vanillaOutput = ItemFunctionality.itemName(itemType, components[0]);

        if (vanilla) {
            return vanillaOutput;
        }
        return fullOutput;

    }

    function getRareItem(uint tokenId, uint itemType) public pure returns(string memory, uint) {
        uint256 rand = MaterialFunctionality.random(string(abi.encodePacked(Strings.toString(tokenId))));
        uint256[1] memory index;


        string[2] memory rareGems = [
            'Diamond',
            'Skull'
        ];

        uint8[2] memory rareGemsIndices = [
            5,
            6
        ];

        string[6] memory rareRunes = [
            'Eth Rune',
            'Sol Rune',
            'Ohm Rune',
            'Avax Rune',
            'Fantom Rune',
            'Dot Rune'
        ];

        uint8[6] memory rareRunesIndices = [
            30,
            31,
            32,
            33,
            34,
            35
        ];

        string[8] memory rareMaterials = [
            'Holopad',
            'Obsidian',
            'Flametal',
            'Black Metal',
            'Dragon Skin',
            'Demon Hide',
            'Holy Water',
            'Force Crystals'
        ];

        uint8[8] memory rareMaterialsIndices = [
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16
        ];

        string[13] memory rareCharms = [
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

        uint8[13] memory rareCharmsIndices = [
            21,
            22,
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
            31,
            32,
            33
        ];

        string[6] memory rareElements = [
            'Spirit',
            'Power',
            'Time',
            'Infinity',
            'Space',
            'Reality'
        ];

        uint8[6] memory rareElementsIndices = [
            6,
            7,
            8,
            9,
            10,
            11 
        ];

        if (itemType == 0x0) {
            rand = rand % 2;
            index[0] = rareGemsIndices[rand];
            return (rareGems[rand], MaterialTokenId.toId(index, 0x0));
        }
        else if (itemType == 0x1) {
            rand = rand % 6;
            index[0] = rareRunesIndices[rand];
            return (rareRunes[rand], MaterialTokenId.toId(index, 0x1));
        }
        else if (itemType == 0x2) {
            rand = rand % 8;
            index[0] = rareMaterialsIndices[rand];
            return (rareMaterials[rand], MaterialTokenId.toId(index, 0x2));
        }
        else if (itemType == 0x3) {
            rand = rand % 13;
            index[0] = rareCharmsIndices[rand];
            return (rareCharms[rand], MaterialTokenId.toId(index, 0x3));
        }
        else {
            rand = rand % 6;
            index[0] = rareElementsIndices[rand];
            return (rareElements[rand], MaterialTokenId.toId(index, 0x5));
        }
    }

    function getRecipeRequirements(uint tokenId) public view returns(RecipeFeatures memory){

        RecipeFeatures memory recipeFeatures;
        uint256[1] memory index;
        uint256 rand = MaterialFunctionality.random(string(abi.encodePacked(Strings.toString(tokenId))));

        bool legendary = false; 

        recipeFeatures.recipeId = tokenId;
        recipeFeatures.recipeName = getRecipeName(tokenId, true);

        //check if legendary:
        if (compareStrings(recipeFeatures.recipeName, 'Light Saber')) {
            //require specific item
            recipeFeatures.materialName = 'Force Crystals';
            index[0] = 16;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Katana')){
            //require specific item
            recipeFeatures.materialName = 'Flametal';
            index[0] = 11;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Obsidian Blade')){
            //require specific item
            recipeFeatures.materialName = 'Obsidian';
            index[0] = 10;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Divine Robe') || compareStrings(recipeFeatures.recipeName, 'Divine Hood') || compareStrings(recipeFeatures.recipeName, 'Divine Gloves')) {
            //require specific item
            recipeFeatures.charmName = 'Ethereal Charm';
            index[0] = 25;
            recipeFeatures.charmId = MaterialTokenId.toId(index, 0x3);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Ethereal Silk Robe') || compareStrings(recipeFeatures.recipeName, 'Ethereal Silk Hood') || compareStrings(recipeFeatures.recipeName, 'Ethereal Silk Gloves')){
            //require specific item
            recipeFeatures.materialName = 'Silk';
            index[0] = 7;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Holo Robe')){
            //require specific item
            recipeFeatures.materialName = 'Holopad';
            index[0] = 9;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Holy Gauntlets')){
            //require specific item
            recipeFeatures.materialName = 'Holy Water';
            index[0] = 15;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Infinity Gauntlets')){
            //require specific item
            recipeFeatures.elementName = 'Infinity';
            index[0] = 9;
            recipeFeatures.elementId = MaterialTokenId.toId(index, 0x5);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Space Ring')){
            //require specific item
            recipeFeatures.elementName = 'Space';
            index[0] = 10;
            recipeFeatures.elementId = MaterialTokenId.toId(index, 0x5);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Reality Ring')){
            //require specific item
            recipeFeatures.elementName = 'Reality'; 
            index[0] = 11;
            recipeFeatures.elementId = MaterialTokenId.toId(index, 0x5);
            legendary = true; 
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Chrono Ring')){
            //require specific item
            recipeFeatures.elementName = 'Time';
            index[0] = 8;
            recipeFeatures.elementId = MaterialTokenId.toId(index, 0x5);
            legendary = true; 
        }
        //check if uncommon
        else if (compareStrings(recipeFeatures.recipeName, 'Demon Husk') || compareStrings(recipeFeatures.recipeName, 'Demonhide Belt') || compareStrings(recipeFeatures.recipeName, 'Demonhide Boots') || compareStrings(recipeFeatures.recipeName, "Demon's Hands")) {
            //require specific item
            recipeFeatures.materialName = 'Demon Hide';
            index[0] = 14;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Dragonskin Armor') || compareStrings(recipeFeatures.recipeName, 'Dragonskin Belt') || compareStrings(recipeFeatures.recipeName, 'Dragonskin Boots') || compareStrings(recipeFeatures.recipeName, "Dragonskin Gloves")) {
            //require specific item
            recipeFeatures.materialName = 'Dragon Skin';
            index[0] = 13;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Holy Chestplate') || compareStrings(recipeFeatures.recipeName, 'Holy Sandles')) {
            //require specific item
            recipeFeatures.materialName = 'Holy Water';
            index[0] = 15;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Hard Leather Belt') || compareStrings(recipeFeatures.recipeName, 'Leather Belt') || compareStrings(recipeFeatures.recipeName, 'Hard Leather Gloves') || compareStrings(recipeFeatures.recipeName, 'Leather Gloves')) {
            //require specific item
            recipeFeatures.materialName = 'Leather Hide';
            index[0] = 6;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Brightsilk Sash') || compareStrings(recipeFeatures.recipeName, 'Silk Sash') ||  compareStrings(recipeFeatures.recipeName, 'Silk Slippers')) {
            //require specific item
            recipeFeatures.materialName = 'Silk';
            index[0] = 7;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Wool Gloves')) {
            //require specific item
            recipeFeatures.materialName = 'Wool';
            index[0] = 8;
            recipeFeatures.materialId = MaterialTokenId.toId(index, 0x2);
        }
        else if (compareStrings(recipeFeatures.recipeName, 'Divine Slippers')) {
            //require specific item
            recipeFeatures.charmName = 'Ethereal Charm';
            index[0] = 25;
            recipeFeatures.charmId = MaterialTokenId.toId(index, 0x3);
        }
        //check if rare
        else if (compareStrings(recipeFeatures.recipeName, 'Ghost Wand') || compareStrings(recipeFeatures.recipeName, 'Grimoire') || compareStrings(recipeFeatures.recipeName, 'Chronicle') || compareStrings(recipeFeatures.recipeName, 'Ornate Gauntlets')){
            //require rare item
            if (rand % 5 == 0) {
                (recipeFeatures.gemName, recipeFeatures.gemId) = getRareItem(tokenId, 0x0);
            }
            else if (rand % 5 == 1) {
                (recipeFeatures.runeName, recipeFeatures.runeId) = getRareItem(tokenId, 0x1);
            }
            else if (rand % 5 == 2) {
                (recipeFeatures.charmName, recipeFeatures.charmId) = getRareItem(tokenId, 0x3);
            }
            else if (rand % 5 == 3) {
                (recipeFeatures.elementName, recipeFeatures.elementId) = getRareItem(tokenId, 0x5);
            }
            else {
                (recipeFeatures.materialName, recipeFeatures.materialId) = getRareItem(tokenId, 0x2);
            }
        }

        //fill rare item for legendary: 
        if (legendary) {
            //require rare item
            if (rand % 5 == 0) {
                (recipeFeatures.gemName, recipeFeatures.gemId) = getRareItem(tokenId, 0x0);
            }
            else if (rand % 5 == 1 && (compareStrings(recipeFeatures.elementName, ''))){
                (recipeFeatures.elementName, recipeFeatures.elementId) = getRareItem(tokenId, 0x5);
            }
            else if (rand % 5 == 2 && (compareStrings(recipeFeatures.charmName, ''))) {
                (recipeFeatures.charmName, recipeFeatures.charmId) = getRareItem(tokenId, 0x3);
            }
            else if (rand % 5 == 3 && (compareStrings(recipeFeatures.materialName, ''))) {
                (recipeFeatures.materialName, recipeFeatures.materialId) = getRareItem(tokenId, 0x2);
            }
            else {
                (recipeFeatures.runeName, recipeFeatures.runeId) = getRareItem(tokenId, 0x1);
            }
        }

        //fill in rest of the requirements 
        if (compareStrings(recipeFeatures.gemName, '')){
            recipeFeatures.gemId = MaterialFunctionality.gemId(tokenId);
            recipeFeatures.gemName = MaterialFunctionality.materialTokenName(recipeFeatures.gemId);
        }
        if (compareStrings(recipeFeatures.runeName, '')){
            recipeFeatures.runeId = MaterialFunctionality.runeId(tokenId);
            recipeFeatures.runeName = MaterialFunctionality.materialTokenName(recipeFeatures.runeId);
        }
        if (compareStrings(recipeFeatures.charmName, '')){
            recipeFeatures.charmId = MaterialFunctionality.charmId(tokenId);
            recipeFeatures.charmName = MaterialFunctionality.materialTokenName(recipeFeatures.charmId);
        }
        if (compareStrings(recipeFeatures.elementName, '')){
            recipeFeatures.elementId = MaterialFunctionality.elementId(tokenId);
            recipeFeatures.elementName = MaterialFunctionality.materialTokenName(recipeFeatures.elementId);
        }
        if (compareStrings(recipeFeatures.materialName, '')){
            recipeFeatures.materialId = MaterialFunctionality.materialId(tokenId);
            recipeFeatures.materialName = MaterialFunctionality.materialTokenName(recipeFeatures.materialId);
        }

        recipeFeatures.toolId = MaterialFunctionality.toolId(tokenId);
        recipeFeatures.toolName = MaterialFunctionality.materialTokenName(recipeFeatures.toolId);
        recipeFeatures.requirementId = MaterialFunctionality.requirementId(tokenId);
        recipeFeatures.requirementName = MaterialFunctionality.materialTokenName(recipeFeatures.requirementId);
        recipeFeatures.recipeName = getRecipeName(tokenId, false);

        return (recipeFeatures);
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