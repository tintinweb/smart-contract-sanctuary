pragma solidity ^0.8.7;

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

contract GameGenie {
    uint256 public none;

    constructor() {
        none = 1;
    }

    function generateData(
        string[5] memory _colors1,
        string[5] memory _colors2,
        string[5] memory _colors3,
        string[5] memory _colors4,
        string[5] memory _colors5,
        uint256 _palBal,
        string[5] memory _x,
        string[5] memory _y,
        string[5] memory _d
    ) external pure returns (string memory) {
        string[2] memory chunk;
        chunk[0] = string(
            abi.encodePacked(
                getImage1(
                    _colors1,
                    _colors2,
                    _colors3,
                    _colors4,
                    _colors5,
                    _palBal
                )
            )
        );

        chunk[1] = string(
            abi.encodePacked(getImage2(_x, _y, _d), getImage3(_x, _y, _d))
        );

        string memory _image = string(abi.encodePacked(chunk[0], chunk[1]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "game #',
                        '", "description": "game is an experiment in NFT composibility and on-chain image generation. Reserved',
                        ' for early adopters, the collection is limited to 250 editions", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_image)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getImage1(
        string[5] memory _colors1,
        string[5] memory _colors2,
        string[5] memory _colors3,
        string[5] memory _colors4,
        string[5] memory _colors5,
        uint256 _palBal
    ) internal pure returns (string memory) {
        string[3] memory chunk;

        chunk[0] = string(
            abi.encodePacked(
                '<svg version="1.2" baseProfile="tiny-ps" xmlns="http://www.w3.org/2000/svg" viewBox="-1080 -1080 ',
                '2160 2160" width="1080" height="1080"> <title>game</title> <defs> ',
                getBorder(_colors1, 1, _palBal),
                getBorder(
                    ((_palBal > 1) ? (_colors2) : (_colors1)),
                    2,
                    _palBal
                ),
                getBorder(_colors1, 3, _palBal),
                getBorder(
                    ((_palBal > 1) ? (_colors2) : (_colors1)),
                    4,
                    _palBal
                ),
                getBorder(_colors1, 5, _palBal),
                " </defs> <style> .a{stroke-width:8;}.shp0{fill:",
                ((_palBal <= 5) ? _colors4[4] : "#fff"),
                ";stroke:",
                ((_palBal < 5) ? "url(#grd1)" : "#000"),
                ";stroke-width:12}.shp1{fill:",
                (
                    (_palBal >= 3)
                        ? ((_palBal < 5) ? "url(#grd1)" : _colors3[1])
                        : "transparent"
                )
            )
        );

        chunk[1] = string(
            abi.encodePacked(
                ";stroke:",
                ((_palBal < 5) ? "url(#grd3)" : "#000"),
                ";}.shp2{fill:",
                (
                    (_palBal >= 3)
                        ? ((_palBal < 5) ? "url(#grd3)" : _colors1[3])
                        : "transparent"
                ),
                ";stroke:",
                ((_palBal < 5) ? "url(#grd2)" : "#000"),
                ";}.shp3{fill:",
                (
                    (_palBal >= 3)
                        ? ((_palBal < 5) ? "url(#grd2)" : _colors5[2])
                        : "transparent"
                ),
                ";stroke:"
            )
        );

        chunk[2] = string(
            abi.encodePacked(
                ((_palBal < 5) ? "url(#grd4)" : "#000"),
                ";}.shp4{fill:",
                (
                    (_palBal >= 3)
                        ? ((_palBal < 5) ? "url(#grd4)" : _colors4[4])
                        : "transparent"
                ),
                ";stroke:",
                ((_palBal < 5) ? "url(#grd4)" : "#000"),
                ";}.shp5{fill:",
                (
                    (_palBal >= 3)
                        ? ((_palBal < 5) ? "url(#grd1)" : _colors2[0])
                        : "transparent"
                ),
                ";stroke:",
                ((_palBal < 5) ? "url(#grd5)" : "#000"),
                ';}</style> <rect class="shp0" width="2160px" height="2160px" x="-1080" y="-1080" />'
            )
        );

        return string(abi.encodePacked(chunk[0], chunk[1], chunk[2]));
    }

    function getImage2(
        string[5] memory _x,
        string[5] memory _y,
        string[5] memory _d
    ) internal pure returns (string memory) {
        bytes memory chunkA = abi.encodePacked(
            '<ellipse class="a shp5" cx="',
            _x[4],
            '" cy="',
            _y[4],
            '" rx="',
            _d[4],
            '"> <animate id="a5" attributeName="rx" from="0" to="',
            _d[4],
            '" dur="7s" /> <animate id="a5" attributeName="cy" from="-800" to="',
            _y[4],
            '" dur="7s" /> <animate id="a5" attributeName="cx" from="-800" to="',
            _x[4],
            '" dur="7s" /> </ellipse>',
            ' <rect x="',
            _x[0],
            '" y="',
            _y[0],
            '" width="480" height="280" class="a shp1" transform="rotate(',
            _d[0],
            ",",
            _x[0],
            ",",
            _y[0],
            ')"> <animate id="a1" attributeName="x" values="-980;',
            _x[0],
            '" dur="3s" repeatCount="1" />',
            '<animate attributeName="width" from="0" to="480" dur="3s" /> </rect> <rect x="'
        );

        return
            string(
                abi.encodePacked(
                    chunkA,
                    _x[1],
                    '" y="',
                    _y[1],
                    '" width="260" height="180" class="a shp2" transform="rotate(',
                    _d[1],
                    ",",
                    _x[1],
                    ",",
                    _y[1],
                    ')"> <animate attributeName="x" from="-980" to="',
                    _x[1],
                    '" dur="4s" /> <animate attributeName="width" from="0" to="260" dur="4s" /> </rect> <rect x="',
                    _x[2],
                    '" y="',
                    _y[2],
                    '" width="520" height="95" class="a shp3" transform="rotate('
                )
            );
    }

    function getImage3(
        string[5] memory _x,
        string[5] memory _y,
        string[5] memory _d
    ) internal pure returns (string memory) {
        bytes memory chunkA = abi.encodePacked(
            _d[2],
            ",",
            _x[2],
            ",",
            _y[2],
            ')"> <animate attributeName="x" from="-980" to="',
            _x[2],
            '" dur="5s" /> <animate attributeName="width" from="0" to="260" dur="5s" /> </rect> <rect x="',
            _x[3],
            '" y="',
            _y[3],
            '" width="700"',
            ' height="490" class="a shp4" transform="rotate(',
            _d[3],
            ",",
            _x[3],
            ",",
            _y[3],
            ')"> <animate attributeName="x" from="-980" to="',
            _x[3],
            '" dur="5s" /> <animate attributeName="width" from="0" to="700" dur="5s" /> </rect> </svg>'
        );

        return string(chunkA);
    }

    function getBorder(
        string[5] memory _colors,
        uint256 _index,
        uint256 _palBal
    ) internal pure returns (string memory) {
        uint256 _index2;

        if (_palBal < 1) {
            _colors = ["#fff", "#fff", "#fff", "#fff", "#fff"];
        } else if (_palBal < 2) {
            // set solid colors
            _index2 = _index - 1;
        } else if (_palBal < 5) {
            (_index < 5) ? (_index2 = _index) : (_index2 = 0);
        }

        return
            string(
                abi.encodePacked(
                    '<linearGradient id="grd',
                    toString(_index),
                    '" > <stop offset="0" stop-color="',
                    _colors[_index - 1],
                    '"/> <stop offset="1" stop-color="',
                    _colors[_index2],
                    '"/> </linearGradient>'
                )
            );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // From loot (for adventurers)
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
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}