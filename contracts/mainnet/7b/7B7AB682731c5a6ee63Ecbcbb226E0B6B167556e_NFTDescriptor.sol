// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

pragma solidity ^0.8.6;

import {Base64} from "./Base64.sol";
import {MultiPartRLEToSVG} from "./MultiPartRLEToSVG.sol";

library NFTDescriptor {
  struct TokenURIParams {
    string name;
    string description;
    bytes parts;
    string background;
    uint16[] animatedPixels;
  }

  /**
   * @notice Construct an ERC721 token URI.
   */
  function constructTokenURI(TokenURIParams memory params, string[] storage palette)
    public
    view
    returns (string memory)
  {
    string memory image = generateSVGImage(
      MultiPartRLEToSVG.SVGParams({
        parts: params.parts,
        background: params.background,
        animatedPixels: params.animatedPixels
      }),
      palette
    );

    // prettier-ignore
    return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
  }

  /**
   * @notice Generate an SVG image for use in the ERC721 token URI.
   */
  function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, string[] storage palette)
    public
    view
    returns (string memory svg)
  {
    return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palette)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
  string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

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
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

pragma solidity ^0.8.6;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library MultiPartRLEToSVG {
  using Strings for uint256;
  struct SVGParams {
    bytes parts;
    string background;
    uint16[] animatedPixels;
  }

  struct ContentBounds {
    uint8 top;
    uint8 right;
    uint8 bottom;
    uint8 left;
  }

  struct Rect {
    uint8 length;
    uint8 colorIndex;
  }

  struct DecodedImage {
    ContentBounds bounds;
    uint256 width;
    Rect[] rects;
  }

  /**
   * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(SVGParams memory params, string[] storage palette) internal view returns (string memory svg) {
    // prettier-ignore
    return
      string(
        abi.encodePacked(
          '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
          '<rect width="100%" height="100%" fill="#',
          params.background,
          '" />',
          _generateSVGRects(params, palette),
          _generateUseHref(params),
          "</svg>"
        )
      );
  }

  function _generateUseHref(SVGParams memory params) private pure returns (string memory svg) {
    string memory chunk;
    for (uint256 i = 1; i <= params.animatedPixels.length; i++) {
      chunk = string(abi.encodePacked(chunk, '<use href="#animated', i.toString(), '"/>'));
    }
    return chunk;
  }

  /**
   * @notice Given RLE image parts and color palettes, generate SVG rects.
   */
  // prettier-ignore
  function _generateSVGRects(SVGParams memory params, string[] storage palette)
        private
        view
        returns (string memory svg)
    {
        string[33] memory lookup = [
            "0", "10", "20", "30", "40", "50", "60", "70", 
            "80", "90", "100", "110", "120", "130", "140", "150", 
            "160", "170", "180", "190", "200", "210", "220", "230", 
            "240", "250", "260", "270", "280", "290", "300", "310",
            "320" 
        ];
        string memory rects;
        DecodedImage memory image = _decodeRLEImage(params.parts);
        uint256 currentX = image.bounds.left;
        uint256 currentY = image.bounds.top;
        string[4] memory buffer;
        string memory part;
        uint8 blueCount;
        uint16[] memory animatedPixels = params.animatedPixels;

        for (uint256 i = 0; i < image.rects.length; i++) {
            Rect memory rect = image.rects[i];
            if (rect.colorIndex != 0) {
                buffer[0] = lookup[rect.length];      // width
                buffer[1] = lookup[currentX];         // x
                buffer[2] = lookup[currentY];         // y
                buffer[3] = palette[rect.colorIndex - 1]; // color

                bool isDroolRect = false;
                for (uint8 j = 0; j < animatedPixels.length; j++) {
                    if(i == animatedPixels[j]){
                        isDroolRect = true;
                        blueCount++;
                    }
                }  
                part = string(abi.encodePacked(part, _getChunk(buffer, isDroolRect, blueCount)));
            }

            currentX += rect.length;
            if (currentX - image.bounds.left == image.width) {
                currentX = image.bounds.left;
                currentY++;
            }
        }
        rects = string(abi.encodePacked(rects, part));
        return rects;
    }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  // prettier-ignore
  //TODO pure
  function _getChunk(string[4] memory buffer, bool isDroolRect, uint256 i) private pure returns (string memory) {
        if(isDroolRect){
            return string(
                abi.encodePacked(
                    '<rect id="animated', i.toString(), '" width="', buffer[0], '" height="10" x="', buffer[1], '" y="', buffer[2], '" fill="#', buffer[3], '"><animate calcMode="discrete" attributeName="height" values="10; 10; 10; 20; 30; 20; 10;"  dur="1.5s" repeatCount="indefinite" /></rect>'
                )
            );
        }else{
            return string(
                abi.encodePacked(
                    '<rect width="', buffer[0], '" height="10" x="', buffer[1], '" y="', buffer[2], '" fill="#', buffer[3], '" />'
                )
            );
        }         
    }

  /**
   * @notice Decode a single RLE compressed image into a `DecodedImage`.
   */
  function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });
    uint256 width = bounds.right - bounds.left;

    uint256 cursor;
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);

    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({length: uint8(image[i]), colorIndex: uint8(image[i + 1])});

      cursor++;
    }
    return DecodedImage({bounds: bounds, width: width, rects: rects});
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