// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./PlanetRing1Descriptor.sol";
import "./PlanetRing2Descriptor.sol";
import "./PlanetRing3Descriptor.sol";
import "../PlanetColor.sol";

library PlanetRingDescriptor {

  function getSVG(uint256 nSatellite_, PlanetColor.PlanetColorPalette memory planetColorPalette_) public pure returns (string memory svg) {

    svg = string(abi.encodePacked('<g class="ring"> '));
    if (nSatellite_ > 5 && nSatellite_ <= 10) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing1Descriptor.getSVG(planetColorPalette_)
        )
      );
    }

    if (nSatellite_ > 10 && nSatellite_ <= 15) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing2Descriptor.getSVG()
        )
      );
    }

    if (nSatellite_ > 15 && nSatellite_ <= 20) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing3Descriptor.getSVG()
        )
      );
    }

    svg = string(
      abi.encodePacked(
        svg,
        '</g> '
      )
    );

  }
}

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
pragma abicoder v2;

library PlanetRing2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path class="fill_ring" d="M449.18,121.1c-2.43-2.43-9.81-9.82-64.92,33.02c-13.99,10.89-29.37,23.71-45.6,38.02',
        'c-23.87,21.02-49.57,45.23-75.44,71.09c-25.83,25.83-50.01,51.5-71.01,75.33c-14.32,16.26-27.18,31.67-38.09,45.69',
        'c-42.84,55.11-35.45,62.5-33.02,64.93c1.7,1.7,4.12,2.49,7.2,2.49c20.07,0,67.02-34.19,108.76-73.2',
        'c-1.44-0.66-2.86-1.38-4.27-2.13c-45.96,42.77-78.21,62.7-95.23,68.73c-7.12,2.52-11.6,2.61-13.28,0.91',
        'c-0.72-0.7-5.88-8.46,33.39-58.96c10.65-13.7,23.16-28.71,37.1-44.55c21.12-24.03,45.52-49.96,71.64-76.07',
        'c26.13-26.14,52.1-50.57,76.14-71.7c15.81-13.92,30.8-26.4,44.46-37.04c50.5-39.27,58.26-34.11,58.98-33.39',
        'c0.43,0.43,3.22,4.09-5.1,20.48c-1.86,3.69-4.29,8.01-7.44,13.08c-8.96,14.43-26.21,38.86-57.72,73.59',
        'c0.77,1.41,1.5,2.84,2.21,4.27C420.62,188.85,461.1,133.02,449.18,121.1z"/> ',
        '<path class="fill_ring" d="M438.39,144c4.11-8.21,2.46-9.86,1.57-10.74c-4.38-4.39-23.86,7.18-57.87,34.38',
        'c-11.17,8.93-23.17,19.02-35.62,29.89c-24.91,21.78-51.63,46.77-76.98,72.14c-25.29,25.29-50.21,51.89-71.9,76.71',
        'c-10.95,12.52-21.09,24.59-30.04,35.79c-27.14,33.96-38.67,53.4-34.27,57.79c0.45,0.44,1.08,1.08,2.65,1.08',
        'c3.3,0,10.74-2.84,29.18-16.29c16.56-12.07,38.07-29.84,62.32-51.46c-0.9-0.53-1.79-1.08-2.65-1.65',
        'c-62.1,55.3-87.05,68.54-89.39,66.2c-1.3-1.3,2.32-13.53,34.5-53.79c8.84-11.05,18.81-22.93,29.58-35.27',
        'c21.77-24.9,46.76-51.6,72.14-77c25.47-25.47,52.29-50.55,77.28-72.38c12.25-10.71,24.07-20.62,35.07-29.43',
        'c40.35-32.25,52.59-35.89,53.89-34.59c2.32,2.33-10.91,27.23-66.14,89.3c0.57,0.87,1.11,1.75,1.65,2.64',
        'c21.58-24.21,39.31-45.69,51.39-62.22C431.91,155.3,436.07,148.61,438.39,144z"/> ',
        '<path class="fill_ring" d="M422.09,151.88c-2.41-2.43-18.07,8.77-46.53,33.27c-6.84,5.88-13.98,12.18-21.36,18.81',
        'c-24.15,21.72-50.77,47.02-76.98,73.25c-26.19,26.19-51.48,52.8-73.18,76.92c-6.64,7.39-12.98,14.57-18.87,21.42',
        'c-24.5,28.45-35.7,44.11-33.27,46.54c0.21,0.21,0.54,0.32,0.96,0.32c8.4,0,55.29-41.04,68.7-52.93c-0.42-0.29-0.84-0.59-1.26-0.89',
        'c-42.42,37.71-64.93,53.39-67.3,52.48c-1.18-3.11,18.87-28.89,52.1-65.84c20.14-22.41,45.15-48.93,73.18-76.96',
        'c28.07-28.06,54.61-53.08,77.04-73.26c36.91-33.2,62.66-53.27,65.69-52.11c0.97,2.47-14.67,24.93-52.35,67.32',
        'c0.32,0.4,0.61,0.82,0.9,1.24C382.14,207.26,426.63,156.42,422.09,151.88z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetRing3Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.6;" class="fill_ring" d="M411.17,180.15c91.21,27.57,108.84,102.78,39.36,167.98c-69.48,65.22-199.75,95.73-290.97,68.16',
        's-108.83-102.78-39.35-168c33.08-31.05,79.94-54.22,129.81-67c-17.52,5.6-33.06,15.65-45.29,28.79',
        'c-25.8,11.31-49.12,25.95-67.63,43.33c-62.39,58.53-46.56,126.06,35.32,150.81c41.55,12.55,92.13,11.68,140.04,0.13',
        'c46.49-11.2,90.45-32.47,121.17-61.32c62.37-58.55,46.56-126.06-35.33-150.81c-23.64-7.15-50.2-9.95-77.54-8.9',
        'c-11.88-4.59-24.78-7.11-38.28-7.11c-5.28,0-10.47,0.39-15.54,1.14C316.75,167.07,368.29,167.19,411.17,180.15z"/> ',
        '<path style="opacity:0.55;" class="fill_ring" d="M388.85,201.11c75.02,22.68,89.51,84.54,32.37,138.16c-25.45,23.88-60.82,42.12-98.86,52.99',
        'c-47.37,13.53-98.85,15.66-140.46,3.08c-75.03-22.68-89.52-84.54-32.37-138.18c12.1-11.36,26.44-21.44,42.25-30.05',
        'c-2.37,3.85-4.49,7.88-6.34,12.03c-9.89,6.26-18.96,13.17-26.99,20.71c-53.4,50.11-39.87,107.91,30.24,129.11',
        'c35.21,10.63,77.97,10.02,118.59,0.42c40.27-9.51,78.43-27.85,105.02-52.8c53.4-50.11,39.85-107.93-30.24-129.1',
        'c-9.87-2.99-20.32-5.07-31.17-6.33c-3.46-2.93-7.11-5.62-10.93-8.1C357.11,193.88,373.64,196.52,388.85,201.11z"/> ',
        '<path style="opacity:0.75;" class="fill_ring" d="M392.24,197.91c-18.06-5.46-37.93-8.23-58.53-8.57c2.13,1.17,4.2,2.41,6.24,3.71',
        'c17.16,0.82,33.69,3.46,48.9,8.05c75.02,22.68,89.51,84.54,32.37,138.16c-25.46,23.88-60.82,42.12-98.86,53',
        'c-47.37,13.53-98.85,15.66-140.46,3.07c-75.03-22.68-89.52-84.54-32.37-138.18c12.11-11.35,26.45-21.44,42.25-30.05',
        'c1.26-2.05,2.58-4.06,3.98-6.03c-19.11,9.66-36.41,21.33-50.68,34.72c-59.03,55.39-44.06,119.3,33.42,142.71',
        'c42.89,12.96,95.93,10.82,144.75-3.09c39.41-11.19,76.08-30.06,102.43-54.81C484.7,285.23,469.73,221.34,392.24,197.91z"/> ',
        '<path style="opacity:0.8;" class="fill_ring" d="M398.32,192.23c-23.64-7.15-50.2-9.94-77.54-8.89c2.73,1.05,5.4,2.21,8.03,3.48',
        'c23.22-0.13,45.64,2.7,65.89,8.8c79.26,23.96,94.56,89.31,34.18,145.98c-29.71,27.9-72.24,48.5-117.22,59.36',
        'c-46.38,11.19-95.37,12.05-135.62-0.12c-79.26-23.97-94.57-89.32-34.18-145.99c15.91-14.94,35.52-27.78,57.2-38.15',
        'c1.8-2.28,3.69-4.48,5.68-6.61c-25.8,11.31-49.12,25.95-67.63,43.34c-62.39,58.53-46.56,126.06,35.32,150.81',
        'c41.55,12.55,92.13,11.69,140.04,0.14c46.48-11.21,90.45-32.48,121.17-61.32C496.01,284.49,480.2,216.98,398.32,192.23z"/> ',
        '<path style="opacity:0.35;" class="fill_ring" d="M382.06,207.48c-9.87-2.98-20.32-5.07-31.17-6.33c4.1,3.42,7.92,7.16,11.43,11.18',
        'c0.9,0.96,1.77,1.92,2.62,2.91c2.31,0.57,4.61,1.2,6.86,1.88c62.66,18.95,74.76,70.6,27.03,115.39',
        'c-13.29,12.46-29.8,23.1-48.09,31.53c-28.34,13.06-60.89,20.85-92.16,22.08c-21.01,0.84-41.44-1.3-59.62-6.79',
        'c-62.66-18.93-74.76-70.59-27.03-115.39c2.31-2.16,4.73-4.28,7.23-6.33c1.53-6.39,3.64-12.55,6.29-18.45',
        'c-9.89,6.25-18.96,13.17-26.98,20.71c-53.4,50.11-39.87,107.91,30.24,129.11c35.21,10.63,77.97,10.02,118.59,0.42',
        'c40.28-9.51,78.44-27.85,105.02-52.8C465.7,286.47,452.15,228.66,382.06,207.48z"/> '
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