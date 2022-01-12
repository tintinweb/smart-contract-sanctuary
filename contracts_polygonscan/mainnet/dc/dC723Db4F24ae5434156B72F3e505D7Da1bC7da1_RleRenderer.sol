// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "./IRenderer.sol";

contract RleRenderer is IRenderer {
    function render(bytes memory encodedData)
        external
        pure
        returns (string memory)
    {
        string memory fullPicture;
        string[] memory colors;
        uint256[] memory counts;
        (colors, counts) = abi.decode(encodedData, (string[], uint256[]));

        require(
            colors.length == counts.length,
            "colors and counts lengths must be equal"
        );

        uint256 chunkSize = 6;
        uint256 offset = 0;
        for (
            uint256 subSection = 0;
            subSection < colors.length / chunkSize;
            subSection++
        ) {
            string memory smallerPicture;
            for (uint256 chunk = 0; chunk < chunkSize; chunk++) {
                uint256 currentIndex = subSection * chunkSize + chunk;
                smallerPicture = string(
                    abi.encodePacked(
                        smallerPicture,
                        _renderPartialBlock(
                            colors[currentIndex],
                            counts[currentIndex],
                            offset
                        )
                    )
                );
                offset += counts[currentIndex];
            }
            fullPicture = string(abi.encodePacked(fullPicture, smallerPicture));
        }

        for (
            uint256 remainder = 0;
            remainder < colors.length % chunkSize;
            remainder++
        ) {
            uint256 currentIndex = (colors.length / chunkSize) *
                chunkSize +
                remainder;
            fullPicture = string(
                abi.encodePacked(
                    fullPicture,
                    _renderPartialBlock(
                        colors[currentIndex],
                        counts[currentIndex],
                        offset
                    )
                )
            );
            offset += counts[currentIndex];
        }

        return fullPicture;
    }

    function _renderPartialBlock(
        string memory colorCode,
        uint256 colorFrequency,
        uint256 offset
    ) private pure returns (string memory) {
        string memory partialBlock;

        uint256 currentOffset = offset;
        uint256 chunkSize = 6;
        for (
            uint256 subSection = 0;
            subSection < colorFrequency / chunkSize;
            subSection++
        ) {
            string memory smallBlock;
            for (uint256 chunk = 0; chunk < chunkSize; chunk++) {
                smallBlock = string(
                    abi.encodePacked(
                        smallBlock,
                        _fillColor(colorCode, currentOffset)
                    )
                );
                currentOffset++;
            }
            partialBlock = string(abi.encodePacked(partialBlock, smallBlock));
        }

        for (
            uint256 remainder = 0;
            remainder < colorFrequency % chunkSize;
            remainder++
        ) {
            partialBlock = string(
                abi.encodePacked(
                    partialBlock,
                    _fillColor(colorCode, currentOffset)
                )
            );
            currentOffset++;
        }

        return partialBlock;
    }

    function _fillColor(string memory colorCode, uint256 offset)
        private
        pure
        returns (string memory)
    {
        string[30] memory gridOffsets = [
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

        return
            string(
                abi.encodePacked(
                    '<rect height="10" width="10" fill="#',
                    colorCode,
                    '" x="',
                    gridOffsets[offset % 24],
                    '" y="',
                    gridOffsets[offset / 24],
                    '"/>'
                )
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

interface IRenderer {
    function render(bytes memory encodedData)
        external
        pure
        returns (string memory);
}