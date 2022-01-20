// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IBlitmap.sol";

//    _____                 _____                         
//   (, /  |          ,    (, /   )                       
//     /---| __  _/_         /__ /    __  __    _  __  _  
//  ) /    |_/ (_(___(_   ) /   \_(_(_/ (_/ (__(/_/ (_/_)_
// (_/                   (_/                              
//
//  10,000 NFT's generated mainly from the original 10,000 Chainrunners.
//  Each Anti Runner has a sibling Chain Runner.  When re-united with its
//  sibling, fun things happen.                            
//
//  This is a handy contract for converting a Blitmap layer into a Chainrunner
//  supported layer.
//

contract BlitmapCRConverter {
    address public blitmapAddress;

    struct BitmapCurser {
        uint8 colorIndex1;
        uint8 colorIndex2;
        uint8 colorIndex3;
        uint8 colorIndex4;
        uint8 colorIndex5;
        uint8 colorIndex6;
        uint8 colorIndex7;
        uint8 colorIndex8;
    }

    constructor(address _blitmapAddress) {
        blitmapAddress = _blitmapAddress;
    }

    function tokenNameOf(uint256 tokenId) external view returns (string memory) {
        return makeStringMultipleOf3(IBlitmap(blitmapAddress).tokenNameOf(tokenId));
    }

    function makeStringMultipleOf3(string memory input) private pure returns (string memory) {
        uint n = bytes(input).length % 3;
        if (n == 0) {
            return input;
        
        } else if (n == 1) {
            return string(abi.encodePacked(input, "  "));

        } else {
            return string(abi.encodePacked(input, " "));
        }
    }

    function getBlitmapLayer(uint256 tokenId) external view returns (bytes memory) {
        bytes memory data = IBlitmap(blitmapAddress).tokenDataOf(tokenId);

        bytes memory result = new bytes(416);

        for (uint i = 0; i < 4; i++) {
            result[4 * i] = data[3 * i];
            result[4 * i + 1] = data[3 * i + 1];
            result[4 * i + 2] = data[3 * i + 2];
            result[4 * i + 3] = bytes1(uint8(255));
        } 

        BitmapCurser memory cursor;

        for (uint i = 12; i < 268;) {
            cursor.colorIndex1 = blitMapColorIndex(data[i], 6, 7);
            cursor.colorIndex2 = blitMapColorIndex(data[i], 4, 5);
            cursor.colorIndex3 = blitMapColorIndex(data[i], 2, 3);
            cursor.colorIndex4 = blitMapColorIndex(data[i], 0, 1);

            cursor.colorIndex5 = blitMapColorIndex(data[i + 1], 6, 7);
            cursor.colorIndex6 = blitMapColorIndex(data[i + 1], 4, 5);
            cursor.colorIndex7 = blitMapColorIndex(data[i + 1], 2, 3);
            cursor.colorIndex8 = blitMapColorIndex(data[i + 1], 0, 1);

            bytes3 b3 = bitmapCursorToBytes3(cursor);
            result[(i-12) * 3/2 + 32] = b3[0];
            result[(i-12) * 3/2 + 33] = b3[1];
            result[(i-12) * 3/2 + 34] = b3[2];

            i+=2;
        }

        return result;
    }

    function blitMapColorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint8) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function bitmapCursorToBytes3(BitmapCurser memory cursor) internal pure returns (bytes3) {
        uint24 result = uint24(cursor.colorIndex1) << 21;
        result += uint24(cursor.colorIndex2) << 18;
        result += uint24(cursor.colorIndex3) << 15;
        result += uint24(cursor.colorIndex4) << 12;
        result += uint24(cursor.colorIndex5) << 9;
        result += uint24(cursor.colorIndex6) << 6;
        result += uint24(cursor.colorIndex7) << 3;
        result += uint24(cursor.colorIndex8);
        return bytes3(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBlitmap {
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory);
    function tokenNameOf(uint256 tokenId) external view returns (string memory);
}