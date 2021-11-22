// SPDX-License-Identifier: CC0-1.0

/// @title Rendering code to draw an svg of the dungeon

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

import { IDungeons } from './interfaces/IDungeons.sol';

contract dungeonsRender {

     struct Maps {
        // Data structure that stores our different maps (layout, doors, points)
        uint256[] layout;
        uint256[] doors;
        uint256[] points;
    }

    struct RenderHelper {   // Helper variables when iterating through and drawing dungeon tiles
        uint256 pixel;
        uint256 start;
        uint256[] layout;
        string parts;
        uint256 counter;
        uint256 numRects;
        uint256 lastStart;
    }

    struct EntityHelper {
        uint256 size;
        uint256 environment;
    }

    string[24] private colors = [
        // Array contains sets of 4 colors:
        // 0 = bg, 1 = wall, 2 = door, 3 = point
        // To calculate, multiply environment (int 0-5) by 4 and add the above numbers.
        // Desert
        "F3D899",   // 0
        "160F09",   // 1
        "FAAA00",   // 2
        "00A29D",   // 3
        // Stone Temple
        "967E67",   // 4
        "F3D899",   // 5
        "3C2A1A",   // 6
        "006669",   // 7
        // Forest Ruins
        "2F590E",   // 8
        "A98C00",   // 9
        "802F1A",   // 10
        "C55300",   // 11
        // Mountain Deep
        "36230F",   // 12
        "744936",   // 13
        "802F1A",   // 14
        "FFA800",   // 15
        //Underwater Keep
        "006669",   // 16
        "004238",   // 17
        "967E67",   // 18
        "F9B569",   // 19
        // Ember"s Glow
        "340D07",   // 20
        "5D0503",   // 21
        "B75700",   // 22
        "FF1800"    // 23
    ];

    string[6] private environmentName = [
        // Names mapped to the above colors
        "Desert Oasis",
        "Stone Temple",
        "Forest Ruins",
        "Mountain Deep",
        "Underwater Keep",
        "Ember's Glow"
    ];
    
    function draw(IDungeons.Dungeon memory dungeon, uint8[] memory x, uint8[] memory y, uint8[] memory entityData) external view returns (string memory) {
        // Hardcoded to save memory: Width = 100

        string memory parts;

        // Setup SVG and draw our background
        // We write at 100x100 and scale it 5x to 500x500 to avoid safari small rendering
        parts = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500" shape-rendering="crispEdges" transform-origin="center"><rect width="100%" height="100%" fill="#',
            colors[dungeon.environment * 4],
            '" />'));

        // Draw the name at the top of the image
        parts = drawNameplate(parts, dungeon.dungeonName);

        // Draw the dungeon layout and entities
        (uint256 start, uint256 pixel) = getWidth(dungeon.size);   // Calculate width of each pixel and where we should start the dungeon
        
        RenderHelper memory helper = RenderHelper(pixel, start, fromBytes(dungeon.layout), "", 0, 0, 0);    // Struct to save memory for render calls so we don't get 'stack too deep' in our drawChunk() function

        parts = string(abi.encodePacked(
            parts, 
            chunkDungeon(dungeon, helper),  // Break dungeon walls into chunks and render each section
            drawEntities(x, y, entityData, dungeon, helper),
            '</svg>'));
        
        return parts; 
    }

    function drawNameplate(string memory parts, string memory name) internal pure returns (string memory) {
    // Draw a nameplate w/ map title at the top of the map.
        // Calculate length of string
        uint256 nameLength = uint256(bytes(name).length);   
        uint256 fontSize;
        uint256 multiplier;
        if(nameLength <= 25) {
            fontSize = 5;
            multiplier = 3;
        } else {
            fontSize = 4;
            multiplier = 2;
            nameLength += 7;   // Hack because we can't use fractions for our multiplier
        }

        // Draw black border behind nameplates
        parts = string(
                abi.encodePacked(
                    parts,
                    '<g transform="scale (5 5)"><rect x="', // Scale nameplate by 5x (transform for 100->500)
                    toString((100 - ((nameLength+3)*multiplier)) / 2),    // assume letters are 3 'pixels', add 3 letters worth of spacing (1.5 per side)
                    '" y="-1" width="',
                    toString((nameLength+3)*multiplier),
                    '" height="9" stroke-width="0.3" stroke="black" fill="#FFA800" />'
                ));

        // Draw text on top of nameplate
        parts = string(
                    abi.encodePacked(
                        parts,
                        '<text x="50" y="5.5" width="',
                        toString(nameLength * 3),
                        '" font-family="monospace" font-size="',
                        toString(fontSize), 
                        '" text-anchor="middle">',
                        name,
                        '</text></g>'
                    ));
        
        return(parts);
    }

    function chunkDungeon(IDungeons.Dungeon memory dungeon, RenderHelper memory helper) internal view returns (string memory) {
        // Loop through and figure out how many rectangles we'll need (so we can calculate array size)
        
        for(uint256 y = 0; y < dungeon.size; y++) {
            
            helper.lastStart = helper.counter;
            string memory rowParts;

            for(uint256 x = 0; x < dungeon.size; x++) {
                if(getBit(helper.layout, helper.counter) == 1 && helper.counter > 0 && getBit(helper.layout, helper.counter-1) == 0) {
                    // Last tile was a wall, current tile is floor. Need a new rect.
                    helper.numRects++;

                    // Draw rect with last known X and width of currentX - lastX.
                    rowParts = drawTile(rowParts, helper.start + (helper.lastStart % dungeon.size)*helper.pixel, helper.start + (helper.lastStart / dungeon.size)*helper.pixel, (helper.counter - helper.lastStart)*helper.pixel, helper.pixel, colors[dungeon.environment * 4 + 1]);

                } else if(getBit(helper.layout, helper.counter) == 0 && helper.counter > 0 && getBit(helper.layout, helper.counter-1) == 1) {
                    // Last tile was a floor, start tracking X so we can get a width
                    helper.lastStart = helper.counter;
                }
                helper.counter++;
            }

            // If the last tile on a row is a wall, we need a new rect
            if(getBit(helper.layout, helper.counter-1) == 0) {
                helper.numRects++;
                rowParts = drawTile(rowParts, helper.start + (helper.lastStart % dungeon.size)*helper.pixel, helper.start + (helper.lastStart / dungeon.size)*helper.pixel, (helper.counter - helper.lastStart)*helper.pixel, helper.pixel, colors[dungeon.environment * 4 + 1]);
            }
            helper.parts = string(abi.encodePacked(helper.parts, rowParts));
            rowParts = "";  // Reset for the next row
        }
        return helper.parts;
    }

    function drawEntities(uint8[] memory x, uint8[] memory y, uint8[] memory entityData, IDungeons.Dungeon memory dungeon, RenderHelper memory helper) internal view returns (string memory) {
    // Draw each entity as a pixel on the map
        string memory parts;
        for(uint256 i = 0; i < entityData.length; i++) {
            parts = drawTile(parts, helper.start + (x[i] % dungeon.size)*helper.pixel, helper.start + y[i]*helper.pixel, helper.pixel, helper.pixel, colors[dungeon.environment * 4 + 2 + entityData[i]]);
        }
        return parts;
    }


    function drawTile(string memory row, uint256 x, uint256 y, uint256 width, uint256 pixel, string memory color) internal pure returns(string memory) {
        row = string(
            abi.encodePacked(
                row,
                '<rect x="',
                toString(x),
                '" y="',
                toString(y),
                '" width="', 
                toString(width),
                '" height="',
                toString(pixel),
                '" fill="#',
                color, 
                '" />'
            ));
        
        return(row);

    }

    function getWidth(uint256 size) internal pure returns(uint256, uint256) {
        uint256 pixel = 500 / (size + 3*2);   // Each 'pixel' should be equal widths and take into account dungeon size + allocate padding (3 pixels) on both sides
        uint256 start = (500 - pixel*size) / 2;     // Remove the width and divide by two to get the midpoint where we should start
        return(start, pixel);
    }

    /**
    * @dev - Assembles a tokenURI for output. Normally we would do this in dungeons.sol but needed to save memory
    */
    function tokenURI(uint256 tokenId, IDungeons.Dungeon memory dungeon, uint256[] memory entities) public view returns(string memory) {
        string memory output; 

        // Generate dungeon
        output = this.draw(dungeon, dungeon.entities.x, dungeon.entities.y, dungeon.entities.entityType);

        string memory size = string(abi.encodePacked(toString(dungeon.size), 'x', toString(dungeon.size)));

        // Base64 Encode svg and output
        string memory json = Base64.encode(bytes(string(
            abi.encodePacked('{"name": "Crypts and Caverns #', toString(tokenId),
             '", "description": "Crypts and Caverns is an onchain map generator that produces an infinite set of dungeons. Enemies, treasure, etc intentionally omitted for others to interpret. Feel free to use Crypts and Caverns in any way you want.", "attributes": [ {"trait_type": "name", "value": "',
             dungeon.dungeonName, 
             '"}, {"trait_type": "size", "value": "',
             size, 
             '"}, {"trait_type": "environment", "value": "',
             environmentName[dungeon.environment],
             '"}, {"trait_type": "doors", "value": "',
             toString(entities[1]),
             '"}, {"trait_type": "points of interest", "value": "',
             toString(entities[0]), 
             '"}, {"trait_type": "affinity", "value": "',
             dungeon.affinity,
             '"}, {"trait_type": "legendary", "value": "',
             dungeon.legendary == 1 ? 'Yes' : 'No',
             '"}, {"trait_type": "structure", "value": "',
             dungeon.structure == 0 ? 'Crypt' : 'Cavern',
             '"}],"image": "data:image/svg+xml;base64,',
              Base64.encode(bytes(output)),
             '"}'))));

        output = string(abi.encodePacked('data:application/json;base64,', json));
        
        return output;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    /* Bitwise Helper Functions */
    function getBit(uint256[] memory map, uint256 position) internal pure returns(uint256) {
    // Returns whether a bit is set or off at a given position in our map (credit: @cjpais)
        (uint256 quotient, uint256 remainder) = getDivided(position, 256);
        require(position <= 255 + (quotient * 256));
        return (map[quotient] >> (255 - remainder)) & 1;
    }


    function getDivided(uint256 numerator, uint256 denominator) public pure returns (uint256 quotient, uint256 remainder)
    {
        require(denominator > 0);
        quotient = numerator / denominator;
        remainder = numerator - denominator * quotient;
    }

    function getNumIntsRequired(bytes memory data) public pure returns (uint256)
    {
    // Calculate the number of ints needed to contain the number of bytes in data
        require(data.length > 0);

        (uint256 quotient, uint256 remainder) = getDivided(data.length, 32);

        if (remainder > 0) return quotient + 1;
        return quotient;
    }


    function fromBytes(bytes memory encodedMap) internal pure returns (uint256[] memory) {
    // Converts a bytes array to a map (two uint256)
        uint256 num = getNumIntsRequired(encodedMap);
        uint256[] memory result = new uint256[](num);

        uint256 offset = 0;
        uint256 x;

        for (uint256 i = 0; i < num; i++) {
            assembly {
                x := mload(add(encodedMap, add(0x20, offset)))
                mstore(add(result, add(0x20, offset)), x)
            }
            offset += 0x20;
        }

        return result;
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Crypts and Caverns

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

interface IDungeons {
    struct Dungeon {
        uint8 size;
        uint8 environment;
        uint8 structure;  // crypt or cavern
        uint8 legendary;
        bytes layout;
        EntityData entities;
        string affinity;
        string dungeonName;
    }

    struct EntityData {
        uint8[] x;
        uint8[] y;
        uint8[] entityType;
    }

    function claim(uint256 tokenId) external payable;
    function claimMany(uint256[] memory tokenArray) external payable;
    function ownerClaim(uint256 tokenId) external payable;
    function mint() external payable;
    function openClaim() external;
    function withdraw(address payable recipient, uint256 amount) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getLayout(uint256 tokenId) external view returns (bytes memory);
    function getSize(uint256 tokenId) external view returns (uint8);
    function getEntities(uint256 tokenId) external view returns (uint8[] memory, uint8[] memory, uint8[] memory);
    function getEnvironment(uint256 tokenId) external view returns (uint8);
    function getName(uint256 tokenId) external view returns (string memory);
    function getNumPoints(uint256 tokenId) external view returns (uint256);
    function getNumDoors(uint256 tokenId) external view returns (uint256);
    function getSvg(uint256 tokenId) external view returns (string memory);
}