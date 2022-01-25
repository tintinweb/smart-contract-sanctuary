// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs11 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_194(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross and Saltire I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 140.5h-31.2l25.209 30.249a50.203 50.203 0 0 1-11.545 14.263L118.5 156.257V197h-17v-40.745l-23.964 28.756a50.186 50.186 0 0 1-11.545-14.263L91.2 140.5H60v-17h31.2L60 86.06V72h11.714l29.786 35.742V72h17v35.74L148.284 72H160v14.06l-31.2 37.44H160v17Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_195(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Grid',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi195-a"><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="none"/></clipPath><symbol id="fi195-c" viewBox="0 0 11.5 13"><path d="M10.5,0H1L0,1V12l1,1h9.5l1-1V1Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi195-e" viewBox="0 0 10.5 13"><path d="M10.5,12V1l-1-1H1L0,1V12l1,1H9.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi195-b" viewBox="0 0 100 13"><use height="13" width="11.5" xlink:href="#fi195-c"/><use height="13" transform="translate(88.5)" width="11.5" xlink:href="#fi195-c"/><use height="13" transform="translate(13.5)" width="10.5" xlink:href="#fi195-e"/><use height="13" transform="translate(26)" width="10.5" xlink:href="#fi195-e"/><use height="13" transform="translate(38.5)" width="10.5" xlink:href="#fi195-e"/><use height="13" transform="translate(51)" width="10.5" xlink:href="#fi195-e"/><use height="13" transform="translate(63.5)" width="10.5" xlink:href="#fi195-e"/><use height="13" transform="translate(76)" width="10.5" xlink:href="#fi195-e"/></symbol></defs><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi195-a)"><path d="M70.5,72,59,71l1,14,1,1h9.5l1-1V73ZM161,71l-11.5,1-1,1V85l1,1H159l1-1ZM84,85V73l-1-1H74.5l-1,1V85l1,1H83Zm12.5,0V73l-1-1H87l-1,1V85l1,1h8.5ZM109,85V73l-1-1H99.5l-1,1V85l1,1H108Zm12.5,0V73l-1-1H112l-1,1V85l1,1h8.5ZM134,85V73l-1-1h-8.5l-1,1V85l1,1H133Zm12.5,0V73l-1-1H137l-1,1V85l1,1h8.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="13" transform="translate(60 88)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 103)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 118)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 133)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 148)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 163)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 178)" width="100" xlink:href="#fi195-b"/><use height="13" transform="translate(60 193)" width="100" xlink:href="#fi195-b"/></g>'
                    )
                )
            );
    }

    function field_196(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Supergrid I',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi196-a" viewBox="-0.5 -70 1 140"><path d="M0 70V-70" fill="none" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi196-e" viewBox="-19.3 -70 38.5 140"><use height="140" overflow="visible" transform="translate(18.75)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="translate(12.5)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="translate(6.25)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="translate(-6.25)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="translate(-12.5)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="translate(-18.75)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/></symbol><symbol id="fi196-f" viewBox="-70 -26.8 140 53.5"><use height="140" overflow="visible" transform="rotate(90 -13.13 13.13)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -9.38 9.38)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -5.63 5.63)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -1.88 1.88)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 1.88 -1.88)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 5.63 -5.63)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 9.38 -9.38)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 13.13 -13.13)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/></symbol><symbol id="fi196-d" viewBox="-88.9 -54.1 177.9 108.2"><use height="140" overflow="visible" transform="rotate(-39.8 21.87 -60.43)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 18.75 -51.8)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 15.62 -43.16)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 12.5 -34.53)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 9.37 -25.9)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 6.25 -17.27)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 3.12 -8.63)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 0 0)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -3.12 8.63)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -6.25 17.27)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -9.37 25.9)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -12.5 34.53)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -15.62 43.16)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -18.75 51.8)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -21.87 60.43)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M110 190.8c-24.1 0-43.8-19.6-43.8-43.8V79.5h87.5V147c.1 24.1-19.6 43.8-43.7 43.8z" id="fi196-b"/></defs><clipPath id="fi196-c"><use overflow="visible" xlink:href="#fi196-b"/></clipPath><g clip-path="url(#fi196-c)"><use height="108.2" overflow="visible" transform="matrix(1 0 0 -1 65.2 133.28)" width="177.9" x="-88.9" xlink:href="#fi196-d" y="-54.1"/><use height="108.2" overflow="visible" transform="matrix(1 0 0 -1 152.7 140.78)" width="177.9" x="-88.9" xlink:href="#fi196-d" y="-54.1"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 110 132)" width="1" x="-.5" xlink:href="#fi196-a" y="-70"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 85 132)" width="38.5" x="-19.3" xlink:href="#fi196-e" y="-70"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 135 132)" width="38.5" x="-19.3" xlink:href="#fi196-e" y="-70"/><use height="53.5" overflow="visible" transform="matrix(1 0 0 -1 110 105.77)" width="140" x="-70" xlink:href="#fi196-f" y="-26.8"/><use height="53.5" overflow="visible" transform="matrix(1 0 0 -1 110 165.77)" width="140" x="-70" xlink:href="#fi196-f" y="-26.8"/></g><path d="M110 190.8c-24.1 0-43.8-19.6-43.8-43.8V79.5h87.5V147c.1 24.1-19.6 43.8-43.7 43.8z" fill="none" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_197(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Supergrid II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi197-a" viewBox="-0.2 -70 0.5 140"><path d="M0 70V-70" fill="none" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke-width=".5"/></symbol><symbol id="fi197-e" viewBox="-19 -70 38 140"><use height="140" overflow="visible" transform="translate(18.75)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="translate(12.5)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="translate(6.25)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="translate(-6.25)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="translate(-12.5)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="translate(-18.75)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/></symbol><symbol id="fi197-f" viewBox="-70 -26.5 140 53"><use height="140" overflow="visible" transform="rotate(90 -13.13 13.13)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -9.38 9.38)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -5.63 5.63)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 -1.88 1.88)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 1.88 -1.88)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 5.63 -5.63)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 9.38 -9.38)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(90 13.13 -13.13)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/></symbol><symbol id="fi197-d" viewBox="-88.7 -53.9 177.5 107.9"><use height="140" overflow="visible" transform="rotate(-39.8 21.87 -60.43)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 18.75 -51.8)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 15.62 -43.16)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 12.5 -34.53)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 9.37 -25.9)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 6.25 -17.27)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 3.12 -8.63)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 0 0)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -3.12 8.63)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -6.25 17.27)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -9.37 25.9)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -12.5 34.53)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -15.62 43.16)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -18.75 51.8)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="rotate(-39.8 -21.87 60.43)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M110 190.8c-24.1 0-43.8-19.6-43.8-43.8V79.5h87.5V147c.1 24.1-19.6 43.8-43.7 43.8z" id="fi197-b"/></defs><clipPath id="fi197-c"><use overflow="visible" xlink:href="#fi197-b"/></clipPath><g clip-path="url(#fi197-c)"><use height="107.9" overflow="visible" transform="matrix(1 0 0 -1 65.2 133.28)" width="177.5" x="-88.7" xlink:href="#fi197-d" y="-53.9"/><use height="107.9" overflow="visible" transform="matrix(1 0 0 -1 152.7 140.78)" width="177.5" x="-88.7" xlink:href="#fi197-d" y="-53.9"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 110 132)" width=".5" x="-.2" xlink:href="#fi197-a" y="-70"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 85 132)" width="38" x="-19" xlink:href="#fi197-e" y="-70"/><use height="140" overflow="visible" transform="matrix(1 0 0 -1 135 132)" width="38" x="-19" xlink:href="#fi197-e" y="-70"/><use height="53" overflow="visible" transform="matrix(1 0 0 -1 110 105.77)" width="140" x="-70" xlink:href="#fi197-f" y="-26.5"/><use height="53" overflow="visible" transform="matrix(1 0 0 -1 110 165.77)" width="140" x="-70" xlink:href="#fi197-f" y="-26.5"/></g><path d="M110 190.8c-24.1 0-43.8-19.6-43.8-43.8V79.5h87.5V147c.1 24.1-19.6 43.8-43.7 43.8z" fill="none" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke-width="2"/>'
                    )
                )
            );
    }

    function field_198(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Microdot',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi198-a" viewBox="-1 -4 2 8"><circle cy="3" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="1"/><circle cy="-3" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="1"/></symbol><symbol id="fi198-b" viewBox="-1 -58 2 116"><use height="8" overflow="visible" transform="translate(0 54)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 42)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 30)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 18)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 6)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 -6)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 -18)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 -30)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 -42)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/><use height="8" overflow="visible" transform="translate(0 -54)" width="2" x="-1" xlink:href="#fi198-a" y="-4"/></symbol><symbol id="fi198-c" viewBox="-6 -58 12 116"><use height="116" overflow="visible" transform="translate(-5)" width="2" x="-1" xlink:href="#fi198-b" y="-58"/><use height="116" overflow="visible" width="2" x="-1" xlink:href="#fi198-b" y="-58"/><use height="116" overflow="visible" transform="translate(5)" width="2" x="-1" xlink:href="#fi198-b" y="-58"/></symbol><symbol id="fi198-d" viewBox="-21 -58 42 116"><use height="116" overflow="visible" transform="translate(-15)" width="12" x="-6" xlink:href="#fi198-c" y="-58"/><use height="116" overflow="visible" width="12" x="-6" xlink:href="#fi198-c" y="-58"/><use height="116" overflow="visible" transform="translate(15)" width="12" x="-6" xlink:href="#fi198-c" y="-58"/></symbol><symbol id="fi198-g" viewBox="-46 -58 92 116"><use height="116" overflow="visible" transform="translate(-25)" width="42" x="-21" xlink:href="#fi198-d" y="-58"/><use height="116" overflow="visible" transform="translate(25)" width="42" x="-21" xlink:href="#fi198-d" y="-58"/><use height="116" overflow="visible" width="2" x="-1" xlink:href="#fi198-b" y="-58"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M110 75H63v76.3l4.2 3.9.4 14.5 3.7 2.1 2.8 5.1 3.2 1.6 1.3 4.1 8.2.9 1.8 5 12.8.8 1.7 4.7h13.8l1.7-4.7 12.8-.8 1.8-5 8.2-.9 1.3-4.1 3.2-1.6 2.8-5.1 3.7-2.1.4-14.5 4.2-3.9V75z" id="fi198-e"/></defs><clipPath id="fi198-f"><use overflow="visible" xlink:href="#fi198-e"/></clipPath><g clip-path="url(#fi198-f)"><use height="116" overflow="visible" transform="matrix(1 0 0 -1 110 135)" width="92" x="-46" xlink:href="#fi198-g" y="-58"/></g>'
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