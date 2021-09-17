// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract RenderBitmapSVG {
    // SPDX-License-Identifier: GPL-3.0

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

    function tokenSvgDataOf(bytes memory data, string[16] memory palette)
        public
        pure
        returns (string memory)
    {
        string
            memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';

        // prettier-ignore
        string[32] memory lookup=["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"];

        SVGCursor memory pos;

        string[8] memory p;

        for (uint256 i = 12; i < 524; i += 16) {
            for (uint8 j = 0; j < 8; j += 1) {
                pos.color1 = palette[colorIndex(data[i + j], 0xF0, 4)];
                pos.color2 = palette[colorIndex(data[i + j], 0x0F, 0)];
                pos.color3 = palette[colorIndex(data[i + 1 + j], 0xF0, 4)];
                pos.color4 = palette[colorIndex(data[i + 1 + j], 0x0F, 0)];
                p[j] = pixel4(lookup, pos);
                pos.x += 4;
            }

            // prettier-ignore
            svgString = string( abi.encodePacked(
                    svgString,
                    p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]
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
        uint8 mask,
        uint8 shift
    ) internal pure returns (uint256) {
        return uint256((uint8(aByte) & mask) >> shift);
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