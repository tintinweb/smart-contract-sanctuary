/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/// @title The Nouns NFT descriptor

contract A {

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
    
    struct SVGParams {
        bytes[] parts;
        string background;
    }

    bytes[] public glasses;

    string[] public colors;

    uint public _s = 1000;

    mapping(uint8 => string[]) public Palettes;

    function setGlasses(bytes memory s) public {
        glasses.push(s);
    }

    function getIdx(string memory s, uint x) public pure returns(string memory y) {
        y = string(abi.encodePacked("",bytes(s)[x]));
    }

    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    function _decodeRLEImage(bytes memory image) public pure returns (DecodedImage memory) {
        uint8 paletteIndex = 0; // uint8(image[0]);
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

    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        returns (string memory svg)
    {
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190', '200', '210', '220', '230', 
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320' 
        ];
        string memory rects;

        _s = params.parts.length;

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

    function getGlassParts() internal pure returns(bytes[] memory) {
        bytes[] memory ssss = new bytes[](1);
        ssss[0] = bytes("0x000a1711071000030006000100060003000100020102000101010001000201020101000400020102000300020102000100010102000100020102000101010001000201020001010101020001000201020001010100010102010200010103000600010006001000");
        return ssss;
    }

    function getColors() internal {
        string[] memory colores;

        colores[0] = "";
        colores[1] = "000000";

        Palettes[0] = colores;
    }

    function getSVG() public returns(string memory str) {
        SVGParams memory params = SVGParams({
            parts: getGlassParts(),
            background: "e1d7d5"
        });

        colors.push("");
        colors.push("000000");
        Palettes[0] = colors;

        str = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#e1d7d5" />',
                _generateSVGRects(params, Palettes),
                '</svg>'
            )
        );
    }
}