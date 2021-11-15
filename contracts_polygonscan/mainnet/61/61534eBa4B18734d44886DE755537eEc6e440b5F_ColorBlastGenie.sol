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

contract ColorBlastGenie {
    bool public set = false;

    constructor() {
        set = true;
    }

    function doesnothing() public {
        set = set;
    }

    function generateSVG(
        uint256 color1,
        uint256 color2,
        uint256 color3,
        uint256 color4,
        uint256 color5,
        uint256 color6,
        uint256 color7,
        uint256 color8,
        uint256 color9
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style> .c{stroke-width:7px} .r1{animation:rotation2 7s infinite linear; } .r2{animation:rotation 8s infinite linear; } .d{stroke:#aaa;',
                    "stroke-width:9px} .g1{fill:url(#g1)} .g2{fill:url(#g2)} .t{font-family:monospace;font-weight:700;font-size:15px;transform:translate(-9%,1%)} @keyframes rotation{ from{transform:rotateY(0)} to{transform:rotateY(359deg)}} @keyframes",
                    ' rotation2{from{transform:rotateX(0)} to{transform:rotateX(359deg)}} </style> <linearGradient id="g1" x1="-100%" x2="200%" y1="0" y2="0"><stop offset="0" stop-color="#fff"></stop><stop offset="0.3" stop-color="#fff"><animate attributeName="offset"',
                    ' dur="4s" repeatCount="indefinite" values="-.15;0.7"> </animate></stop><stop offset="0.4" stop-color="#222"><animate attributeName="offset" dur="4s" repeatCount="indefinite" values="0.1;0.9" linear="true"> </animate></stop><stop offset=".5" stop-color="#fff"><animate attribute',
                    'name="offset" dur="4s" repeatCount="indefinite" values="0.25;1.1"> </animate></stop></linearGradient><linearGradient id="g2" x1="-100%" x2="200%" y1="0" y2="0" gradienttransform="rotate(-90)"><stop offset="0" stop-color="#fff"></stop><stop offset="0.03" stop-color="#',
                    'fff"><animate attributeName="offset" dur="3.5s" repeatCount="indefinite" values="-1;0.4"> </animate></stop><stop offset="0.4" stop-color="#000"> <animate attributeName="offset" dur="3.5s" repeatCount="indefinite" values="-0.35;0.6" linear="true"> </animate></stop><stop offset=".5"',
                    ' stop-color="#fff"><animate attributeName="offset" dur="3.5s" repeatCount="indefinite" values="0;0.75"> </animate></stop></linearGradient><rect height="100%" width="100%" /> ',
                    getAllPogs(
                        color1,
                        color2,
                        color3,
                        color4,
                        color5,
                        color6,
                        color7,
                        color8,
                        color9
                    ),
                    "</svg>"
                )
            );
    }

    function generatePog(
        uint256 color,
        string memory x,
        string memory y,
        bool _isOne
    ) internal pure returns (string memory) {
        // string memory hexColor = getColorHexCode(color);
        bytes memory chunkA = abi.encodePacked(
            '<ellipse class="r',
            (_isOne ? "1" : "2"),
            ' d" cx="',
            x,
            '%" cy="',
            y,
            '%" rx="12%" transform-origin="',
            x,
            "% ",
            y,
            '%" /> <ellipse class="r',
            (_isOne ? "1" : "2"),
            ' c" cx="',
            x,
            '%" cy="',
            y,
            '%" rx="12%" transform-origin="',
            x,
            "% ",
            y
        );

        bytes memory chunkB = abi.encodePacked(
            '%" stroke="',
            getColorHexCode(color),
            '" /> <text class="g',
            (!_isOne ? "1" : "2"),
            ' t" transform-origin="',
            y,
            "% ",
            x,
            '%" x="',
            x,
            '%" y="',
            y,
            '%">',
            getColorHexCode(color),
            " </text> "
        );

        return string(abi.encodePacked(chunkA, chunkB));
    }

    function getAllPogs(
        uint256 color1,
        uint256 color2,
        uint256 color3,
        uint256 color4,
        uint256 color5,
        uint256 color6,
        uint256 color7,
        uint256 color8,
        uint256 color9
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    generatePog(color1, "18", "20", true),
                    generatePog(color2, "49", "20", false),
                    generatePog(color3, "80", "20", true),
                    generatePog(color4, "18", "50", false),
                    generatePog(color5, "49", "50", true),
                    generatePog(color6, "80", "50", false),
                    generatePog(color7, "18", "80", true),
                    generatePog(color8, "49", "80", false),
                    generatePog(color9, "80", "80", true)
                )
            );
    }

    function getColorComponentRed(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16((value >> 8) & 0xf);
    }

    function getColorComponentGreen(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16((value >> 4) & 0xf);
    }

    function getColorComponentBlue(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16(value & 0xf);
    }

    function getColorHexCode(uint256 value)
        internal
        pure
        returns (string memory)
    {
        bytes16 _HEX_SYMBOLS = "0123456789abcdef";
        uint16 red = getColorComponentRed(value);
        uint16 green = getColorComponentGreen(value);
        uint16 blue = getColorComponentBlue(value);

        bytes memory buffer = new bytes(7);

        buffer[0] = "#";
        buffer[1] = _HEX_SYMBOLS[red];
        buffer[2] = _HEX_SYMBOLS[red];
        buffer[3] = _HEX_SYMBOLS[green];
        buffer[4] = _HEX_SYMBOLS[green];
        buffer[5] = _HEX_SYMBOLS[blue];
        buffer[6] = _HEX_SYMBOLS[blue];

        return string(buffer);
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

