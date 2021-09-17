// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract RenderBitmapSVG {
    // SPDX-License-Identifier: GPL-3.0

    // prettier-ignore
    // uint8[1024] data = [ 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 ];

    // struct SVGCursor {
    //     uint8 x;
    //     uint8 y;
    //     string color1;
    //     string color2;
    //     string color3;
    //     string color4;
    // }

    // string[16] colors = [
    //     "e4a672",
    //     "b86f50",
    //     "743f39",
    //     "3f2832",
    //     "9e2835",
    //     "e53b44",
    //     "fb922b",
    //     "ffe762",
    //     "63c64d",
    //     "327345",
    //     "193d3f",
    //     "4f6781",
    //     "afbfd2",
    //     "ffffff",
    //     "2ce8f4",
    //     "0484d1"
    // ];

    // function tokenSvgDataOf(uint256 tokenId)
    //     public
    //     view
    //     returns (string memory)
    // {
    //     string
    //         memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';

    //     string[32] memory lookup = [
    //         "0",
    //         "1",
    //         "2",
    //         "3",
    //         "4",
    //         "5",
    //         "6",
    //         "7",
    //         "8",
    //         "9",
    //         "10",
    //         "11",
    //         "12",
    //         "13",
    //         "14",
    //         "15",
    //         "16",
    //         "17",
    //         "18",
    //         "19",
    //         "20",
    //         "21",
    //         "22",
    //         "23",
    //         "24",
    //         "25",
    //         "26",
    //         "27",
    //         "28",
    //         "29",
    //         "30",
    //         "31"
    //     ];

    //     SVGCursor memory pos;

    //     string[8] memory p;

    //     for (uint256 i = 12; i < 268; i += 8) {
    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[0] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[1] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[2] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[3] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[4] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[5] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[6] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         pos.color1 = colors[data[i]];
    //         pos.color2 = colors[data[i + 1]];
    //         pos.color3 = colors[data[i + 2]];
    //         pos.color4 = colors[data[i + 3]];
    //         p[7] = pixel4(lookup, pos);
    //         pos.x += 4;

    //         svgString = string(
    //             abi.encodePacked(
    //                 svgString,
    //                 p[0],
    //                 p[1],
    //                 p[2],
    //                 p[3],
    //                 p[4],
    //                 p[5],
    //                 p[6],
    //                 p[7]
    //             )
    //         );

    //         if (pos.x >= 32) {
    //             pos.x = 0;
    //             pos.y += 1;
    //         }
    //     }

    //     svgString = string(abi.encodePacked(svgString, "</svg>"));
    //     return svgString;
    // }

    // function pixel4(string[32] memory lookup, SVGCursor memory pos)
    //     internal
    //     pure
    //     returns (string memory)
    // {
    //     return
    //         string(
    //             abi.encodePacked(
    //                 '<rect fill="',
    //                 pos.color1,
    //                 '" x="',
    //                 lookup[pos.x],
    //                 '" y="',
    //                 lookup[pos.y],
    //                 '" width="1.5" height="1.5" />',
    //                 '<rect fill="',
    //                 pos.color2,
    //                 '" x="',
    //                 lookup[pos.x + 1],
    //                 '" y="',
    //                 lookup[pos.y],
    //                 '" width="1.5" height="1.5" />',
    //                 string(
    //                     abi.encodePacked(
    //                         '<rect fill="',
    //                         pos.color3,
    //                         '" x="',
    //                         lookup[pos.x + 2],
    //                         '" y="',
    //                         lookup[pos.y],
    //                         '" width="1.5" height="1.5" />',
    //                         '<rect fill="',
    //                         pos.color4,
    //                         '" x="',
    //                         lookup[pos.x + 3],
    //                         '" y="',
    //                         lookup[pos.y],
    //                         '" width="1.5" height="1.5" />'
    //                     )
    //                 )
    //             )
    //         );
    // }

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint256 a) internal pure returns (string memory) {
        uint256 count = 0;
        uint256 b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    function byteToUint(bytes1 b) internal pure returns (uint256) {
        return uint256(uint8(b));
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect fill="',
                    pos.color1,
                    '" x="',
                    lookup[pos.x],
                    '" y="',
                    lookup[pos.y],
                    '" width="1.5" height="1.5" />',
                    '<rect fill="',
                    pos.color2,
                    '" x="',
                    lookup[pos.x + 1],
                    '" y="',
                    lookup[pos.y],
                    '" width="1.5" height="1.5" />',
                    string(
                        abi.encodePacked(
                            '<rect fill="',
                            pos.color3,
                            '" x="',
                            lookup[pos.x + 2],
                            '" y="',
                            lookup[pos.y],
                            '" width="1.5" height="1.5" />',
                            '<rect fill="',
                            pos.color4,
                            '" x="',
                            lookup[pos.x + 3],
                            '" y="',
                            lookup[pos.y],
                            '" width="1.5" height="1.5" />'
                        )
                    )
                )
            );
    }

    function tokenSvgDataOf(bytes memory data)
        public
        pure
        returns (string memory)
    {
        string
            memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';

        string[32] memory lookup = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31"
        ];

        SVGCursor memory pos;

        string[4] memory colors = [
            string(
                abi.encodePacked(
                    "#",
                    byteToHexString(data[0]),
                    byteToHexString(data[1]),
                    byteToHexString(data[2])
                )
            ),
            string(
                abi.encodePacked(
                    "#",
                    byteToHexString(data[3]),
                    byteToHexString(data[4]),
                    byteToHexString(data[5])
                )
            ),
            string(
                abi.encodePacked(
                    "#",
                    byteToHexString(data[6]),
                    byteToHexString(data[7]),
                    byteToHexString(data[8])
                )
            ),
            string(
                abi.encodePacked(
                    "#",
                    byteToHexString(data[9]),
                    byteToHexString(data[10]),
                    byteToHexString(data[11])
                )
            )
        ];

        string[8] memory p;

        for (uint256 i = 12; i < 268; i += 8) {
            for (uint8 j = 0; j < 8; j += 1) {
                pos.color1 = colors[colorIndex(data[i], 6, 7)];
                pos.color2 = colors[colorIndex(data[i], 4, 5)];
                pos.color3 = colors[colorIndex(data[i], 2, 3)];
                pos.color4 = colors[colorIndex(data[i], 0, 1)];
                p[j] = pixel4(lookup, pos);
                pos.x += 4;
            }
            // pos.color1 = colors[colorIndex(data[i], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i], 0, 1)];
            // p[0] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 1], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 1], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 1], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 1], 0, 1)];
            // p[1] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 2], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 2], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 2], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 2], 0, 1)];
            // p[2] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 3], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 3], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 3], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 3], 0, 1)];
            // p[3] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 4], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 4], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 4], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 4], 0, 1)];
            // p[4] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 5], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 5], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 5], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 5], 0, 1)];
            // p[5] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 6], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 6], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 6], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 6], 0, 1)];
            // p[6] = pixel4(lookup, pos);
            // pos.x += 4;

            // pos.color1 = colors[colorIndex(data[i + 7], 6, 7)];
            // pos.color2 = colors[colorIndex(data[i + 7], 4, 5)];
            // pos.color3 = colors[colorIndex(data[i + 7], 2, 3)];
            // pos.color4 = colors[colorIndex(data[i + 7], 0, 1)];
            // p[7] = pixel4(lookup, pos);
            // pos.x += 4;

            svgString = string(
                abi.encodePacked(
                    svgString,
                    p[0],
                    p[1],
                    p[2],
                    p[3],
                    p[4],
                    p[5],
                    p[6],
                    p[7]
                )
            );

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</svg>"));
        return svgString;
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return (uint8(aByte) >> index) & 1 == 1;
    }

    function colorIndex(
        bytes1 aByte,
        uint8 index1,
        uint8 index2
    ) internal pure returns (uint256) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}