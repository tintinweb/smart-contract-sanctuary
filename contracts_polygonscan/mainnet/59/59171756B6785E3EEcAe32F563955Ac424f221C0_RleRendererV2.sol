// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "./IRenderer.sol";

contract RleRendererV2 is IRenderer {
    function render(bytes memory encodedData)
        external
        pure
        returns (string memory)
    {
        string memory fullPicture;
        string[] memory colors;
        uint16[] memory counts;
        (colors, counts) = abi.decode(encodedData, (string[], uint16[]));

        require(
            colors.length == counts.length,
            "colors and counts lengths must be equal"
        );
        string[720] memory decodedImage;
        decodedImage = _decodeImage(colors, counts);

        fullPicture = _renderImage(decodedImage);

        // Now simply iterate and return whatever
        return fullPicture;
    }

    function _renderImage(string[720] memory decodedImage)
        private
        pure
        returns(string memory)
    {
        string memory fullPicture;
        uint16 offset = 0;
        for (uint16 i = 0; i < decodedImage.length; i += 120) {

            string memory partialPicture;
            for (uint16 j = 0; j < 120; j += 20) {

                string memory smallPicture;
                for (uint16 k = 0; k < 20; k += 5) {
                    smallPicture = string(
                        abi.encodePacked(
                            smallPicture,
                            _fillColor(decodedImage[offset], offset),
                            _fillColor(decodedImage[offset + 1], offset + 1),
                            _fillColor(decodedImage[offset + 2], offset + 2),
                            _fillColor(decodedImage[offset + 3], offset + 3),
                            _fillColor(decodedImage[offset + 4], offset + 4)
                        )
                    );
                    offset += 5;
                }
                partialPicture = string(
                    abi.encodePacked(
                        partialPicture,
                        smallPicture
                    )
                );
            }
            fullPicture = string(
                abi.encodePacked(
                    fullPicture,
                    partialPicture
                )
            );
        }
        return fullPicture;
    }

    function _decodeImage(string[] memory colors, uint16[] memory counts)
        private
        pure
        returns (string[720] memory)
    {
        string[720] memory arr;
        uint16 index = 0;
        for (uint16 i = 0; i < counts.length; i++) {
            for (uint16 j = 0; j < counts[i]; j++) {
                arr[index++] = colors[i];
            }
        }
        return arr;
    }

    function _fillColor(string memory colorCode, uint16 offset)
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