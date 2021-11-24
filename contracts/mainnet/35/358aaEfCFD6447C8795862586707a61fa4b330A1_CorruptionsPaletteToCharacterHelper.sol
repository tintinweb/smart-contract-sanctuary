// SPDX-License-Identifier: Unlicense
// intended for internal use only (but have fun with it if you want)

pragma solidity^0.8.0;

contract CorruptionsPaletteToCharacterHelper { 
    struct Cursor {
        uint256 x;
        uint256 y;
    }

    function prepareCanvas(string[] memory charPaletteStrings, uint256 numChars, bytes memory composition) external pure returns (string[32] memory) {
        require(composition.length == 961, "RenderHelper: wrong length");
        bytes[256] memory charPalette;
        bytes[32] memory canvas;
        string[32] memory canvasString;
        for (uint8 i = 0; i < 32; i++) {
            canvasString[i] = "&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;";
            canvas[i] = bytes(canvasString[i]);
        }
        Cursor memory cursor;
        for (uint256 i = 0; i < numChars; i++) {
            charPalette[i] = bytes(charPaletteStrings[i]);
        }

        for (uint256 i = 0; i < 961; i++) {
            canvas[cursor.y][cursor.x * 9]      = charPalette[uint8(composition[i])][0];
            canvas[cursor.y][cursor.x * 9 + 1]  = charPalette[uint8(composition[i])][1];
            canvas[cursor.y][cursor.x * 9 + 2]  = charPalette[uint8(composition[i])][2];
            canvas[cursor.y][cursor.x * 9 + 3]  = charPalette[uint8(composition[i])][3];
            canvas[cursor.y][cursor.x * 9 + 4]  = charPalette[uint8(composition[i])][4];
            canvas[cursor.y][cursor.x * 9 + 5]  = charPalette[uint8(composition[i])][5];
            canvas[cursor.y][cursor.x * 9 + 6]  = charPalette[uint8(composition[i])][6];
            canvas[cursor.y][cursor.x * 9 + 7]  = charPalette[uint8(composition[i])][7];
            canvas[cursor.y][cursor.x * 9 + 8]  = charPalette[uint8(composition[i])][8];
            
            cursor.x++;
            if (cursor.x > 30) {
                cursor.x = 0;
                cursor.y++;
            }
        }

        for (uint256 i = 0; i < 32; i++) {
            canvasString[i] = string(canvas[i]);
        }

        return canvasString;
    }
}