// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFraming.sol";

contract FramesV2 is IFraming {
    using Strings for uint256;

    function _colorScheme(uint256 frameId)
        internal
        pure
        returns (
            string memory,
            uint256,
            string[] memory
        )
    {
        if (frameId == 1) {
            string[] memory stopColors = new string[](5);
            stopColors[0] = "B5DBF1";
            stopColors[1] = "84B5EE";
            stopColors[2] = "7B8FDD";
            stopColors[3] = "C98FC6";
            stopColors[4] = "D0A5D4";
            return ("Supercool Meta", 1, stopColors);
        } else if (frameId == 2) {
            string[] memory stopColors = new string[](3);
            stopColors[0] = "E3CE0D";
            stopColors[1] = "CB1C1C";
            stopColors[2] = "A11AD1";
            return ("Fahrenheit 451", 1, stopColors);
        } else if (frameId == 3) {
            string[] memory stopColors = new string[](3);
            stopColors[0] = "1630B7";
            stopColors[1] = "1B7EB6";
            stopColors[2] = "0AD5DC";
            return ("Cool Blue", 1, stopColors);
        } else if (frameId == 4) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "B82525";
            return ("Chili Red", 0, stopColors);
        } else if (frameId == 5) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "DF5908";
            return ("Tiger Orange", 0, stopColors);
        } else if (frameId == 6) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "CEB11F";
            return ("Cyber Yellow", 0, stopColors);
        } else if (frameId == 7) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "64A343";
            return ("Olive green", 0, stopColors);
        } else if (frameId == 8) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "37AE87";
            return ("Jungle green", 0, stopColors);
        } else if (frameId == 9) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "1499B0";
            return ("Aqua Blue", 0, stopColors);
        } else if (frameId == 10) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "176CD1";
            return ("Ocean Blue", 0, stopColors);
        } else if (frameId == 11) {
            string[] memory stopColors = new string[](4);
            stopColors[0] = "FFFFFF";
            stopColors[1] = "000000";
            stopColors[2] = "EEEEEE";
            stopColors[3] = "EEEEEE";
            return ("Shades of Gray", 1, stopColors);
        } else if (frameId == 12) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "8F1DC6";
            return ("Grape Purple", 0, stopColors);
        } else if (frameId == 13) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "B33BAD";
            return ("Violet", 0, stopColors);
        } else if (frameId == 14) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "CE2F64";
            return ("Ruby Pink", 0, stopColors);
        } else if (frameId == 15) {
            string[] memory stopColors = new string[](1);
            stopColors[0] = "727272";
            return ("Smoke Gray", 0, stopColors);
        } else if (frameId == 16) {
            string[] memory stopColors = new string[](6);
            stopColors[0] = "000000";
            stopColors[1] = "FFFFFF";
            stopColors[2] = "EEEEEE";
            stopColors[3] = "FFFFFF";
            stopColors[4] = "000000";
            stopColors[5] = "000000";
            return ("Black & White", 1, stopColors);
        } else if (frameId == 17) {
            string[] memory stopColors = new string[](4);
            stopColors[0] = "A117B3";
            stopColors[1] = "A117B3";
            stopColors[2] = "1560B4";
            stopColors[3] = "1E0221";
            return ("Wonderland Purple", 2, stopColors);
        } else if (frameId == 18) {
            string[] memory stopColors = new string[](4);
            stopColors[0] = "000000";
            stopColors[1] = "000000";
            stopColors[2] = "B41515";
            stopColors[3] = "1735B3";
            return ("Inferno", 2, stopColors);
        } else if (frameId == 19) {
            string[] memory stopColors = new string[](5);
            stopColors[0] = "1B4A0B";
            stopColors[1] = "4BCA32";
            stopColors[2] = "3C9135";
            stopColors[3] = "018F26";
            stopColors[4] = "15CA7D";
            return ("Forest Green", 1, stopColors);
        } else if (frameId == 20) {
            string[] memory stopColors = new string[](3);
            stopColors[0] = "D4158F";
            stopColors[1] = "8636B0";
            stopColors[2] = "251AA2";
            return ("Star Pink", 1, stopColors);
        } else if (frameId == 21) {
            string[] memory stopColors = new string[](6);
            stopColors[0] = "753AC5";
            stopColors[1] = "1C0CB5";
            stopColors[2] = "0BB411";
            stopColors[3] = "D3E10C";
            stopColors[4] = "EB8B0A";
            stopColors[5] = "D61F1F";
            return ("Rainbow", 1, stopColors);
        } else if (frameId == 22) {
            string[] memory stopColors = new string[](3);
            stopColors[0] = "CCDBE3";
            stopColors[1] = "627DEE";
            stopColors[2] = "EEEEEE";
            return ("Sky Blue", 1, stopColors);
        }
    }

    function _randomWeightedFrameId(
        uint256 tokenId,
        uint16[22] memory cumulativeSumWeights
    ) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId))) % 404; // modulus sumOfWeights
        for (uint256 i = 0; i < cumulativeSumWeights.length; i++) {
            if (rand < cumulativeSumWeights[i]) {
                return i + 1; // frameId 1-indexed
            }
        }
    }

    function _frameIdByRules(
        uint256 tokenId,
        uint16[22] memory cumulativeSumWeights
    ) internal pure returns (uint256) {
        if (tokenId <= 69) {
            return 2;
        } else if (tokenId <= 200) {
            return 3;
        } else if (tokenId <= 419) {
            return 20;
        } else if (tokenId == 420) {
            return 21;
        } else {
            return _randomWeightedFrameId(tokenId, cumulativeSumWeights);
        }
    }

    function genFrame(uint256 tokenId)
        external
        pure
        returns (string memory, string memory)
    {
        uint256 offset;
        string memory stops;
        string memory frame;

        uint16[22] memory cumulativeSumWeights = [
            // cumSumWeight, weight, frameId
            120, // 120, 1
            121, // 1, 2
            123, // 2, 3
            137, // 14, 4
            151, // 14, 5
            165, // 14, 6
            179, // 14, 7
            193, // 14, 8
            207, // 14, 9
            221, // 14, 10
            251, // 30, 11
            265, // 14, 12
            279, // 14, 13
            293, // 14, 14
            307, // 14, 15
            337, // 30, 16
            367, // 30, 17
            397, // 30, 18
            399, // 2, 19
            401, // 2, 20
            402, // 1, 21
            404 // 2, 22
        ];

        (
            string memory frameName,
            uint256 gradient,
            string[] memory stopColors
        ) = _colorScheme(_frameIdByRules(tokenId, cumulativeSumWeights));

        uint256 numColors = stopColors.length;
        if (numColors > 1) {
            for (uint256 i = 0; i < numColors; i++) {
                offset = (100 * i) / (numColors - 1);
                stops = string(
                    abi.encodePacked(
                        stops,
                        "<stop offset='",
                        offset.toString(),
                        "%' stop-color='#",
                        stopColors[i],
                        "'/>"
                    )
                );
            }
        }

        if (gradient == 0) {
            frame = string(
                abi.encodePacked(
                    "<rect height='320' width='260' style='fill:#000; stroke-width:20; stroke:#",
                    stopColors[0],
                    "'/>"
                )
            );
        } else if (gradient == 1) {
            frame = string(
                abi.encodePacked(
                    "<defs><linearGradient id='linear' gradientUnits='userSpaceOnUse' gradientTransform='rotate(12)' x1='100%' y1='0%' x2='0%' y2='100%'>",
                    stops,
                    '</linearGradient></defs>',
                    "<rect height='320' width='260' style='fill:#000; stroke-width:20; stroke:url(#linear)'/>"
                )
            );
        } else if (gradient == 2) {
            frame = string(
                abi.encodePacked(
                    "<defs><radialGradient id='radial' gradientUnits='userSpaceOnUse' r='100%'>",
                    stops,
                    '</radialGradient></defs>',
                    "<rect height='320' width='260' style='fill:#000; stroke-width:20; stroke:url(#radial)'/>"
                )
            );
        }
        return (frameName, frame);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

interface IFraming {
    function genFrame(uint256 tokenId)
        external
        pure
        returns (string memory, string memory); // (frameName, frame)
}