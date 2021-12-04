/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

pragma solidity ^0.8.0;

contract Sluggy {

    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
    string name;
    string png;
  }

    // mapping from trait type (index) to its name
    string[9] private _traitTypes = [
        "Body",
        "Head",
        "Spell",
        "Eye",
        "Neck",
        "Mouth",
        "Wings",
        "Wand",
        "Rank"
    ];

    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;

    constructor() {}

    function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) public{
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    /** RENDER */

    /**
   * generates an <image> element using base64 encoded PNGs
   * @param trait the trait storing the PNG data
   * @return the <image> element
   */

   function drawTrait(Trait memory trait) internal pure returns (string memory) {
       return string(abi.encodePacked(
           '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
           trait.png,
           '"/>'
       ));
   }

   /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @return a valid SVG of the Wizard / Dragon
   */

   function drawSVG(uint8 type1,uint8 type2,uint8 type3,uint8 type4) internal view returns (string memory) {
       string memory svgString = string(abi.encodePacked(
           drawTrait(traitData[0][type1]),
           drawTrait(traitData[1][type2]),
           drawTrait(traitData[2][type3]),
           drawTrait(traitData[3][type4])
       ));

       return string(abi.encodePacked(
           '<svg id="sluggy" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
           svgString,
           "</svg>"
       ));

   }

   function showSVG(uint8 c1,uint8 c2,uint8 c3,uint8 c4) external view returns (string memory) {
       return string(abi.encodePacked(
           'data: image/svg+xml;base64,',
           base64(bytes(drawSVG(c1,c2,c3,c4)))

       ));
   }

   /** BASE 64 - Written by Brech Devos */
   string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
   function base64(bytes memory data) internal pure returns (string memory) {
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