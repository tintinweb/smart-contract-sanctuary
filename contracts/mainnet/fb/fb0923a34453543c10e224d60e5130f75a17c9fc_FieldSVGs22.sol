// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs22 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_285(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Sparkle',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi285-a"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath><symbol id="fi285-b" viewBox="0 0 51.494 60.927"><path d="M7.323 51.19A33.153 33.153 0 0 1 0 30v29.977l4.5-3.463ZM7.33 8.781C11.812 3.4 17.989.062 24.816 0H.013l2.276 5.647ZM50.007 29.971c0-14.98 3.345-23.06 0-29.971l-5.85 3.386-1.472 5.4a33.159 33.159 0 0 1 7.322 21.2ZM25 59.977c6.937 0 18.022 1.488 25 0 0 0-3.142-6.492-7.322-8.787-4.524 5.429-10.773 8.787-17.678 8.787v-21.19h7.321C36.847 33.358 43.1 30 50 30H32.323v-8.787A33.145 33.145 0 0 1 25 .023v21.19h-7.321C13.155 26.642 6.905 30 0 30h17.679v8.787A33.151 33.151 0 0 1 25 59.977" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M50 0H25.2c6.827.062 13 3.4 17.486 8.781ZM.012 0v29.983A33.152 33.152 0 0 1 7.33 8.781ZM25 59.988a33.163 33.163 0 0 1 7.322-21.2L25 30v29.988ZM17.679 38.787 25 30H0c6.905 0 13.155 3.358 17.679 8.787ZM17.679 21.213 25 30V.023a33.153 33.153 0 0 1-7.321 21.19ZM32.323 21.213 25 30h25c-6.9 0-13.153-3.358-17.677-8.787ZM42.678 51.19 50 59.977C53.015 55.483 50 42.1 50 30a33.153 33.153 0 0 1-7.322 21.19Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M7.323 51.19 0 59.977c4.861 2.137 12.5 0 25 0-6.9 0-13.153-3.358-17.677-8.787Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi285-a)"><use height="60.927" transform="translate(59.999 72)" width="51.494" xlink:href="#fi285-b"/><use height="60.927" transform="translate(109.999 72)" width="51.494" xlink:href="#fi285-b"/><use height="60.927" transform="translate(59.999 132)" width="51.494" xlink:href="#fi285-b"/><use height="60.927" transform="translate(109.999 132)" width="51.494" xlink:href="#fi285-b"/><use height="60.927" transform="translate(59.999 192)" width="51.494" xlink:href="#fi285-b"/><use height="60.927" transform="translate(109.999 192)" width="51.494" xlink:href="#fi285-b"/></g>'
                    )
                )
            );
    }

    function field_286(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Talon Matrix II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi286-d" viewBox="-26 -60.8 51 120"><path d="m17.1-6.3-2.4-5 1.9-1.6 3.8 2.6L25-.8l-7.9-5.5zm-2.4 16 2.4-5L25-.8l-4.6 9.5-3.8 2.6-1.9-1.6zM.8 34.1l1.7 10.1-2.5 15-2.5-15 1.7-10.1H.8zm4.1-5.9 7.6-1.5L25 29.2l-12.5 2.5-7.6-1.5v-2zm0-30 7.6-1.5L25-.8 12.5 1.6 4.9.1v-1.9zM2.2-35.3l2.4-5 9.2-7.1-5.9 11.1-3.8 2.6-1.9-1.6zm-1.4-.5H-.8l-1.7-10.1L0-59.2l2.5 13.3L.8-35.8zm4.1 4 7.6-1.5 10.3 2.5-10.3 2.5-7.6-1.5v-2zm-25.3 81.4 3.8-2.6 1.9 1.6-2.4 5-7.9 5.5 4.6-9.5zm37-2.6 3.8 2.6 4.6 9.5-7.9-5.5-2.4-5 1.9-1.6zm-40.8-12.9 1.7 10.1-2.5 15-1-15 1-10.1h1.6-.8zm-.8-94.9 7.9 5.5 2.4 5-1.9 1.6-3.8-2.6-4.6-9.5zm1.6 25H-25l-1-10.1 1-15 2.5 15-1.7 10.1h.8z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-b" viewBox="-4.1 -4.7 8.2 9.3"><path d="m-4.1 3 2.4-5 3.8-2.7 2 1.7-2.4 5-3.8 2.7-2-1.7z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-e" viewBox="-18.2 -21.7 36.3 43.3"><path d="m-4.7 12-7.6-1.5v-2L-4.7 7l7.6 1.5v2zM7 4.6 5.4-5.5 7-15.6h1.6l1.7 10.1L8.6 4.6H7zM-4.7-18l7.6-1.5v-1l-7.6-1.2-7.6 1.2v1z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="20.2" overflow="visible" transform="translate(-16.44 -5.49)" width="3.5" x="-1.7" xlink:href="#fi286-a" y="-10.1"/><use height="9.3" overflow="visible" transform="translate(1.58 17.01)" width="8.2" x="-4.1" xlink:href="#fi286-b" y="-4.7"/><use height="9.3" overflow="visible" transform="matrix(-1 0 0 1 14.08 17.01)" width="8.2" x="-4.1" xlink:href="#fi286-b" y="-4.7"/><use height="9.3" overflow="visible" transform="rotate(180 7.04 1)" width="8.2" x="-4.1" xlink:href="#fi286-b" y="-4.7"/><use height="9.3" overflow="visible" transform="matrix(1 0 0 -1 1.58 2.01)" width="8.2" x="-4.1" xlink:href="#fi286-b" y="-4.7"/><use height="9.3" overflow="visible" transform="matrix(-1 0 0 1 -10.92 -12.99)" width="8.2" x="-4.1" xlink:href="#fi286-b" y="-4.7"/></symbol><symbol id="fi286-g" viewBox="-4.9 -4.9 9.8 9.8"><path d="M-4.1 2.9 0 .1l-4.9 1 .8 1.8zM0 .1l-2.2 4.4 1.4.4L0 .1zm4.1 2.8L4.9 1 0 .1l4.1 2.8zM0 .1.8 5l1.4-.4L0 .1zm-4.1-3L-4.9-1 0 0l-4.1-2.9zM0-.1-.8-5l-1.4.4L0-.1zm4.1-2.8L0-.1l4.9-1-.8-1.8zM0-.1l2.2-4.4-1.4-.4L0-.1z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-c" viewBox="-17.4 10.2 9.8 9.8"><path d="m-8.5 12.3-4 2.8-2.1 4.4c2 1 4.5.5 5.9-1.3 1.4-1.8 1.4-4.2.2-5.9zm-4 2.8-4 2.8a4.8 4.8 0 0 1 .2-5.8c1.5-1.8 3.9-2.3 5.9-1.3l-2.1 4.3z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-f" viewBox="-4.9 -4.9 9.8 9.8"><path d="M-4.9-1 0 0l-1-4.9c-2 .4-3.5 2-3.9 3.9zm0 2L0 0l-1 4.9C-2.9 4.5-4.5 3-4.9 1zM1 4.9 0 0l4.9 1C4.5 2.9 3 4.5 1 4.9zM0 0l1-4.9C2.9-4.5 4.5-3 4.9-1L0 0z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-a" viewBox="-1.7 -10.1 3.5 20.2"><path d="M.1-10.1 1.7 0 .1 10.1h-.8L-1.7 0l1-10.1h.8z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi286-h" viewBox="-25.5 -60 51 120"><use height="9.8" overflow="visible" transform="translate(.5 29.94)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="matrix(-1 0 0 1 .5 29.94)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 .5 30.06)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="rotate(180 .25 15.03)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="translate(.5 -30.06)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="matrix(-1 0 0 1 .5 -30.06)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 .5 -29.94)" width="9.8" x="-17.4" xlink:href="#fi286-c" y="10.2"/><use height="120" overflow="visible" transform="translate(.5 .85)" width="51" x="-26" xlink:href="#fi286-d" y="-60.8"/><use height="43.3" overflow="visible" transform="translate(-7.33 20.49)" width="36.3" x="-18.2" xlink:href="#fi286-e" y="-21.7"/><use height="43.3" overflow="visible" transform="matrix(1 0 0 -1 -7.33 -20.51)" width="36.3" x="-18.2" xlink:href="#fi286-e" y="-21.7"/><use height="9.8" overflow="visible" transform="translate(.5)" width="9.8" x="-4.9" xlink:href="#fi286-f" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(.5 30)" width="9.8" x="-4.9" xlink:href="#fi286-g" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(.5 -30)" width="9.8" x="-4.9" xlink:href="#fi286-g" y="-4.9"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 132)" width="9.8" x="-4.9" xlink:href="#fi286-f" y="-4.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 162)" width="9.8" x="-4.9" xlink:href="#fi286-f" y="-4.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="9.8" x="-4.9" xlink:href="#fi286-f" y="-4.9"/><use height="120" overflow="visible" transform="matrix(1 0 0 -1 134.5 132)" width="51" x="-25.5" xlink:href="#fi286-h" y="-60"/><use height="120" overflow="visible" transform="rotate(180 42.8 66)" width="51" x="-25.5" xlink:href="#fi286-h" y="-60"/>'
                    )
                )
            );
    }

    function field_287(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tiles I',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi287-a" viewBox="-14.03 -15 28.05 30"><path d="M14.03-9.51 8.74-6.34l-3.05-5.49L10.97-15zM10.97 8.66 5.69 5.49 8.74 0l5.29 3.17zm-16.66 0h6.1V15h-6.1z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M8.74 0 5.69 5.49.41 8.66h-6.1l-5.28-3.17L-14.03 0v-6.34l3.06-5.49L-5.69-15h6.1l5.28 3.17 3.05 5.49z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi287-b" viewBox="-14.03 -30 28.05 60"><use height="30" overflow="visible" transform="translate(0 15)" width="28.05" x="-14.03" xlink:href="#fi287-a" y="-15"/><use height="30" overflow="visible" transform="translate(0 -15)" width="28.05" x="-14.03" xlink:href="#fi287-a" y="-15"/></symbol><symbol id="fi287-c" viewBox="-14.03 -60 28.05 180"><use height="60" overflow="visible" transform="translate(0 30)" width="28.05" x="-14.03" xlink:href="#fi287-b" y="-30"/><use height="60" overflow="visible" transform="translate(0 90)" width="28.05" x="-14.03" xlink:href="#fi287-b" y="-30"/><use height="60" overflow="visible" transform="translate(0 -30)" width="28.05" x="-14.03" xlink:href="#fi287-b" y="-30"/></symbol><symbol id="fi287-f" viewBox="-26.53 -97.5 53.05 195"><use height="180" overflow="visible" transform="translate(12.5 -37.5)" width="28.05" x="-14.03" xlink:href="#fi287-c" y="-60"/><use height="180" overflow="visible" transform="translate(-12.5 -22.5)" width="28.05" x="-14.03" xlink:href="#fi287-c" y="-60"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi287-d"/></defs><clipPath id="fi287-e"><use overflow="visible" xlink:href="#fi287-d"/></clipPath><g clip-path="url(#fi287-e)"><use height="195" overflow="visible" transform="matrix(1 0 0 -1 100.141 121.33)" width="53.05" x="-26.53" xlink:href="#fi287-f" y="-97.5"/><use height="195" overflow="visible" transform="matrix(1 0 0 -1 150.142 121.33)" width="53.05" x="-26.53" xlink:href="#fi287-f" y="-97.5"/><use height="180" overflow="visible" transform="matrix(1 0 0 -1 62.642 158.83)" width="28.05" x="-14.03" xlink:href="#fi287-c" y="-60"/></g>'
                    )
                )
            );
    }

    function field_288(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tiles IV',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M95 90.073H75V78.1h20v11.973Zm-29.814 0v24H75v-24h-9.814ZM75 175.182A45.179 45.179 0 0 0 95 189.4v-15.473H75v1.255Zm50 14.253a45.177 45.177 0 0 0 20-14.135v-1.371h-20v15.506Zm30-51.41V126.05h-10v11.975h10ZM65.047 126.05v11.975H75V126.05h-9.953ZM145 78.1h-20v11.973h20V78.1Zm0 35.977h10v-24h-10v24Zm-50 0H75v11.973h20v-11.973Zm10.093 0v-24H115V78.1h-10v11.973H95v24l10.093.004ZM125 126.05h-9.907v11.975H125v11.9h-9.907v-11.9h-10v11.9H95v-11.9H75v11.9h-9.813v.457a44.755 44.755 0 0 0 8.827 23.545H75V150h20v23.927h10.093V150h10v23.927H125V150h20v23.927h1.078a44.764 44.764 0 0 0 8.862-24H145v-11.9h-19.906V126.05H145v-11.975h-20v11.975Zm-29.907 0v11.975h10V126.05h-10Zm20 0v-11.975h-10v11.975h10ZM125 90.073h-9.907v24H125v-24ZM115 192h-10v-18.073h10V192Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M135 162h10l-10 11.975V162Zm0 0v-11.975L125 162h10Zm-50 0H75l10 11.975V162Zm10 0-10-11.975V162h10ZM85 90.023 75 102h10V90.023ZM85 102v11.975L95 102H85Zm50 0h10l-10-11.977V102Zm-10 0 10 11.975V102h-10Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_289(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Xanom',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi289-a" viewBox="-7.3 -8.5 14.5 17"><path d="M1.7 7.5-6.2 2l4.5-9.5L6.2-2z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M7.2-8.5 6.2-2l-7.9-5.5zM-6.2 2l7.9 5.5-9 1z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi289-b" viewBox="-13.5 -8.5 27 17"><use height="17" overflow="visible" transform="translate(-6.251)" width="14.5" x="-7.3" xlink:href="#fi289-a" y="-8.5"/><use height="17" overflow="visible" transform="matrix(-1 0 0 1 6.251 0)" width="14.5" x="-7.3" xlink:href="#fi289-a" y="-8.5"/></symbol><symbol id="fi289-c" viewBox="-13.5 -16 27 32"><use height="17" overflow="visible" transform="translate(0 7.5)" width="27" x="-13.5" xlink:href="#fi289-b" y="-8.5"/><use height="17" overflow="visible" transform="matrix(1 0 0 -1 0 -7.5)" width="27" x="-13.5" xlink:href="#fi289-b" y="-8.5"/></symbol><symbol id="fi289-d" viewBox="-51 -16 102 32"><use height="32" overflow="visible" transform="translate(-12.5)" width="27" x="-13.5" xlink:href="#fi289-c" y="-16"/><use height="32" overflow="visible" transform="translate(-37.5)" width="27" x="-13.5" xlink:href="#fi289-c" y="-16"/><use height="32" overflow="visible" transform="translate(12.5)" width="27" x="-13.5" xlink:href="#fi289-c" y="-16"/><use height="32" overflow="visible" transform="translate(37.5)" width="27" x="-13.5" xlink:href="#fi289-c" y="-16"/></symbol><symbol id="fi289-g" viewBox="-51 -31 102 62"><use height="32" overflow="visible" transform="translate(0 15)" width="102" x="-51" xlink:href="#fi289-d" y="-16"/><use height="32" overflow="visible" transform="translate(0 -15)" width="102" x="-51" xlink:href="#fi289-d" y="-16"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi289-e"/></defs><clipPath id="fi289-f"><use overflow="visible" xlink:href="#fi289-e"/></clipPath><g clip-path="url(#fi289-f)"><use height="62" overflow="visible" transform="matrix(1 0 0 -1 110.001 87)" width="102" x="-51" xlink:href="#fi289-g" y="-31"/><use height="62" overflow="visible" transform="matrix(1 0 0 -1 110.001 147)" width="102" x="-51" xlink:href="#fi289-g" y="-31"/><use height="32" overflow="visible" transform="matrix(1 0 0 -1 110.001 192)" width="102" x="-51" xlink:href="#fi289-d" y="-16"/></g>'
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