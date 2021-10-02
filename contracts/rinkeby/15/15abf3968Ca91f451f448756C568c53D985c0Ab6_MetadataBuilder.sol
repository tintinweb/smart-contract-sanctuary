/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/MetadataBuilder.sol
// SPDX-License-Identifier: GPL-3.0 AND GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0 >=0.8.6 <0.9.0;

////// src/MetadataUtils.sol
/* pragma solidity ^0.8.0; */

function toString(uint256 value) pure returns (string memory) {
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

////// src/MetadataBuilder.sol

/// @title A library used to convert multi-part RLE compressed images to SVG
/// From: https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/libs/MetadataBuilder.sol

/* pragma solidity ^0.8.6; */

/* import { Base64 } from './MetadataUtils.sol'; */

library MetadataBuilder {
    struct SVGParams {
        bytes[] parts;
        string background;
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
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(
        string memory title,
        string memory name,
        SVGParams memory params,
        mapping(uint8 => string[]) storage palettes
    ) public view returns (string memory svg) {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<style>@font-face { font-family: "d"; src: url(data:application/octet-stream;base64,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);}</style>'
                '<style>.base { fill: #fff; font-family: d; font-size: 14px; }</style>',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '<text x="160" y="25" with="320" text-anchor="middle" class="base">', title, '</text><text x="160" y="303" with="320" text-anchor="middle" class="base">', name, '</text>',
                '</svg>'
            )
        );
    }

    /// @dev Opensea contract metadata: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI(string calldata name, string calldata description) external pure returns (string memory) {
        string memory json = string(abi.encodePacked('{ "name": "', name, '", ', '"description" : ', description, '}'));
        string memory encodedJson = Base64.encode(bytes(json));
        string memory output = string(abi.encodePacked('data:application/json;base64,', encodedJson));
        return output;
    }

    function tokenURI(
        string calldata text,
        string calldata subtext,
        string calldata name,
        string calldata description,
        string calldata attributes,
        SVGParams memory params,
        mapping(uint8 => string[]) storage palettes
    ) external view returns (string memory) {
        string memory output = Base64.encode(bytes(generateSVG(text, subtext, params, palettes)));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        name,
                        '", ',
                        '"description" : "',
                        description,
                        '", ',
                        '"image": "data:image/svg+xml;base64,',
                        output,
                        '", '
                        '"attributes": ',
                        attributes,
                        '}'
                    )
                )
            )
        );
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        string[65] memory lookup = [
            '0', '5', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55', '60', '65', '70', '75', 
            '80', '85', '90', '95', '100', '105', '110', '115', '120', '125', '130', '135', '140', '145', '150', '155', 
            '160', '165', '170', '175', '180', '185', '190', '195', '200', '205', '210', '215', '220', '225', '230', '235', 
            '240', '245', '250', '255', '260', '265', '270', '275', '280', '285', '290', '295', '300', '305', '310', '315',
            '320'
        ];
        string memory rects;
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="5" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }

        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }
}