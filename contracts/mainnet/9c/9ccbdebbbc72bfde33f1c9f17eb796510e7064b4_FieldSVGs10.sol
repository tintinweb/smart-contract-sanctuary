// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs10 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_178(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Papellony',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi178-a" viewBox="-8.33 -10 16.67 20"><path d="M-8.33 0c0-5.52 3.73-10 8.33-10S8.33-5.52 8.33 0C3.73 0 0 4.48 0 10 0 4.48-3.73 0-8.33 0z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi178-d" viewBox="-50 -10 100 20"><use height="20" overflow="visible" transform="translate(-41.667)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="translate(-25)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="translate(-8.333)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="translate(8.333)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="translate(25)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="translate(41.667)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/></symbol><symbol id="fi178-e" viewBox="-16.67 -10 33.33 20"><path d="M8.33 10C8.33 4.48 4.6 0 0 0h-16.67l8.33-10H8.33c4.6 0 8.33 4.48 8.33 10-4.59 0-8.33 4.48-8.33 10z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi178-b"/></defs><clipPath id="fi178-c"><use overflow="visible" xlink:href="#fi178-b"/></clipPath><g clip-path="url(#fi178-c)"><use height="20" overflow="visible" transform="matrix(1 0 0 -1 110 82)" width="100" x="-50" xlink:href="#fi178-d" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="100" x="-50" xlink:href="#fi178-d" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 110 122)" width="100" x="-50" xlink:href="#fi178-d" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 110 142)" width="100" x="-50" xlink:href="#fi178-d" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 110 162)" width="100" x="-50" xlink:href="#fi178-d" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 76.667 182)" width="33.33" x="-16.67" xlink:href="#fi178-e" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 101.667 182)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="matrix(1 0 0 -1 118.334 182)" width="16.67" x="-8.33" xlink:href="#fi178-a" y="-10"/><use height="20" overflow="visible" transform="rotate(180 71.66 91)" width="33.33" x="-16.67" xlink:href="#fi178-e" y="-10"/></g>'
                    )
                )
            );
    }

    function field_179(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Masoned',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M149.5 88H160v-3l-1 1h-22l-1-1V73l1-1h-4l1 1v12l-1 1h-21l-1-1V73l1-1h-4l1 1v12l-1 1H87l-1-1V73l1-1h-4l1 1v12l-1 1H61l-1-1v3h10.5l1 1v11l-1 1H60v17h10.5l1 1v11l-1 1H60v16c0 .335.018.666.025 1H70.5l1 1v11l-1 1H62c.223.766.463 1.524.722 2.275L63 163h20l1 1v11l-1 1H69.282c1.29 1.81 2.7 3.532 4.218 5.155V179l1-1h21l1 1v11l-1 1h-9.265a49.664 49.664 0 0 0 4.142 2H108l1 1v2.975c.137 0 .274 0 .411.01.2 0 .391.015.589.015.198 0 .392-.013.589-.015.137-.005.274-.008.411-.01V194l1-1h17.618a49.321 49.321 0 0 0 4.141-2H124.5l-1-1v-11l1-1h21l1 1v2.154a49.948 49.948 0 0 0 4.217-5.154H137l-1-1v-11l1-1h20l.276.276c.258-.751.499-1.51.722-2.276h-8.5l-1-1v-11l1-1h10.474c.007-.334.026-.665.026-1v-2l-1 1H137l-1-1v-11l1-1h22l1 1v-3h-10.5l-1-1v-11l1-1H160v-3l-1 1h-22l-1-1v-11l1-1h22l1 1v-3h-10.5l-1-1V89l1-1Zm-51 1 1-1h21l1 1v11l-1 1h-21l-1-1V89Zm-3 29 1 1v11l-1 1h-21l-1-1v-11l1-1h21Zm-9.5-3v-11l1-1h21l1 1v11l-1 1H87l-1-1Zm0 19 1-1h21l1 1v11l-1 1H87l-1-1v-11Zm12.5 15 1-1h21l1 1v11l-1 1h-21l-1-1v-11Zm13.5-3-1-1v-11l1-1h21l1 1v11l-1 1h-21Zm9.5-16-1 1h-21l-1-1v-11l1-1h21l1 1v11Zm-9.5-14-1-1v-11l1-1h21l1 1v11l-1 1h-21ZM73.5 89l1-1h21l1 1v11l-1 1h-21l-1-1V89ZM61 116l-1-1v-11l1-1h22l1 1v11l-1 1H61Zm0 30-1-1v-11l1-1h22l1 1v11l-1 1H61Zm13.5 15-1-1v-11l1-1h21l1 1v11l-1 1h-21ZM87 176l-1-1v-11l1-1h21l1 1v11l-1 1H87Zm34.5 14-1 1h-21l-1-1v-11l1-1h21l1 1v11Zm12.5-15-1 1h-21l-1-1v-11l1-1h21l1 1v11Zm11.5-27 1 1v11l-1 1h-21l-1-1v-11l1-1h21Zm0-30 1 1v11l-1 1h-21l-1-1v-11l1-1h21Zm1-18-1 1h-21l-1-1V89l1-1h21l1 1v11Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_180(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fretty I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi180-a" viewBox="-13.5 -16 27 32"><path d="M7.68 14.22-11.85-9.22l4.17-5L11.85 9.22zM12.5-10 4.82-.78l-4.17-5L8.33-15l5.17-1zm-25 0-1-6 5.17 1zM-.65 5.78-8.33 15l-5.17 1 1-6L-4.82.78zM13.5 16l-5.17-1 4.17-5z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi180-b" viewBox="-26 -16 52 32"><use height="32" overflow="visible" transform="translate(-12.5)" width="27" x="-13.5" xlink:href="#fi180-a" y="-16"/><use height="32" overflow="visible" transform="translate(12.5)" width="27" x="-13.5" xlink:href="#fi180-a" y="-16"/></symbol><symbol id="fi180-e" viewBox="-51 -16 102 32"><use height="32" overflow="visible" transform="translate(-25)" width="52" x="-26" xlink:href="#fi180-b" y="-16"/><use height="32" overflow="visible" transform="translate(25)" width="52" x="-26" xlink:href="#fi180-b" y="-16"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi180-c"/></defs><clipPath id="fi180-d"><use overflow="visible" xlink:href="#fi180-c"/></clipPath><g clip-path="url(#fi180-d)"><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110 87)" width="102" x="-51" xlink:href="#fi180-e" y="-16"/><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110 117)" width="102" x="-51" xlink:href="#fi180-e" y="-16"/><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110 147)" width="102" x="-51" xlink:href="#fi180-e" y="-16"/><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110 177)" width="102" x="-51" xlink:href="#fi180-e" y="-16"/><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110 207)" width="102" x="-51" xlink:href="#fi180-e" y="-16"/></g>'
                    )
                )
            );
    }

    function field_181(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fretty II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi181-a" viewBox="-13.21 -15.57 26.15 31.6"><path d="m12.5-1.56.44 2.6L2.6 13.44l-1.3-1.56zm-9.9 15zM-1.3-15l2.12-.57L11.2-3.12 9.9-1.56zM-9.9 1.56 1.3 15l-1.74 1.03L-11.2 3.12zm8.6-13.44L-12.5 1.56l-.71-2.27L-2.6-13.44z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi181-d" viewBox="-50.71 -15.57 101.15 31.6"><use height="31.6" overflow="visible" transform="translate(-37.5)" width="26.15" x="-13.21" xlink:href="#fi181-a" y="-15.57"/><use height="31.6" overflow="visible" transform="translate(-12.5)" width="26.15" x="-13.21" xlink:href="#fi181-a" y="-15.57"/><use height="31.6" overflow="visible" transform="translate(12.5)" width="26.15" x="-13.21" xlink:href="#fi181-a" y="-15.57"/><use height="31.6" overflow="visible" transform="translate(37.5)" width="26.15" x="-13.21" xlink:href="#fi181-a" y="-15.57"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi181-b"/></defs><clipPath id="fi181-c"><use overflow="visible" xlink:href="#fi181-b"/></clipPath><g clip-path="url(#fi181-c)"><use height="31.6" overflow="visible" transform="matrix(1 0 0 -1 110 87)" width="101.15" x="-50.71" xlink:href="#fi181-d" y="-15.57"/><use height="31.6" overflow="visible" transform="matrix(1 0 0 -1 110 117)" width="101.15" x="-50.71" xlink:href="#fi181-d" y="-15.57"/><use height="31.6" overflow="visible" transform="matrix(1 0 0 -1 110 147)" width="101.15" x="-50.71" xlink:href="#fi181-d" y="-15.57"/><use height="31.6" overflow="visible" transform="matrix(1 0 0 -1 110 177)" width="101.15" x="-50.71" xlink:href="#fi181-d" y="-15.57"/><use height="31.6" overflow="visible" transform="matrix(1 0 0 -1 110 207)" width="101.15" x="-50.71" xlink:href="#fi181-d" y="-15.57"/></g>'
                    )
                )
            );
    }

    function field_182(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Grillage',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M112.5 166.5v30.437c-.828.041-1.661.062-2.5.063-.839.001-1.672-.02-2.5-.063V166.5h5Zm0-60h-5v51h5v-51Zm-23 58h41v-5h-41v5Zm25-30H160v-5h-45.5v5Zm-9-5H60v5h45.5v-5Zm27 62.148a49.95 49.95 0 0 0 5-2.9V136.5h-5v55.148Zm5-64.148V72h-5v55.5h5Zm-7-28h-41v5h41v-5Zm-18-2V72h-5v25.5h5Zm27 7H160v-5h-20.5v5Zm-59 60v-5H61.575a49.638 49.638 0 0 0 1.58 5H80.5Zm0-60v-5H60v5h20.5Zm7-32.5h-5v55.5h5V72Zm52 92.5h17.344a49.325 49.325 0 0 0 1.58-5H139.5v5Zm-52 27.148V136.5h-5v52.253a49.703 49.703 0 0 0 5 2.895Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_183(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Vair',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M101.666 79.653 93.333 72h33.333l-8.333 7.653v14.694L110 102l-8.334-7.653V79.653Zm0 60v14.694L110 162l8.333-7.653v-14.694l8.333-7.653H93.333l8.333 7.653Zm50 34.982A49.813 49.813 0 0 0 157.707 162h-14.374l8.333 7.653v4.982Zm0-50.288L160 132v-30h-16.667l8.333 7.653v14.694Zm-83.333 50.287v-4.981L76.666 162H62.292a49.773 49.773 0 0 0 6.041 12.634ZM76.666 162 85 169.653v20.641a49.624 49.624 0 0 0 16.666 6v-26.641L110 162H76.666ZM85 79.653 93.333 72H60l8.333 7.653v14.694L76.666 102 85 94.347V79.653Zm33.333 30v14.694l8.333 7.653 8.334-7.653v-14.694l8.333-7.653H110l8.333 7.653ZM110 162l8.334 7.653V196.3a49.673 49.673 0 0 0 16.666-6v-20.647l8.333-7.653H110Zm41.667-82.347L160 72h-33.334L135 79.653v14.694l8.333 7.653 8.333-7.653.001-14.694Zm-16.666 60v14.694l8.332 7.653 8.333-7.653v-14.694L160 132h-33.334l8.335 7.653Zm-50 0L93.333 132H60l8.333 7.653v14.694L76.666 162 85 154.347l.001-14.694Zm16.666-30L110 102H60v30l8.333-7.653v-14.694L76.666 102 85 109.653v14.694L93.333 132l8.333-7.653.001-14.694Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_184(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Counter-Vair',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M128.75 169.5 135 162l6.251 7.5v15l.756.907a49.87 49.87 0 0 1-17.2 9.361L122.5 192l-3.477 4.172a49.572 49.572 0 0 1-18.045 0L97.5 192l-2.307 2.769a49.878 49.878 0 0 1-17.2-9.361l.756-.907v-15L85 162l6.251 7.5v15L97.5 192l6.25-7.5v-15L110 162l6.25 7.5v15l6.25 7.5 6.25-7.5v-15Zm25-45-6.25 7.5-6.249-7.5v-15L135 102l-6.249 7.5v15L122.5 132l-6.25-7.5v-15L110 102l-6.25 7.5v15L97.5 132l-6.249-7.5v-15L85 102l-6.25 7.5v15L72.5 132l-6.25-7.5v-15L60 102v45c-.002 4.374.57 8.73 1.7 12.955l4.547-5.456v-15L72.5 132l6.249 7.5v15L85 162l6.251-7.5v-15L97.5 132l6.25 7.5v15L110 162l6.25-7.5v-15l6.25-7.5 6.25 7.5v15L135 162l6.251-7.5v-15l6.25-7.5 6.249 7.5v15l4.546 5.456A50.024 50.024 0 0 0 160 147v-45l-6.25 7.5v15Zm0-30L160 102V72h-12.5l6.249 7.5.001 15Zm-25 0L135 102l6.251-7.5v-15L147.5 72h-25l6.25 7.5v15ZM60 102l6.25-7.5v-15L72.5 72H60v30Zm18.75-7.5L85 102l6.251-7.5v-15L97.5 72h-25l6.249 7.5.001 15Zm25 0L110 102l6.25-7.5v-15l6.25-7.5h-25l6.25 7.5v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_185(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Vair Ancient',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M157.707 162H62.292a49.754 49.754 0 0 1-1.6-6.75c10.527-.61 4.86-16.529 16.032-16.529 11.39 0 5.265 16.558 16.656 16.558 11.391 0 5.265-16.558 16.656-16.558 11.391 0 5.265 16.558 16.656 16.558 11.391 0 5.265-16.558 16.655-16.558 11.15 0 5.528 15.854 15.967 16.526a49.813 49.813 0 0 1-1.607 6.753Zm-14.363-53.279c-11.39 0-5.265 16.558-16.655 16.558s-5.266-16.558-16.656-16.558c-11.39 0-5.265 16.558-16.656 16.558-11.391 0-5.265-16.558-16.656-16.558-11.391 0-5.265 16.558-16.655 16.558V132H160v-6.721c-11.391 0-5.266-16.558-16.656-16.558Zm7.805 66.673c-1.21-3.54-2.85-6.673-7.805-6.673-11.39 0-5.265 16.558-16.655 16.558s-5.266-16.558-16.656-16.558c-11.39 0-5.265 16.558-16.656 16.558-11.391 0-5.265-16.558-16.656-16.558-4.984 0-6.614 3.17-7.825 6.736A49.993 49.993 0 0 0 110.039 197a49.992 49.992 0 0 0 41.11-21.606Zm-7.805-96.673c-11.39 0-5.265 16.558-16.655 16.558s-5.266-16.558-16.656-16.558c-11.39 0-5.265 16.558-16.656 16.558-11.391 0-5.265-16.558-16.656-16.558-11.391 0-5.265 16.558-16.655 16.558V102H160v-6.721c-11.391 0-5.266-16.558-16.656-16.558Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_186(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale and Per Chevron',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 102.021V197a50.014 50.014 0 0 1-48.3-37.047L109.983 102l.017.021ZM160 72h-50v30.021l48.284 57.921A49.833 49.833 0 0 0 160 147V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_187(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale and Per Fess Indented',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m97.5 162 12.5-60v95a50 50 0 0 1-50-50v-45l12.5 60L85 102l12.5 60ZM110 72v30l12.5 60 12.5-60 12.5 60 12.5-60V72h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_188(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess and Per Pale Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M115 177c0 7.181-10 7.82-10 15a7.68 7.68 0 0 0 2 4.9A49.997 49.997 0 0 1 60 147v-15h45c0 7.181 10 7.819 10 15s-10 7.819-10 15 10 7.821 10 15ZM105 72c0 7.18 10 7.819 10 15s-10 7.819-10 15 10 7.819 10 15-10 7.82-10 15h55V72h-55Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_189(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Saltire and Per Fess',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 72v60h-50l50-60ZM60 72v60h50L60 72Zm11.213 106.544a49.962 49.962 0 0 0 77.562-.013L110 132l-38.787 46.544Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_190(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale and Barry of Four',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 102h50v30H60v-30Zm50 0h50V72h-50v30Zm47.708 60A49.972 49.972 0 0 0 160 147v-15h-50v30h47.708Zm-48.63 34.977H110V162H62.292a50.016 50.016 0 0 0 46.786 34.977Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_191(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale and Barry of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72h50v15h-50V72Zm-50 30h50V87H60v15Zm0 30h50v-15H60v15Zm90 45a49.85 49.85 0 0 0 7.707-15H110v15h40Zm-90-30a49.97 49.97 0 0 0 2.292 15H110v-15H60Zm100-30v-15h-50v15h50Zm0 30v-15h-50v15h50Zm-50 50v-20H70a49.916 49.916 0 0 0 40 20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_192(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess and Paly of Five',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M135 72h25v60h-25V72Zm-25 125a49.747 49.747 0 0 0 25-6.706V132h-25v65Zm-50-50a49.97 49.97 0 0 0 25 43.294V132H60v15Zm25-75v60h25V72H85Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_193(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess and Two Pallets',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M100 72v60H80V72h20Zm0 124a50.207 50.207 0 0 0 10 1 50.2 50.2 0 0 0 10-1v-64h-20v64Zm40-9a49.923 49.923 0 0 0 20-40v-15h-20v55Zm-80-40a49.924 49.924 0 0 0 20 40v-55H60v15Zm60-75v60h20V72h-20Z" fill="#',
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