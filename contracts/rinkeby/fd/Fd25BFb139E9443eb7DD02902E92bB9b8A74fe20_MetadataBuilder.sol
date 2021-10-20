/**
 *Submitted for verification at Etherscan.io on 2021-10-19
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
        return '0';
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
    bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

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

////// src/MetadataBuilder.sol

/// @title A library used to convert multi-part RLE compressed images to SVG
/// From: https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/libs/MetadataBuilder.sol

/* pragma solidity ^0.8.6; */

/* import { Base64, toString } from './MetadataUtils.sol'; */

library DisplayTypes {
    uint8 constant NONE = 0x0;
    uint8 constant RANKING = 0x1;
    uint8 constant NUMBER = 0x2;
    uint8 constant BOOST_PERCENT = 0x3;
    uint8 constant BOOST_NUMBER = 0x4;
    uint8 constant DATE = 0x5;
}

library MetadataBuilder {
    bytes16 internal constant HEX = '0123456789abcdef';

    struct Params {
        uint8 resolution;
        bytes4 color;
        bytes4 background;
        bytes4 viewbox;
        string text;
        string subtext;
        string name;
        string description;
        string attributes;
        bytes[] parts;
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
    function generateSVG(Params memory params, mapping(uint8 => bytes4[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                generateStyles(params),
                '<rect width="100%" height="100%" fill="#', toColor(params.background), '" />',
                generateText(params), generateSVGRects(params, palettes),
                '</svg>'
            )
        );
    }

    function generateStyles(Params memory params) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<style>@font-face { font-family: "d"; src: url(data:application/octet-stream;base64,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);}</style>',
                    '<style>.base { fill: #',
                    toColor(params.color),
                    '; font-family: d; font-size: 14px; }</style>'
                )
            );
    }

    function generateText(Params memory params) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="160" y="25" with="320" text-anchor="middle" class="base">',
                    params.text,
                    '</text><text x="160" y="303" with="320" text-anchor="middle" class="base">',
                    params.subtext,
                    '</text>'
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

    function tokenURI(Params memory params, mapping(uint8 => bytes4[]) storage palettes)
        external
        view
        returns (string memory)
    {
        string memory output = Base64.encode(bytes(generateSVG(params, palettes)));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        params.name,
                        '", ',
                        '"description" : "',
                        params.description,
                        '", ',
                        '"image": "data:image/svg+xml;base64,',
                        output,
                        '", '
                        '"attributes": ',
                        params.attributes,
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
    function generateSVGRects(Params memory params, mapping(uint8 => bytes4[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        string[] memory lookup = new string[](params.resolution + 1);
        uint16 step = 320 / params.resolution;
        string memory stepstr = toString(step);
        for (uint16 i = 0; i <= 320; i += step) {
            lookup[i/step] = toString(i);
        }

        string memory rects;
        for (uint8 p = 0; p < params.parts.length; p++) {
            if (params.parts[p].length == 0) {
                continue;
            }
        
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            bytes4[] storage palette = palettes[image.paletteIndex];
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
                    buffer[cursor + 3] = toColor(palette[rect.colorIndex]); // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer, stepstr)));
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
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer, stepstr)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer, string memory height) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="', height, '" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
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

    function attributes(bytes[] calldata traits) external pure returns (string memory) {
        string memory res = string(abi.encodePacked('['));

        for (uint256 i = 0; i < traits.length; i++) {
            if (traits[i].length == 0) {
                continue;
            }

            res = string(abi.encodePacked(res, trait(traits[i])));
        }

        res = string(abi.encodePacked(res, ']'));
        return res;
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(bytes calldata t) internal pure returns (string memory) {
        (uint8 d, string memory typ, bytes memory v) = abi.decode(t, (uint8, string, bytes));

        string memory value = '';
        if (d == DisplayTypes.NONE) {
            value = abi.decode(v, (string));
            value = string(abi.encodePacked('"', value, '"'));
        } else {
            uint256 num = abi.decode(v, (uint256));
            value = string(abi.encodePacked(toString(num)));
        }

        if (d == DisplayTypes.RANKING) {
            return string(abi.encodePacked('{', '"trait_type": "', typ, '", ', '"value": ', value, '}'));
        }

        string memory display = '';
        if (d == DisplayTypes.NUMBER) {
            display = string(abi.encodePacked('"display_type": "number", '));
        } else if (d == DisplayTypes.BOOST_NUMBER) {
            display = string(abi.encodePacked('"display_type": "boost_number", '));
        } else if (d == DisplayTypes.BOOST_PERCENT) {
            display = string(abi.encodePacked('"display_type": "boost_percentage", '));
        } else if (d == DisplayTypes.DATE) {
            display = string(abi.encodePacked('"display_type": "date", '));
        }

        return string(abi.encodePacked('{"trait_type": "', typ, '", ', display, '"value": ', value, '}'));
    }

    function toColor(bytes4 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(8);
        for (uint256 i = 0; i < value.length; i++) {
            buffer[i * 2 + 1] = HEX[uint8(value[i]) & 0xf];
            buffer[i * 2] = HEX[uint8(value[i] >> 4) & 0xf];
        }
        return string(buffer);
    }
}