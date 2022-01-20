// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

import "../PlanetColor.sol";
pragma abicoder v2;

library PlanetRing1Descriptor {

  function getSVG(PlanetColor.PlanetColorPalette memory planetColorPalette_) public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="RING_1_LG_1" gradientUnits="userSpaceOnUse" ',
        'x1="156.6662" y1="302.3599" x2="892.5151" y2="251.0216"> ',
        '<stop  offset="0" style="stop-color:#A7B8C3"/> ',
        '<stop  offset="0.4969" style="stop-color:#', planetColorPalette_.colorRing,'"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#RING_1_LG_1);" d="M398.16,150.23',
        'c-8.8-7.07-34.07,8.43-66.15,38.25c0.6,0.31,1.2,0.63,1.8,0.97c29.55-27.79,52.37-42.39,59.95-36.31',
        'c7.79,6.22-2.1,32.76-23.79,68.95c-1.59,2.66-3.26,5.39-4.98,8.14c-4.42,7.09-9.24,14.5-14.43,22.17',
        'c-0.52,0.79-1.08,1.61-1.63,2.41c-12.33,18.04-26.66,37.39-42.47,57.13c-4.66,5.84-9.31,11.52-13.95,17.06',
        'c-2.04,2.44-4.08,4.84-6.09,7.21c-14.48,16.98-28.62,32.38-41.8,45.64c-2.4,2.41-4.76,4.75-7.08,7.02',
        'c-32.91,32.1-58.75,49.54-66.95,42.99c-8.52-6.82,4.14-37.98,30.29-79.53c-0.86,0.12-1.74,0.22-2.61,0.33',
        'c-26.76,43.43-39.21,76.38-29.55,84.12c9.46,7.59,37.98-10.91,73.51-45.21c2.59-2.5,5.23-5.1,7.91-7.79',
        'c14.43-14.45,29.82-31.26,45.44-49.82c2.04-2.4,4.05-4.81,6.08-7.27c3.06-3.7,6.12-7.45,9.18-11.27',
        'c17.06-21.31,32.34-42.24,45.3-61.7c0.52-0.78,1.04-1.56,1.55-2.32c3.88-5.88,7.54-11.61,10.96-17.18',
        'c1.55-2.5,3.03-4.96,4.47-7.39C396.74,187.17,407.27,157.52,398.16,150.23z"/> ',
        '<linearGradient id="RING_1_LG_2" gradientUnits="userSpaceOnUse" ',
        'x1="99.5356" y1="330.8851" x2="901.7024" y2="252.0497"> ',
        '<stop offset="0" style="stop-color:#A7B8C3"/> ',
        '<stop offset="0.4969" style="stop-color:#', planetColorPalette_.colorRing,'"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#RING_1_LG_2);" d="M457.59,259.11',
        'c-2.59-10.86-31.42-14.16-74.25-10.5c0.2,0.63,0.41,1.25,0.6,1.88c39.7-3.64,66.15-1.14,68.38,8.23',
        'c2.3,9.53-20.89,24.06-59,39.06c-1.92,0.77-3.88,1.52-5.89,2.28c-24.06,9.14-53.45,18.36-85.78,26.66',
        'c-2.03,2.46-4.04,4.88-6.08,7.27c33.99-8.47,65.05-18.15,90.7-27.94c2.42-0.93,4.79-1.85,7.11-2.78',
        'C434.85,286.74,460.25,270.21,457.59,259.11z',
        'M285.98,330.6c-29.07,6.97-56.74,12.29-81.33,15.85c-0.91,0.14-1.83,0.27-2.73,0.41c-0.97,0.14-1.92,0.27-2.89,0.41',
        'c-0.23,0.03-0.46,0.06-0.69,0.09c-53.23,7.23-90.54,5.84-93.22-5.37c-2.54-10.59,26.4-27.36,72.31-44.09',
        'c-0.12-0.69-0.21-1.38-0.29-2.07c-48.7,18.06-79.45,36.72-76.54,48.89c3.06,12.72,42.21,15.07,97.68,7.96',
        'c0.87-0.11,1.75-0.21,2.61-0.33c0.29-0.05,0.55-0.08,0.81-0.11c0.19-0.03,0.38-0.05,0.57-0.07',
        'c25.41-3.41,54.09-8.78,84.17-15.95c2.01-2.37,4.05-4.77,6.09-7.21C290.34,329.55,288.17,330.08,285.98,330.6z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
import "../utils/PlanetRandom.sol";

library PlanetColor {

  struct PlanetColorPalette {
    string colorSurface;
    string colorBase;
    string colorRing;
  }

  function getPlanetColor(uint temperature_, bytes32 blockhashInit_,  uint offsetRandom_) public pure returns (PlanetColorPalette memory planetColorPalette, uint offsetRandom) {

    uint newOffsetRandom;

    // select random palette color
    uint randomColorSurface = PlanetRandom.calcRandom(0,3, blockhashInit_, offsetRandom_);
    newOffsetRandom = offsetRandom_ + 1124;
    uint randomColorBase = PlanetRandom.calcRandom(0,3, blockhashInit_, newOffsetRandom);
    newOffsetRandom = newOffsetRandom + 1124;
    uint randomColorRing = PlanetRandom.calcRandom(0,3, blockhashInit_, newOffsetRandom);
    newOffsetRandom = newOffsetRandom + 1124;

    string[3] memory planetColorSurfaceList;
    string[3] memory planetColorBaseList;
    string[3] memory planetColorRingList;
    PlanetColorPalette memory planetColorPaletteTemp;

    if (temperature_ < 193) {
      planetColorSurfaceList = ["F5FAF6","90CA9C","787A78"];
      planetColorBaseList = ["0A5F84","856A18","04916F"];
      planetColorRingList = ["751E87","10871D","87802B"];
    } else if (temperature_ < 213) {
      planetColorSurfaceList = ["7D5191","544A91","918B60"];
      planetColorBaseList = ["0C6A74","067341","113673"];
      planetColorRingList = ["D8D8D8","8DCFD9","D6AB89"];
    } else if (temperature_ < 233) {
      planetColorSurfaceList = ["8F97FF","A432CA","46C9DF"];
      planetColorBaseList = ["194D8C","8C894A","614A8A"];
      planetColorRingList = ["B4EBA0","EBDD59","EB6A4D"];
    } else if (temperature_ < 253) {
      planetColorSurfaceList = ["26171B","172619","733B4A"];
      planetColorBaseList = ["9FD7F2","F2CEA0","5D8DA6"];
      planetColorRingList = ["CCC922","6E23CC","807E0B"];
    } else if (temperature_ < 273) {
      planetColorSurfaceList = ["7D5191","410087","1C003B"];
      planetColorBaseList = ["0b670b","086424","630908"];
      planetColorRingList = ["1454C9","C99014","806838"];
    } else if (temperature_ < 293) {
      planetColorSurfaceList = ["FFFF00","B3091D","FFAA52"];
      planetColorBaseList = ["420087","8E1919","1C003B"];
      planetColorRingList = ["070E87","8A700B","D48B20"];
    } else if (temperature_ < 313) {
      planetColorSurfaceList = ["C50034","007810","86129A"];
      planetColorBaseList = ["6C78AC","ABA75B","8874AB"];
      planetColorRingList = ["410087","33870E","870780"];
    } else if (temperature_ < 333) {
      planetColorSurfaceList = ["0A0A8F","56118F","8F6118"];
      planetColorBaseList = ["C87D4F","61C790","C7A058"];
      planetColorRingList = ["77BD69","A37DBD","BD5F57"];
    } else if (temperature_ < 353) {
      planetColorSurfaceList = ["8E1919","478F21","8F138F"];
      planetColorBaseList = ["FFFF00","FF0095","B30068"];
      planetColorRingList = ["E0940E","004894","945F04"];
    } else if (temperature_ < 373) {
      planetColorSurfaceList = ["FF5C37","B33215","039560"];
      planetColorBaseList = ["FFD55B","B3912E","B35D0C"];
      planetColorRingList = ["1CC5E5","007F99","199908"];
    }

    planetColorPaletteTemp.colorSurface = planetColorSurfaceList[randomColorSurface];
    planetColorPaletteTemp.colorBase = planetColorBaseList[randomColorBase];
    planetColorPaletteTemp.colorRing = planetColorRingList[randomColorRing];

    planetColorPalette = planetColorPaletteTemp;
    offsetRandom = newOffsetRandom;

  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';


library PlanetRandom {

  /**
   * @notice Return random number from blockhash
   * @dev min include, max exclude
   */
  function calcRandom(uint256 min_, uint256 max_, bytes32 blockhash_, uint256 payload_) public pure returns (uint256) {
    uint256 randomHash = uint(keccak256(abi.encodePacked(blockhash_, payload_)));
    return (randomHash % (max_ - min_)) + min_;
  }

  function getRandomHash(bytes32 blockhash_, uint256 payload_) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(blockhash_, payload_));
  }

  function calcRandomBytes1(uint256 min_, uint256 max_, bytes32 randomHash_, uint index_) public pure returns (uint) {
    uint randomHashIndex;
    if ( index_ == 31 ) {
      randomHashIndex = uint(uint8(randomHash_[index_])) * (uint8(randomHash_[0]));
    } else {
      randomHashIndex = uint(uint8(randomHash_[index_])) * (uint8(randomHash_[index_ + 1]));
    }
    return ((randomHashIndex ) % (max_ - min_)) + min_;
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