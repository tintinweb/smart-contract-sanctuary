// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";

library Colors {
    using Strings for uint256;

    struct HSL {
        uint256 hue;
        uint256 saturation;
        uint256 lightness;
    }

    struct Color {
        string start;
        string end;
    }

    struct MainframeColors {
        Color light;
        Color medium;
        Color dark;
        Color bg;
    }

    function generateHSLColor(
        string memory seed,
        uint256 hMin,
        uint256 hMax,
        uint256 sMin,
        uint256 sMax,
        uint256 lMin,
        uint256 lMax
    ) public pure returns (HSL memory) {
        return
            HSL(
                generatePseudoRandomValue(
                    string(abi.encodePacked("H", seed)),
                    hMin,
                    hMax
                ),
                generatePseudoRandomValue(
                    string(abi.encodePacked("S", seed)),
                    sMin,
                    sMax
                ),
                generatePseudoRandomValue(
                    string(abi.encodePacked("L", seed)),
                    lMin,
                    lMax
                )
            );
    }

    function toHSLString(HSL memory hsl) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    hsl.hue.toString(),
                    ",",
                    hsl.saturation.toString(),
                    "%,",
                    hsl.lightness.toString(),
                    "%)"
                )
            );
    }

    function generatePseudoRandomValue(
        string memory seed,
        uint256 from,
        uint256 to
    ) public pure returns (uint256) {
        if (to <= from) return from;
        return
            (uint256(keccak256(abi.encodePacked(seed))) % (to - from)) + from;
    }

    function generateComputerColors(string memory seed)
        public
        pure
        returns (MainframeColors memory)
    {
        HSL memory lightStart = generateHSLColor(
            string(abi.encodePacked(seed, "LIGHT_START")),
            0,
            359,
            50,
            70,
            55,
            75
        );
        HSL memory lightEnd = generateHSLColor(
            string(abi.encodePacked(seed, "LIGHT_END")),
            lightStart.hue + 359 - generatePseudoRandomValue(seed, 5, 60),
            lightStart.hue + 359 + generatePseudoRandomValue(seed, 5, 60),
            70,
            85,
            25,
            45
        );
        HSL memory mediumStart = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            lightStart.hue,
            lightStart.hue,
            lightStart.saturation,
            lightStart.saturation,
            35,
            50
        );
        HSL memory mediumEnd = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            lightEnd.hue,
            lightEnd.hue,
            lightEnd.saturation,
            lightEnd.saturation,
            35,
            10
        );

        HSL memory darkStart = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            0,
            359,
            40,
            70,
            13,
            16
        );
        HSL memory darkEnd = generateHSLColor(
            string(abi.encodePacked(seed, "DARKEST_END")),
            darkStart.hue + 359 - generatePseudoRandomValue(seed, 5, 60),
            darkStart.hue + 359 + generatePseudoRandomValue(seed, 5, 60),
            darkStart.saturation,
            darkStart.saturation,
            3,
            13
        );

        HSL memory BGStart = generateHSLColor(
            string(abi.encodePacked(seed, "BG_START")),
            0,
            359,
            55,
            100,
            45,
            65
        );
        HSL memory BGEnd = generateHSLColor(
            string(abi.encodePacked(seed, "BG_END")),
            0,
            359,
            BGStart.saturation,
            BGStart.saturation,
            BGStart.lightness,
            BGStart.lightness
        );

        return
            MainframeColors(
                Color(toHSLString(lightStart), toHSLString(lightEnd)),
                Color(toHSLString(mediumStart), toHSLString(mediumEnd)),
                Color(toHSLString(darkStart), toHSLString(darkEnd)),
                Color(toHSLString(BGStart), toHSLString(BGEnd))
            );
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