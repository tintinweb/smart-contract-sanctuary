// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract RenderBitmapSVG {
    struct SVGCursor {
        uint256 x;
        uint256 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    function _assembleRow(SVGCursor memory pos)
        private
        pure
        returns (string memory)
    {
        string[32] memory LOOKUP = [
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
        return
            string(
                abi.encodePacked(
                    '<rect width="1" height="1" x="',
                    LOOKUP[pos.x],
                    '" y="',
                    LOOKUP[pos.y],
                    '"  style="fill:#',
                    pos.color1,
                    '" />',
                    '<rect width="1" height="1" x="',
                    LOOKUP[pos.x],
                    '" y="',
                    LOOKUP[pos.y],
                    '"  style="fill:#',
                    pos.color2,
                    '" />',
                    string(
                        abi.encodePacked(
                            '<rect width="1" height="1" x="',
                            LOOKUP[pos.x],
                            '" y="',
                            LOOKUP[pos.y],
                            '"  style="fill:#',
                            pos.color3,
                            '" />',
                            '<rect width="1" height="1" x="',
                            LOOKUP[pos.x],
                            '" y="',
                            LOOKUP[pos.y],
                            '"  style="fill:#',
                            pos.color4,
                            '" />'
                        )
                    )
                )
            );
    }

    // supports 256 colors using 8 bits as the index
    function render16(uint8[1024] calldata data, string[16] calldata palette)
        public
        pure
        returns (string memory)
    {
        string
            memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32" >';
        SVGCursor memory pos;
        string[8] memory p;
        for (uint256 y = 0; y < 32; y += 1) {
            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[0] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[1] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[2] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[3] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[4] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[5] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[6] = _assembleRow(pos);
            pos.y = y + 4;

            pos.color1 = palette[data[pos.y]];
            pos.color2 = palette[data[pos.y + 1]];
            pos.color3 = palette[data[pos.y + 2]];
            pos.color4 = palette[data[pos.y + 3]];
            p[7] = _assembleRow(pos);
            pos.y = y + 4;

            string(
                abi.encodePacked(
                    output,
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

            pos.y = 0;
            pos.x += 1;
        }
        output = string(abi.encodePacked(output, "</svg>"));
        return output;
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