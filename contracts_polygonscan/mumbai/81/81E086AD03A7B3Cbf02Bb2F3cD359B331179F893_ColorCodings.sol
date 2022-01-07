// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

library ColorCodings {
    function renderInParts(string[][] memory hexes)
        external
        pure
        returns (string memory)
    {
        string memory fullPicture;

        for (uint256 row = 0; row < hexes.length; row += 1) {
            // Add by horizontal blocks (24 x 6)
            fullPicture = string(
                abi.encodePacked(
                    fullPicture,
                    _renderHorizontalBlock(hexes, row, row + 1)
                )
            );
        }

        return fullPicture;
    }

    function _renderHorizontalBlock(
        string[][] memory hexes,
        uint256 rowStart,
        uint256 rowEnd
    ) private pure returns (string memory) {
        string memory horizontalBlock;

        for (uint256 col = 0; col < hexes[0].length; col += 6) {
            // A horizontal block is collection of 6 x 6 squares
            horizontalBlock = string(
                abi.encodePacked(
                    horizontalBlock,
                    _renderSquare(hexes, rowStart, rowEnd, col, col + 6)
                )
            );
        }

        return horizontalBlock;
    }

    function _renderSquare(
        string[][] memory hexes,
        uint256 rowStart,
        uint256 rowEnd,
        uint256 colStart,
        uint256 colEnd
    ) private pure returns (string memory) {
        string[30] memory offsets = [
            "0",
            "10",
            "20",
            "30",
            "40",
            "50",
            "60",
            "70",
            "80",
            "90",
            "100",
            "110",
            "120",
            "130",
            "140",
            "150",
            "160",
            "170",
            "180",
            "190",
            "200",
            "210",
            "220",
            "230",
            "240",
            "250",
            "260",
            "270",
            "280",
            "290"
        ];
        string memory square;

        for (uint256 i = rowStart; i < rowEnd; i++) {
            // Square is composed of 6 x 1 rows
            string memory thinRow;
            for (uint256 j = colStart; j < colEnd; j++) {
                thinRow = string(
                    abi.encodePacked(
                        thinRow,
                        '<rect height="10" width="10" fill="#',
                        hexes[i][j],
                        '" x="',
                        offsets[j],
                        '" y="',
                        offsets[i],
                        '" />'
                    )
                );
            }
            square = string(abi.encodePacked(square, thinRow));
        }
        return square;
    }
}