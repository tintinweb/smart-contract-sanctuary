// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs8 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_151(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lozengy II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi151-a" viewBox="-8.33 -10 16.67 20"><path d="M0 10-8.33-.01l.01.01L0-10 8.33 0z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi151-b" viewBox="-16.67 -10 33.33 20"><use height="20" overflow="visible" transform="translate(-8.333)" width="16.67" x="-8.33" xlink:href="#fi151-a" y="-10"/><use height="20" overflow="visible" transform="translate(8.333)" width="16.67" x="-8.33" xlink:href="#fi151-a" y="-10"/></symbol><symbol id="fi151-c" viewBox="-50 -10 100 20"><use height="20" overflow="visible" transform="translate(-33.333)" width="33.33" x="-16.67" xlink:href="#fi151-b" y="-10"/><use height="20" overflow="visible" width="33.33" x="-16.67" xlink:href="#fi151-b" y="-10"/><use height="20" overflow="visible" transform="translate(33.333)" width="33.33" x="-16.67" xlink:href="#fi151-b" y="-10"/></symbol><symbol id="fi151-f" viewBox="-50 -40 100 80"><use height="20" overflow="visible" transform="translate(0 30)" width="100" x="-50" xlink:href="#fi151-c" y="-10"/><use height="20" overflow="visible" transform="translate(0 10)" width="100" x="-50" xlink:href="#fi151-c" y="-10"/><use height="20" overflow="visible" transform="translate(0 -10)" width="100" x="-50" xlink:href="#fi151-c" y="-10"/><use height="20" overflow="visible" transform="translate(0 -30)" width="100" x="-50" xlink:href="#fi151-c" y="-10"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72h100v75c0 27.61-22.38 50-49.99 50H110c-27.61 0-50-22.39-50-50V72z" id="fi151-d"/></defs><clipPath id="fi151-e"><use overflow="visible" xlink:href="#fi151-d"/></clipPath><g clip-path="url(#fi151-e)"><use height="80" overflow="visible" transform="matrix(1 0 0 -1 110.002 102)" width="100" x="-50" xlink:href="#fi151-f" y="-40"/><use height="80" overflow="visible" transform="matrix(1 0 0 -1 110.002 182)" width="100" x="-50" xlink:href="#fi151-f" y="-40"/></g>'
                    )
                )
            );
    }

    function field_152(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lozengy Wide',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 139.5 85 147l-25-7.5 25-7.5 25 7.5ZM85 147l-24.459 7.338c.016.112.029.226.046.338L85 162l25-7.5-25-7.5Zm0-45-25 7.5 25 7.5 25-7.5-25-7.5Zm0 15-25 7.5 25 7.5 25-7.5-25-7.5Zm-12.022 63.607c4 4.401 8.752 8.055 14.032 10.793l22.99-6.9-25-7.5-12.022 3.607ZM132.99 191.4a50.175 50.175 0 0 0 14.032-10.79L135 177l-25 7.5 22.99 6.9ZM85 72l-25 7.5L85 87l25-7.5L85 72Zm0 15-25 7.5 25 7.5 25-7.5L85 87Zm50 30 25-7.5-25-7.5-25 7.5 25 7.5Zm0 15 25-7.5-25-7.5-25 7.5 25 7.5Zm0-30 25-7.5-25-7.5-25 7.5 25 7.5Zm-25-22.5 25 7.5 25-7.5-25-7.5-25 7.5Zm25 82.5 24.413-7.324c.017-.112.03-.226.046-.338L135 147l-25 7.5 25 7.5Zm0 15 18.633-5.59a50.348 50.348 0 0 0 1.7-3.311L135 162l-25 7.5 25 7.5Zm-50-15-20.331 6.1a48.775 48.775 0 0 0 1.7 3.311L85 177l25-7.5-25-7.5Zm50-15 25-7.5-25-7.5-25 7.5 25 7.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_153(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lozengy Barry',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi153-a" viewBox="-8.33 -5 16.67 10"><path d="M-8.33 5 0-5 8.33 5H-8.33z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi153-b" viewBox="-16.67 -5 33.33 10"><use height="10" overflow="visible" transform="translate(-8.333)" width="16.67" x="-8.33" xlink:href="#fi153-a" y="-5"/><use height="10" overflow="visible" transform="translate(8.333)" width="16.67" x="-8.33" xlink:href="#fi153-a" y="-5"/></symbol><symbol id="fi153-c" viewBox="-66.67 -5 133.33 10"><use height="10" overflow="visible" transform="translate(-50)" width="33.33" x="-16.67" xlink:href="#fi153-b" y="-5"/><use height="10" overflow="visible" transform="translate(-16.667)" width="33.33" x="-16.67" xlink:href="#fi153-b" y="-5"/><use height="10" overflow="visible" transform="translate(16.667)" width="33.33" x="-16.67" xlink:href="#fi153-b" y="-5"/><use height="10" overflow="visible" transform="translate(50)" width="33.33" x="-16.67" xlink:href="#fi153-b" y="-5"/></symbol><symbol id="fi153-f" viewBox="-70.83 -30 141.67 60"><use height="10" overflow="visible" transform="translate(4.167 25)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/><use height="10" overflow="visible" transform="translate(-4.167 15)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/><use height="10" overflow="visible" transform="translate(4.167 5)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/><use height="10" overflow="visible" transform="translate(-4.167 -5)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/><use height="10" overflow="visible" transform="translate(4.167 -15)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/><use height="10" overflow="visible" transform="translate(-4.167 -25)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi153-d"/></defs><clipPath id="fi153-e"><use overflow="visible" xlink:href="#fi153-d"/></clipPath><g clip-path="url(#fi153-e)"><use height="60" overflow="visible" transform="matrix(1 0 0 -1 122.5 102)" width="141.67" x="-70.83" xlink:href="#fi153-f" y="-30"/><use height="60" overflow="visible" transform="matrix(1 0 0 -1 122.5 162)" width="141.67" x="-70.83" xlink:href="#fi153-f" y="-30"/></g><g clip-path="url(#fi153-e)"><use height="10" overflow="visible" transform="matrix(1 0 0 -1 126.667 197)" width="133.33" x="-66.67" xlink:href="#fi153-c" y="-5"/></g>'
                    )
                )
            );
    }

    function field_154(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fusilly I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M61.521 159.263A50.024 50.024 0 0 0 79.613 186.7l13.72-24.7-16.666-30-15.146 27.263ZM126.667 162l16.666-30 15.146 27.263a50.02 50.02 0 0 1-18.092 27.437l-13.72-24.7Zm16.666-30-16.666-30 16.666-30L160 102l-16.667 30ZM110 132l16.667 30L110 192l-16.667-30L110 132Zm0 0-16.667-30L110 72l16.667 30L110 132Zm-33.333 0L60 102l16.667-30 16.666 30-16.666 30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_155(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fusilly II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M72.5 72 60 92l12.5 20L85 92 72.5 72Zm50 40L110 92l12.5-20L135 92l-12.5 20Zm-25 0L85 92l12.5-20L110 92l-12.5 20ZM60 132l12.5-20L85 132l-12.5 20L60 132Zm62.5 20 12.5 20-12.5 20-12.5-20 12.5-20Zm12.5-20 12.5-20 12.5 20-12.5 20-12.5-20Zm-37.5 20L85 132l12.5-20 12.5 20-12.5 20Zm0 0 12.5 20-12.5 20L85 172l12.5-20Zm-25 0L85 172l-7.9 12.635A50.094 50.094 0 0 1 63.748 166l8.752-14Zm50 0L110 132l12.5-20 12.5 20-12.5 20Zm12.5 20 12.5-20 8.752 14a50.105 50.105 0 0 1-13.352 18.635L135 172Zm12.5-60L135 92l12.5-20L160 92l-12.5 20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_156(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fusilly III',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m100 152-10.01 20L80 152.04v-.08L89.99 132 100 152ZM60 72v.04L69.99 92 80 72H60Zm49.99 60L120 112l-10.01-20-9.99 19.96v.08l9.99 19.96Zm-20 0L100 112 89.99 92 80 111.96v.08L89.99 132Zm-29.776 19.533c.036.392.076.783.12 1.173L69.99 172 80 152l-10.01-20-9.776 19.533ZM129.99 132 140 112l-10.01-20-9.99 19.96v.08l9.99 19.96ZM100 151.96v.08l9.99 19.96L120 152l-10.01-20-9.99 19.96ZM149.99 92 160 72h-20v.04L149.99 92ZM140 112.04l9.99 19.96L160 112l-10.01-20-9.99 19.96v.08ZM129.99 92 140 72h-20v.04L129.99 92ZM120 192l-10.01-20-9.99 19.96v.04l-10.01-20-8.161 16.307a50.001 50.001 0 0 0 56.328.011L129.99 172 120 191.96v.04Zm20-39.96 9.99 19.96 9.683-19.347c.041-.361.077-.723.11-1.086L149.99 132 140 151.96v.08Zm-20-.08v.08l9.99 19.96L140 152l-10.01-20-9.99 19.96ZM109.99 92 120 72h-20v.04L109.99 92Zm-20 0L100 72H80v.04L89.99 92ZM80 112 69.99 92 60 111.96v.08L69.99 132 80 112Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_157(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pily I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m160 72-16.667 102.335L126.667 72 110 192 93.333 72 76.666 174.335 60 72h100Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_158(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pily II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m120 72-10 125-10-125h20Zm-40 0 10 120 10-120H80Zm-20 0 10 104.314L80 72H60Zm60 0 10 120 10-120h-20Zm20 0 10 104.314L160 72h-20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_159(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Orly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 151.5a14.995 14.995 0 0 0 13.858-9.26A14.995 14.995 0 0 0 125 136.5V114H95v22.5a15.001 15.001 0 0 0 15 15ZM100 120h20v15a10.001 10.001 0 0 1-20 0v-15ZM65 78v67.5a45 45 0 1 0 90 0V78H65Zm85 66a39.996 39.996 0 0 1-11.716 28.284 39.996 39.996 0 0 1-56.568 0A39.998 39.998 0 0 1 70 144V84h80v60Zm-40 20.5c6.63 0 12.989-2.634 17.678-7.322A25.004 25.004 0 0 0 135 139.5V102H85v37.5a25.003 25.003 0 0 0 25 25ZM90 108h40v30a20 20 0 0 1-40 0v-30Zm20 69.5a35 35 0 0 0 35-35V90H75v52.5a35 35 0 0 0 35 35ZM80 96h60v45a30 30 0 0 1-60 0V96Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_160(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Roundel',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 162c16.569 0 30-13.431 30-30 0-16.569-13.431-30-30-30-16.569 0-30 13.431-30 30 0 16.569 13.431 30 30 30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_161(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Annulet',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M140 132a29.995 29.995 0 0 1-18.519 27.716 30.002 30.002 0 0 1-28.148-52.66 29.997 29.997 0 0 1 44.383 13.464A29.987 29.987 0 0 1 140 132Zm-5 0a24.998 24.998 0 0 0-29.877-24.52 25.004 25.004 0 0 0-19.643 19.643A25 25 0 0 0 110 157a25.028 25.028 0 0 0 25-25Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_162(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Billet',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M93.333 92h33.333v80H93.333V92Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_163(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Triangle',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 95.062 15.995 27.703 15.994 27.704H78.011l15.994-27.704L110 95.062Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_164(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Inescutcheon',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 172a25.026 25.026 0 0 1-25-25V97h50v50a25.024 25.024 0 0 1-7.331 17.669A25.024 25.024 0 0 1 110 172Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_165(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lozenge',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M109.998 196.999h-.056.056Zm24.997-64.995-24.993 29.99-24.997-29.99-.002-.003L110 102.006l24.997 29.995-.002.003Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_166(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Mascle',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 96-30 35.953L110 168l30-36.047L110 96Zm-16.983 35.961L110 111.608l16.983 20.353L110 152.367l-16.983-20.406Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_167(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Mullet',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m117.2 135.4 33.9-3.4-33.9-3.4 19.1-28.2-22.9 22.6-3.4-41.8-3.4 41.8-22.9-22.6 19.1 28.2-33.9 3.4 33.9 3.4-19.1 28.2 22.9-22.6 3.4 41.8 3.4-41.8 22.9 22.6-19.1-28.2Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_168(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quatrefoil',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M117.9 97.2c3.9 2.4 6 5.3 6 9.6 0 5.2-2.2 7.4-5.8 11.3-1.6 1.8-.5 3.7.8 5 1.3 1.3 3.2 2.3 5 .8 4-3.5 6.1-5.8 11.3-5.8 4.2 0 7.2 2.1 9.6 6 1.5 2.5 3.3 6.1 7.4 7.9-4.1 1.8-5.9 5.3-7.4 7.9-2.4 3.9-5.3 6-9.6 6-5.2 0-7.4-2.2-11.3-5.8-1.8-1.6-3.7-.5-5 .8-1.3 1.3-2.3 3.2-.8 5 3.5 4 5.8 6.1 5.8 11.3 0 4.2-2.1 7.2-6 9.6-2.5 1.5-6.1 3.3-7.9 7.4-1.8-4.1-5.3-5.9-7.9-7.4-3.9-2.4-6-5.3-6-9.6 0-5.2 2.2-7.4 5.8-11.3 1.6-1.8.5-3.7-.8-5-1.3-1.3-3.2-2.3-5-.8-4 3.5-6.1 5.8-11.3 5.8-4.2 0-7.2-2.1-9.6-6-1.5-2.5-3.3-6.1-7.4-7.9 4.1-1.8 5.9-5.3 7.4-7.9 2.4-3.9 5.3-6 9.6-6 5.2 0 7.4 2.2 11.3 5.8 1.8 1.6 3.7.5 5-.8 1.3-1.3 2.3-3.2.8-5-3.5-4-5.8-6.1-5.8-11.3 0-4.2 2.1-7.2 6-9.6 2.5-1.5 6.1-3.3 7.9-7.4 1.8 4.2 5.3 5.9 7.9 7.4Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_169(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quasar',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 132c-27.608-.01-49.986-26.868-49.986-60 0 33.138-22.386 60-50 60 27.614 0 50 26.863 50 60 0-33.132 22.378-59.99 49.986-60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_170(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Roundels',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M85 117c8.284 0 15-6.716 15-15 0-8.284-6.716-15-15-15-8.284 0-15 6.716-15 15 0 8.284 6.716 15 15 15ZM135 117c8.284 0 15-6.716 15-15 0-8.284-6.716-15-15-15-8.284 0-15 6.716-15 15 0 8.284 6.716 15 15 15ZM110 177c8.284 0 15-6.716 15-15 0-8.284-6.716-15-15-15-8.284 0-15 6.716-15 15 0 8.284 6.716 15 15 15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}