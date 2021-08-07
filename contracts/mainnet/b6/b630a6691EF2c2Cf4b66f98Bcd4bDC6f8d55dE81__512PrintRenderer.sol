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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed, offsetBit etc...)
library Randomize {
    struct Random {
        uint256 seed;
        uint256 offsetBit;
    }

    /// @notice get an random number between (min and max) using seed and offseting bits
    ///         this function assumes that max is never bigger than 0xffffff (hex color with opacity included)
    /// @dev this function is simply used to get random number using a seed.
    ///      if does bitshifting operations to try to reuse the same seed as much as possible.
    ///      should be enough for anyth
    /// @param random the randomizer
    /// @param min the minimum
    /// @param max the maximum
    /// @return result the resulting pseudo random number
    function next(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        uint256 newSeed = random.seed;
        uint256 newOffset = random.offsetBit + 3;

        uint256 maxOffset = 4;
        uint256 mask = 0xf;
        if (max > 0xfffff) {
            mask = 0xffffff;
            maxOffset = 24;
        } else if (max > 0xffff) {
            mask = 0xfffff;
            maxOffset = 20;
        } else if (max > 0xfff) {
            mask = 0xffff;
            maxOffset = 16;
        } else if (max > 0xff) {
            mask = 0xfff;
            maxOffset = 12;
        } else if (max > 0xf) {
            mask = 0xff;
            maxOffset = 8;
        }

        // if offsetBit is too high to get the max number
        // just get new seed and restart offset to 0
        if (newOffset > (256 - maxOffset)) {
            newOffset = 0;
            newSeed = uint256(keccak256(abi.encode(newSeed)));
        }

        uint256 offseted = (newSeed >> newOffset);
        uint256 part = offseted & mask;
        result = min + (part % (max - min));

        random.seed = newSeed;
        random.offsetBit = newOffset;
    }

    function nextInt(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (int256 result) {
        result = int256(Randomize.next(random, min, max));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../../../Randomize.sol';

/// @title TheBoard
/// @author Simon Fremaux (@dievardump)
contract _512PrintRenderer {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    using Randomize for Randomize.Random;

    struct Configuration {
        int256 spacing;
        string background1;
        string background2;
        string stroke1;
        string stroke2;
        string background;
        string stroke;
        bool degen;
        bool animated;
        bool backgroundGradient;
        bool strokeGradient;
        bool rotated;
        bool rounded;
        bool missing;
        bytes left;
        bytes right;
    }

    constructor() {}

    function start(bytes32 seed)
        public
        pure
        returns (Randomize.Random memory, Configuration memory)
    {
        Randomize.Random memory random = Randomize.Random({
            seed: uint256(seed),
            offsetBit: 0
        });

        Configuration memory config = _getConfiguration(random);

        return (random, config);
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        bytes32 seed
    ) external pure returns (string memory) {
        (Randomize.Random memory random, Configuration memory config) = start(
            seed
        );

        string memory id = uint256(seed).toString();

        bytes memory svg = abi.encodePacked(
            'data:application/json;utf8,{"name":"',
            name,
            '","image":"data:image/svg+xml;utf8,',
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1200 1200' width='1200' height='1200'>"
            "<defs><clipPath id='print-clip-",
            id,
            "'><rect x='40' y='40' width='1120' height='1120' /></clipPath>"
        );

        svg = abi.encodePacked(
            svg,
            config.backgroundGradient
                ? string(_renderBackgroundGradient(id, config, random))
                : '',
            config.strokeGradient
                ? string(_renderStrokeGradient(id, config, random))
                : '',
            '</defs>',
            "<rect width='100%' height='100%' fill='",
            config.backgroundGradient
                ? string(abi.encodePacked('url(#print-background-', id, ')'))
                : config.background1,
            "'/><g x='40' y='40' stroke-linecap='round' stroke-width='",
            random.next(1, config.rounded ? 8 : 4).toString(),
            "' stroke='",
            config.strokeGradient
                ? string(abi.encodePacked('url(#print-stroke-', id, ')'))
                : config.stroke1,
            "' fill='",
            config.backgroundGradient
                ? string(abi.encodePacked('url(#print-background-', id, ')'))
                : config.background1,
            "' style='clip-path: url(#print-clip-",
            id,
            ")'>"
        );

        _fill(random, config);

        svg = abi.encodePacked(svg, config.left, config.right);

        svg = abi.encodePacked(
            svg,
            "</g><text text-anchor='end' x='1160' y='1180' fill='",
            config.strokeGradient
                ? string(abi.encodePacked('url(#print-stroke-', id, ')'))
                : config.stroke1,
            "'>#",
            tokenId.toString(),
            '</text></svg>"'
        );

        svg = abi.encodePacked(
            svg,
            ',"license":"Full ownership with unlimited commercial rights.","creator":"@dievardump"'
            ',"description":"Left or Right? Repeat. Add some fun.\\n\\n512Print Seedling is my take on the Solidity version of the renowned 10Print algorithm and the second of the [sol]Seedlings, an experiment of art and collectible NFTs 100% generated with Solidity.\\nby @dievardump\\n\\nLicense: Full ownership with unlimited commercial rights.\\n\\nMore info at https://solSeedlings.art"'
            ',"properties":{"Background":"',
            config.backgroundGradient ? 'Gradient' : 'Unicolor',
            '","Stroke":"',
            config.strokeGradient ? 'Gradient' : 'Unicolor',
            '"'
        );

        svg = abi.encodePacked(
            svg,
            config.degen ? ',"Particularity":"Degen"' : '',
            config.rotated ? ',"Angle":"45deg"' : '',
            config.rounded ? ',"Variante":"Rounded"' : '',
            config.animated ? ',"Rendering":"Animated"' : '',
            '}}'
        );

        return string(svg);
    }

    function _fill(Randomize.Random memory random, Configuration memory config)
        internal
        pure
    {
        if (config.rounded) {
            _renderRounded(random, config);
        } else {
            _renderClassic(random, config);
        }
    }

    function _renderClassic(
        Randomize.Random memory random,
        Configuration memory config
    ) internal pure {
        bytes memory result;
        int256 offset;
        int256 half = config.spacing / 2;
        for (int256 y; y < 1160; y += config.spacing) {
            for (int256 x; x < 1160; x += config.spacing) {
                if (config.missing && random.next(0, 100) < 15) continue;
                if (random.next(0, 2) == 0) {
                    if (!config.degen || random.next(0, 100) >= 10) {
                        result = _getLine(
                            x,
                            config.rotated ? y + half : y,
                            x + config.spacing,
                            config.rotated ? y + half : y + config.spacing,
                            0
                        );
                    } else {
                        offset = (random.nextInt(10, 20) * config.spacing) / 2;
                        result = _getLine(
                            x - offset,
                            config.rotated ? y + half : y - offset,
                            x + offset,
                            config.rotated ? y + half : y + offset,
                            random.next(10, 28)
                        );
                    }

                    config.left = abi.encodePacked(config.left, result);
                } else {
                    if (!config.degen || random.next(0, 100) >= 10) {
                        result = _getLine(
                            config.rotated ? x + half : x,
                            y + config.spacing,
                            config.rotated ? x + half : x + config.spacing,
                            y,
                            0
                        );
                    } else {
                        offset = (random.nextInt(10, 20) * config.spacing) / 2;
                        result = _getLine(
                            config.rotated ? x + half : x - offset,
                            y + offset,
                            config.rotated ? x + half : x + offset,
                            y - offset,
                            random.next(10, 28)
                        );
                    }

                    config.right = abi.encodePacked(config.right, result);
                }
            }
        }
    }

    function _renderRounded(
        Randomize.Random memory random,
        Configuration memory config
    ) internal pure {
        uint256 spacing = uint256(config.spacing);
        string memory half = (spacing / 2).toString();

        bytes memory element;

        // 50% change being round
        string memory strSpacing = spacing.toString();
        bytes memory roundedBase = _getRoundedBase(half, strSpacing);
        bytes memory cross = _getCross(half, strSpacing);
        bytes memory rotate = abi.encodePacked(
            ' rotate(90, ',
            half,
            ', ',
            half,
            ')'
        );

        int256 temp;
        bool doRotate;
        for (int256 y; y < 1160; y += config.spacing) {
            for (int256 x; x < 1160; x += config.spacing) {
                temp = random.nextInt(0, 100);
                if (temp < 50) {
                    element = roundedBase;
                } else {
                    element = cross;
                    if (temp > 83) {
                        element = abi.encodePacked(
                            element,
                            _getRoundedCircle(half, config.spacing / 4)
                        );
                    } else if (temp > 66) {
                        temp = config.animated
                            ? random.nextInt(20, 50)
                            : int256(0);
                        element = abi.encodePacked(
                            element,
                            _getSquare(
                                uint256(config.spacing / 4).toString(),
                                half,
                                uint256(temp)
                            )
                        );
                    }
                }

                doRotate = (random.next(0, 2) == 0);
                temp = random.nextInt(5, 10);
                config.left = abi.encodePacked(
                    config.left,
                    "<g transform='translate(",
                    uint256(x).toString(),
                    ',',
                    uint256(y).toString(),
                    ')',
                    doRotate ? rotate : bytes(''),
                    "' ",
                    config.degen
                        ? abi.encodePacked(
                            " stroke-width='",
                            uint256(temp).toString(),
                            "' "
                        )
                        : bytes(''),
                    '>',
                    element,
                    '</g>'
                );
            }
        }
    }

    function _getCross(string memory half, string memory spacing)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<line x1='",
            half,
            "' y1='0' x2='",
            half,
            "' y2='",
            spacing,
            "' />",
            "<line x1='0' y1='",
            half,
            "' x2='",
            spacing,
            "' y2='",
            half,
            "' />"
        );
    }

    function _getSquare(
        string memory position,
        string memory size,
        uint256 animation
    ) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            "<rect x='",
            position,
            "' y='",
            position,
            "' width='",
            size,
            "' height='",
            size,
            "' rx='6'>"
        );

        if (animation > 0) {
            svg = abi.encodePacked(
                svg,
                "<animateTransform attributeName='transform' attributeType='XML' type='rotate' dur='",
                animation.toString(),
                "s' from='0 ",
                size,
                ' ',
                size,
                "' to='360 ",
                size,
                ' ',
                size,
                "' repeatCount='indefinite' />"
            );
        }

        svg = abi.encodePacked(svg, '</rect>');
    }

    function _getRoundedCircle(string memory half, int256 size)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<circle cx='",
            half,
            "' cy='",
            half,
            "' r='",
            uint256(size).toString(),
            "' />"
        );
    }

    function _getRoundedBase(string memory half, string memory spacing)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<path d='M ",
            half,
            ' 0',
            'a ',
            half,
            ' ',
            half,
            ' 0 0 1 -',
            half,
            ' ',
            half,
            '',
            'm '
        );

        svg = abi.encodePacked(
            svg,
            spacing,
            ' 0',
            'a ',
            half,
            ' ',
            half,
            ' 0 0 0 -',
            half,
            ' ',
            half,
            "' fill='none'/>"
        );
    }

    function _getLine(
        int256 x0,
        int256 y0,
        int256 x1,
        int256 y1,
        uint256 strokeWidth
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<path fill='none' ",
                strokeWidth != 0
                    ? string(
                        abi.encodePacked(
                            "stroke-width='",
                            strokeWidth.toString(),
                            "'"
                        )
                    )
                    : '',
                " d='M",
                x0 < 0
                    ? string(abi.encodePacked('-', uint256(x0 * -1).toString()))
                    : uint256(x0).toString(),
                ',',
                y0 < 0
                    ? string(abi.encodePacked('-', uint256(y0 * -1).toString()))
                    : uint256(y0).toString(),
                'L',
                x1 < 0
                    ? string(abi.encodePacked('-', uint256(x1 * -1).toString()))
                    : uint256(x1).toString(),
                ',',
                y1 < 0
                    ? string(abi.encodePacked('-', uint256(y1 * -1).toString()))
                    : uint256(y1).toString(),
                "'/>"
            );
    }

    function _renderBackgroundGradient(
        string memory id,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure returns (bytes memory result) {
        uint256 animation = random.next(10000, 20000);
        result = abi.encodePacked(
            "<linearGradient id='print-background-",
            id,
            "' gradientTransform='rotate(",
            random.next(0, 360).toString(),
            ", 600, 600)' gradientUnits='userSpaceOnUse'><stop offset='0%' stop-color='",
            config.background1,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.background1,
                ';',
                config.background2,
                ';',
                config.background1,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(
            result,
            "</stop><stop offset='100%' stop-color='",
            config.background2,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.background2,
                ';',
                config.background1,
                ';',
                config.background2,
                "' repeatCount='indefinite' />"
            );
        }

        return abi.encodePacked(result, '</stop></linearGradient>');
    }

    function _renderStrokeGradient(
        string memory id,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure returns (bytes memory result) {
        uint256 animation = random.next(10000, 20000);
        result = abi.encodePacked(
            "<linearGradient id='print-stroke-",
            id,
            "' gradientTransform='rotate(",
            random.next(0, 360).toString(),
            ", 600, 600)' gradientUnits='userSpaceOnUse'><stop offset='0%' stop-color='",
            config.stroke1,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.stroke1,
                ';',
                config.stroke2,
                ';',
                config.stroke1,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(
            result,
            "</stop><stop offset='100%' stop-color='",
            config.stroke2,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.stroke2,
                ';',
                config.stroke1,
                ';',
                config.stroke2,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(result, '</stop></linearGradient>');
    }

    function _getConfiguration(Randomize.Random memory random)
        internal
        pure
        returns (Configuration memory config)
    {
        string[16] memory darker = [
            '#000000',
            '#1A1A2E',
            '#2C061F',
            '#352F44',
            '#1D2D50',
            '#2A363B',
            '#61105E',
            '#84142D',
            '#173F5F',
            '#29435C',
            '#A7226E',
            '#C70D3A',
            '#355C7D',
            '#20639B',
            '#6C5B7B',
            '#2D6E7E'
        ];

        string[20] memory lighter = [
            '#FFFFFF',
            '#E4FBFF',
            '#F7D9D9',
            '#B5EAEA',
            '#00FFF5',
            '#B6C9F0',
            '#FECEAB',
            '#FFF591',
            '#F8B195',
            '#F7DB4F',
            '#FF847C',
            '#3CAEA3',
            '#DA7F8F',
            '#F67280',
            '#2F9599',
            '#F26B38',
            '#C06C84',
            '#ED553B',
            '#E84A5F',
            '#EC2049'
        ];

        bool rounded = (random.next(0, 100) < 33);

        // if not rounded, 5% rotated
        bool rotated = !rounded && (random.next(0, 100) < 5);

        // if rotated; then degen, else 20%
        bool degen = (rotated || (random.next(0, 100) < 20));

        uint256 temp = random.next(0, 100);
        int256 spacing = random.nextInt(rounded ? 120 : 90, 160);
        if (spacing % 2 != 0) {
            spacing++;
        }

        config = Configuration({
            spacing: spacing,
            background1: '#000',
            background2: '#000',
            stroke1: '#fff',
            stroke2: '#fff',
            background: 'Black',
            stroke: 'White',
            degen: degen,
            animated: false,
            backgroundGradient: false,
            strokeGradient: false,
            rotated: rotated,
            missing: !rounded && (random.next(0, 100) < 5),
            left: '',
            right: '',
            rounded: rounded
        });

        if (temp >= 4 && temp < 8) {
            // black on white
            config.background1 = '#fff';
            config.background2 = '#fff';
            config.stroke1 = '#000';
            config.stroke2 = '#000';
            config.background = 'White';
            config.stroke = 'Black';
        } else if (temp < 26) {
            // black on lighter background
            config.background1 = config.background2 = lighter[
                random.next(0, lighter.length)
            ];
            config.stroke1 = '#000';
            config.stroke2 = '#000';

            config.background = 'Lighter';
            config.stroke = 'Black';
        } else if (temp < 44) {
            // white on darker background
            config.background1 = config.background2 = darker[
                random.next(0, darker.length)
            ];
            config.stroke1 = '#fff';
            config.stroke2 = '#fff';

            config.background = 'Darker';
            config.stroke = 'White';
        } else if (temp < 62) {
            // light gradient on black
            config.background1 = '#000';
            config.background2 = '#000';
            temp = random.next(0, lighter.length);
            config.stroke1 = lighter[temp];
            config.stroke2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];

            config.background = 'Black';
            config.stroke = 'Light gradient';
        } else if (temp < 80) {
            // dark gradient on white
            config.background1 = '#fff';
            config.background2 = '#fff';

            temp = random.next(0, darker.length);
            config.stroke1 = darker[temp];
            config.stroke2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            config.background = 'White';
            config.stroke = 'Darker gradient';
        } else if (temp < 90) {
            // dark gradient on light gradient
            temp = random.next(0, lighter.length);
            config.background1 = lighter[temp];
            config.background2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];
            temp = random.next(0, darker.length);
            config.stroke1 = darker[temp];
            config.stroke2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            config.background = 'Lighter gradient';
            config.stroke = 'Darker gradient';
        } else {
            // light gradient on dark gradient
            temp = random.next(0, darker.length);
            config.background1 = darker[temp];
            config.background2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            temp = random.next(0, lighter.length);
            config.stroke1 = lighter[temp];
            config.stroke2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];

            config.background = 'Darker gradient';
            config.stroke = 'Lighter gradient';
        }

        config.backgroundGradient =
            keccak256(abi.encodePacked((config.background1))) !=
            keccak256(abi.encodePacked((config.background2)));
        config.strokeGradient =
            keccak256(abi.encodePacked((config.stroke1))) !=
            keccak256(abi.encodePacked((config.stroke2)));

        // if rounded or gradient, it can be animated
        config.animated =
            (rounded || (config.backgroundGradient || config.strokeGradient)) &&
            (random.next(0, 100) < 10);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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