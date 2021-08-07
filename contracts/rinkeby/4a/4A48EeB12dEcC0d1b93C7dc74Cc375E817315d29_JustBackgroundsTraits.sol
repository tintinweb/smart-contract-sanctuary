// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @author jpegmint.xyz

library JustBackgroundsTraits {

    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    struct ColorTraits {
        string hexCode;
        string name;
        string family;
        string source;
        string brightness;
        string special;
    }
    
    function getColorTraits(bytes6 colorBytes) external pure returns (ColorTraits memory traits) {
        traits = ColorTraits(
            _extractColorHexCode(colorBytes),
            _extractColorName(colorBytes),
            _extractColorFamily(colorBytes),
            _extractColorSource(colorBytes),
            _extractColorBrightness(colorBytes),
            _extractColorSpecial(colorBytes)
        );
    }

    function _extractColorHexCode(bytes6 colorBytes) internal pure returns (string memory) {
        uint8 r = uint8(colorBytes[0]);
        uint8 g = uint8(colorBytes[1]);
        uint8 b = uint8(colorBytes[2]);
        bytes memory buffer = new bytes(6);
        buffer[0] = _HEX_SYMBOLS[r >> 4 & 0xf];
        buffer[1] = _HEX_SYMBOLS[r & 0xf];
        buffer[2] = _HEX_SYMBOLS[g >> 4 & 0xf];
        buffer[3] = _HEX_SYMBOLS[g & 0xf];
        buffer[4] = _HEX_SYMBOLS[b >> 4 & 0xf];
        buffer[5] = _HEX_SYMBOLS[b & 0xf];
        return string(buffer);
    }

    function _extractColorFamily(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[4];

             if (bits == 0x00) trait = 'Blue Colors';
        else if (bits == 0x01) trait = 'Brown Colors';
        else if (bits == 0x02) trait = 'Gray Colors';
        else if (bits == 0x03) trait = 'Green Colors';
        else if (bits == 0x04) trait = 'Orange Colors';
        else if (bits == 0x05) trait = 'Pink Colors';
        else if (bits == 0x06) trait = 'Purple Colors';
        else if (bits == 0x07) trait = 'Red Colors';
        else if (bits == 0x08) trait = 'White Colors';
        else if (bits == 0x09) trait = 'Yellow Colors';
    }

    function _extractColorSource(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[5] & 0x03;

             if (bits == 0x00) trait = 'CSS Color';
        else if (bits == 0x01) trait = 'HTML Basic';
        else if (bits == 0x02) trait = 'HTML Extended';
        else if (bits == 0x03) trait = 'Other';
    }

    function _extractColorBrightness(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = (colorBytes[5] >> 2) & 0x03;

             if (bits == 0x00) trait = 'Dark';
        else if (bits == 0x01) trait = 'Light';
        else if (bits == 0x02) trait = 'Medium';
    }

    function _extractColorSpecial(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = (colorBytes[5] >> 4) & 0x0F;

             if (bits == 0x00) trait = 'None';
        else if (bits == 0x01) trait = 'Gems';
        else if (bits == 0x02) trait = 'HEX Word';
        else if (bits == 0x03) trait = 'Meme';
        else if (bits == 0x04) trait = 'Metallic';
        else if (bits == 0x05) trait = 'Real Word';
        else if (bits == 0x06) trait = 'Transparent';
        else if (bits == 0x07) trait = 'Twin';
        else if (bits == 0x08) trait = 'Woods';
    }

    function _extractColorName(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[3];

             if (bits == 0x00) trait = 'Acacia';
        else if (bits == 0x01) trait = 'Accede';
        else if (bits == 0x02) trait = 'Access';
        else if (bits == 0x03) trait = 'Acetic';
        else if (bits == 0x04) trait = 'Acidic';
        else if (bits == 0x05) trait = 'Addict';
        else if (bits == 0x06) trait = 'Adobes';
        else if (bits == 0x07) trait = 'Affect';
        else if (bits == 0x08) trait = 'Alice Blue';
        else if (bits == 0x09) trait = 'Amber';
        else if (bits == 0x0A) trait = 'Amethyst';
        else if (bits == 0x0B) trait = 'Antique White';
        else if (bits == 0x0C) trait = 'Aqua';
        else if (bits == 0x0D) trait = 'Aquamarine';
        else if (bits == 0x0E) trait = 'Ash';
        else if (bits == 0x0F) trait = 'Assess';
        else if (bits == 0x10) trait = 'Assets';
        else if (bits == 0x11) trait = 'Assist';
        else if (bits == 0x12) trait = 'Attest';
        else if (bits == 0x13) trait = 'Attics';
        else if (bits == 0x14) trait = 'Azure';
        else if (bits == 0x15) trait = 'Babies';
        else if (bits == 0x16) trait = 'Baffed';
        else if (bits == 0x17) trait = 'Basics';
        else if (bits == 0x18) trait = 'Beaded';
        else if (bits == 0x19) trait = 'Beasts';
        else if (bits == 0x1A) trait = 'Bedded';
        else if (bits == 0x1B) trait = 'Beefed';
        else if (bits == 0x1C) trait = 'Beige';
        else if (bits == 0x1D) trait = 'Bidets';
        else if (bits == 0x1E) trait = 'Birch';
        else if (bits == 0x1F) trait = 'Bisque';
        else if (bits == 0x20) trait = 'Black';
        else if (bits == 0x21) trait = 'Blanched Almond';
        else if (bits == 0x22) trait = 'Blue';
        else if (bits == 0x23) trait = 'Blue Violet';
        else if (bits == 0x24) trait = 'Boasts';
        else if (bits == 0x25) trait = 'Bobbed';
        else if (bits == 0x26) trait = 'Bobcat';
        else if (bits == 0x27) trait = 'Bodies';
        else if (bits == 0x28) trait = 'Boobie';
        else if (bits == 0x29) trait = 'Bosses';
        else if (bits == 0x2A) trait = 'Brass';
        else if (bits == 0x2B) trait = 'Bronze';
        else if (bits == 0x2C) trait = 'Brown';
        else if (bits == 0x2D) trait = 'Burly Wood';
        else if (bits == 0x2E) trait = 'Caddie';
        else if (bits == 0x2F) trait = 'Cadet Blue';
        else if (bits == 0x30) trait = 'Ceased';
        else if (bits == 0x31) trait = 'Cedar';
        else if (bits == 0x32) trait = 'Chartreuse';
        else if (bits == 0x33) trait = 'Cherry';
        else if (bits == 0x34) trait = 'Chocolate';
        else if (bits == 0x35) trait = 'Cicada';
        else if (bits == 0x36) trait = 'Coffee';
        else if (bits == 0x37) trait = 'Cootie';
        else if (bits == 0x38) trait = 'Copper';
        else if (bits == 0x39) trait = 'Coral';
        else if (bits == 0x3A) trait = 'Cornflower Blue';
        else if (bits == 0x3B) trait = 'Cornsilk';
        else if (bits == 0x3C) trait = 'Crimson';
        else if (bits == 0x3D) trait = 'Cyan';
        else if (bits == 0x3E) trait = 'Dabbed';
        else if (bits == 0x3F) trait = 'Daffed';
        else if (bits == 0x40) trait = 'Dark Blue';
        else if (bits == 0x41) trait = 'Dark Cyan';
        else if (bits == 0x42) trait = 'Dark Goldenrod';
        else if (bits == 0x43) trait = 'Dark Gray';
        else if (bits == 0x44) trait = 'Dark Green';
        else if (bits == 0x45) trait = 'Dark Khaki';
        else if (bits == 0x46) trait = 'Dark Magenta';
        else if (bits == 0x47) trait = 'Dark Olive Green';
        else if (bits == 0x48) trait = 'Dark Orange';
        else if (bits == 0x49) trait = 'Dark Orchid';
        else if (bits == 0x4A) trait = 'Dark Red';
        else if (bits == 0x4B) trait = 'Dark Salmon';
        else if (bits == 0x4C) trait = 'Dark Sea Green';
        else if (bits == 0x4D) trait = 'Dark Slate Blue';
        else if (bits == 0x4E) trait = 'Dark Slate Gray';
        else if (bits == 0x4F) trait = 'Dark Turquoise';
        else if (bits == 0x50) trait = 'Dark Violet';
        else if (bits == 0x51) trait = 'Debase';
        else if (bits == 0x52) trait = 'Decade';
        else if (bits == 0x53) trait = 'Decide';
        else if (bits == 0x54) trait = 'Deeded';
        else if (bits == 0x55) trait = 'Deep Pink';
        else if (bits == 0x56) trait = 'Deep Sky Blue';
        else if (bits == 0x57) trait = 'Deface';
        else if (bits == 0x58) trait = 'Defeat';
        else if (bits == 0x59) trait = 'Defect';
        else if (bits == 0x5A) trait = 'Detect';
        else if (bits == 0x5B) trait = 'Detest';
        else if (bits == 0x5C) trait = 'Diamond';
        else if (bits == 0x5D) trait = 'Dibbed';
        else if (bits == 0x5E) trait = 'Dim Gray';
        else if (bits == 0x5F) trait = 'Diodes';
        else if (bits == 0x60) trait = 'Dissed';
        else if (bits == 0x61) trait = 'Dodger Blue';
        else if (bits == 0x62) trait = 'Doodad';
        else if (bits == 0x63) trait = 'Dotted';
        else if (bits == 0x64) trait = 'Eddies';
        else if (bits == 0x65) trait = 'Efface';
        else if (bits == 0x66) trait = 'Effect';
        else if (bits == 0x67) trait = 'Emerald';
        else if (bits == 0x68) trait = 'Estate';
        else if (bits == 0x69) trait = 'Facade';
        else if (bits == 0x6A) trait = 'Facets';
        else if (bits == 0x6B) trait = 'Fascia';
        else if (bits == 0x6C) trait = 'Fasted';
        else if (bits == 0x6D) trait = 'Fibbed';
        else if (bits == 0x6E) trait = 'Fiesta';
        else if (bits == 0x6F) trait = 'Fir';
        else if (bits == 0x70) trait = 'Fire Brick';
        else if (bits == 0x71) trait = 'Fitted';
        else if (bits == 0x72) trait = 'Floral White';
        else if (bits == 0x73) trait = 'Footed';
        else if (bits == 0x74) trait = 'Forest Green';
        else if (bits == 0x75) trait = 'Fuchsia';
        else if (bits == 0x76) trait = 'Gainsboro';
        else if (bits == 0x77) trait = 'Ghost White';
        else if (bits == 0x78) trait = 'Gold';
        else if (bits == 0x79) trait = 'Goldenrod';
        else if (bits == 0x7A) trait = 'Gray';
        else if (bits == 0x7B) trait = 'Green';
        else if (bits == 0x7C) trait = 'Green Yellow';
        else if (bits == 0x7D) trait = 'Honey Dew';
        else if (bits == 0x7E) trait = 'Hot Pink';
        else if (bits == 0x7F) trait = 'Indian Red';
        else if (bits == 0x80) trait = 'Indigo';
        else if (bits == 0x81) trait = 'Ivory';
        else if (bits == 0x82) trait = 'Jade';
        else if (bits == 0x83) trait = 'Khaki';
        else if (bits == 0x84) trait = 'Lavender';
        else if (bits == 0x85) trait = 'Lavender Blush';
        else if (bits == 0x86) trait = 'Lawn Green';
        else if (bits == 0x87) trait = 'Lemon Chiffon';
        else if (bits == 0x88) trait = 'Light Blue';
        else if (bits == 0x89) trait = 'Light Coral';
        else if (bits == 0x8A) trait = 'Light Cyan';
        else if (bits == 0x8B) trait = 'Light Goldenrod Yellow';
        else if (bits == 0x8C) trait = 'Light Gray';
        else if (bits == 0x8D) trait = 'Light Green';
        else if (bits == 0x8E) trait = 'Light Pink';
        else if (bits == 0x8F) trait = 'Light Salmon';
        else if (bits == 0x90) trait = 'Light Sea Green';
        else if (bits == 0x91) trait = 'Light Sky Blue';
        else if (bits == 0x92) trait = 'Light Slate Gray';
        else if (bits == 0x93) trait = 'Light Steel Blue';
        else if (bits == 0x94) trait = 'Light Yellow';
        else if (bits == 0x95) trait = 'Lime';
        else if (bits == 0x96) trait = 'Lime Green';
        else if (bits == 0x97) trait = 'Linen';
        else if (bits == 0x98) trait = 'Magenta';
        else if (bits == 0x99) trait = 'Mahogany';
        else if (bits == 0x9A) trait = 'Maple';
        else if (bits == 0x9B) trait = 'Maroon';
        else if (bits == 0x9C) trait = 'Medium Aquamarine';
        else if (bits == 0x9D) trait = 'Medium Blue';
        else if (bits == 0x9E) trait = 'Medium Orchid';
        else if (bits == 0x9F) trait = 'Medium Purple';
        else if (bits == 0xA0) trait = 'Medium Sea Green';
        else if (bits == 0xA1) trait = 'Medium Slate Blue';
        else if (bits == 0xA2) trait = 'Medium Spring Green';
        else if (bits == 0xA3) trait = 'Medium Turquoise';
        else if (bits == 0xA4) trait = 'Medium Violet Red';
        else if (bits == 0xA5) trait = 'Midnight Blue';
        else if (bits == 0xA6) trait = 'Mint Cream';
        else if (bits == 0xA7) trait = 'Misty Rose';
        else if (bits == 0xA8) trait = 'Moccasin';
        else if (bits == 0xA9) trait = 'Navajo White';
        else if (bits == 0xAA) trait = 'Navy';
        else if (bits == 0xAB) trait = 'Oak';
        else if (bits == 0xAC) trait = 'Odessa';
        else if (bits == 0xAD) trait = 'Office';
        else if (bits == 0xAE) trait = 'Old Lace';
        else if (bits == 0xAF) trait = 'Olive';
        else if (bits == 0xB0) trait = 'Olive Drab';
        else if (bits == 0xB1) trait = 'Orange';
        else if (bits == 0xB2) trait = 'Orange Red';
        else if (bits == 0xB3) trait = 'Orchid';
        else if (bits == 0xB4) trait = 'Pale Goldenrod';
        else if (bits == 0xB5) trait = 'Pale Green';
        else if (bits == 0xB6) trait = 'Pale Turquoise';
        else if (bits == 0xB7) trait = 'Pale Violet Red';
        else if (bits == 0xB8) trait = 'Palladium';
        else if (bits == 0xB9) trait = 'Papaya Whip';
        else if (bits == 0xBA) trait = 'Patina';
        else if (bits == 0xBB) trait = 'Peach Puff';
        else if (bits == 0xBC) trait = 'Pearl';
        else if (bits == 0xBD) trait = 'Peru';
        else if (bits == 0xBE) trait = 'Pine';
        else if (bits == 0xBF) trait = 'Pink';
        else if (bits == 0xC0) trait = 'Platinum';
        else if (bits == 0xC1) trait = 'Plum';
        else if (bits == 0xC2) trait = 'Powder Blue';
        else if (bits == 0xC3) trait = 'Purple';
        else if (bits == 0xC4) trait = 'Pyrite';
        else if (bits == 0xC5) trait = 'Quartz';
        else if (bits == 0xC6) trait = 'Rebecca Purple';
        else if (bits == 0xC7) trait = 'Red';
        else if (bits == 0xC8) trait = 'Redwood';
        else if (bits == 0xC9) trait = 'Rose Gold';
        else if (bits == 0xCA) trait = 'Rose Quartz';
        else if (bits == 0xCB) trait = 'Rosewood';
        else if (bits == 0xCC) trait = 'Rosy Brown';
        else if (bits == 0xCD) trait = 'Royal Blue';
        else if (bits == 0xCE) trait = 'Ruby';
        else if (bits == 0xCF) trait = 'Saddle Brown';
        else if (bits == 0xD0) trait = 'Sadist';
        else if (bits == 0xD1) trait = 'Safest';
        else if (bits == 0xD2) trait = 'Salmon';
        else if (bits == 0xD3) trait = 'Sandy Brown';
        else if (bits == 0xD4) trait = 'Sapphire';
        else if (bits == 0xD5) trait = 'Sassed';
        else if (bits == 0xD6) trait = 'Scoffs';
        else if (bits == 0xD7) trait = 'Sea Green';
        else if (bits == 0xD8) trait = 'Sea Shell';
        else if (bits == 0xD9) trait = 'Seabed';
        else if (bits == 0xDA) trait = 'Secede';
        else if (bits == 0xDB) trait = 'Seeded';
        else if (bits == 0xDC) trait = 'Sienna';
        else if (bits == 0xDD) trait = 'Siesta';
        else if (bits == 0xDE) trait = 'Silver';
        else if (bits == 0xDF) trait = 'Sky Blue';
        else if (bits == 0xE0) trait = 'Slate Blue';
        else if (bits == 0xE1) trait = 'Slate Gray';
        else if (bits == 0xE2) trait = 'Snow';
        else if (bits == 0xE3) trait = 'Sobbed';
        else if (bits == 0xE4) trait = 'Spring Green';
        else if (bits == 0xE5) trait = 'Static';
        else if (bits == 0xE6) trait = 'Steel Blue';
        else if (bits == 0xE7) trait = 'Tabbed';
        else if (bits == 0xE8) trait = 'Tactic';
        else if (bits == 0xE9) trait = 'Tan';
        else if (bits == 0xEA) trait = 'Teak';
        else if (bits == 0xEB) trait = 'Teal';
        else if (bits == 0xEC) trait = 'Teased';
        else if (bits == 0xED) trait = 'Teases';
        else if (bits == 0xEE) trait = 'Tested';
        else if (bits == 0xEF) trait = 'Thistle';
        else if (bits == 0xF0) trait = 'Tictac';
        else if (bits == 0xF1) trait = 'Tidbit';
        else if (bits == 0xF2) trait = 'Toasts';
        else if (bits == 0xF3) trait = 'Toffee';
        else if (bits == 0xF4) trait = 'Tomato';
        else if (bits == 0xF5) trait = 'Tooted';
        else if (bits == 0xF6) trait = 'Transparent';
        else if (bits == 0xF7) trait = 'Transparent?';
        else if (bits == 0xF8) trait = 'Turquoise';
        else if (bits == 0xF9) trait = 'Violet';
        else if (bits == 0xFA) trait = 'Walnut';
        else if (bits == 0xFB) trait = 'Wheat';
        else if (bits == 0xFC) trait = 'White';
        else if (bits == 0xFD) trait = 'White Smoke';
        else if (bits == 0xFE) trait = 'Yellow';
        else if (bits == 0xFF) trait = 'Yellow Green';
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}