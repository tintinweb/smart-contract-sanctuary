// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs5 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_90(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M150.7 174.1c-2.8-3.5-2.4-8.6 1-11.5-3.5 3-8.8 2.7-11.8-.8s-2.7-8.7.7-11.7c-3.6 2.6-8.5 1.9-11.3-1.6-2.9-3.5-2.4-8.6 1-11.5-3.5 2.9-8.8 2.4-11.7-1.1-1-1.1-1.5-2.4-1.8-3.7.3-1.4.9-2.7 1.8-3.8 2.9-3.6 8.2-4 11.7-1.1l-.2-.2c-3.5-3-3.9-8.3-.9-11.8s8.3-3.9 11.8-.9c0-.1-.1-.1-.2-.2-3.5-3.1-3.9-8.3-.9-11.8 3.1-3.5 8.3-3.9 11.8-.9-3.5-2.9-4-8.1-1.1-11.6 2.3-2.9 6.1-3.8 9.4-2.5v-1.7c-.9-2.1-1-4.6 0-6.7v-7h-5.2c-2.9 3.3-8 3.6-11.4.8 3.6 2.9 4 8.2 1.1 11.7-2.9 3.6-8.2 4-11.7 1.1 3.3 3 3.8 8 1 11.5s-7.8 4.1-11.3 1.6c3.4 3.1 3.7 8.3.7 11.7-3.1 3.5-8.3 3.8-11.8.8 3.3 2.9 3.8 8 1 11.5-.6.8-1.3 1.4-2.1 1.9-.8-.5-1.5-1.1-2.1-1.9-2.9-3.5-2.4-8.6 1-11.5-3.6 2.9-8.8 2.3-11.7-1.3-2.8-3.5-2.4-8.6 1-11.5-3.6 2.9-8.8 2.3-11.7-1.3-2.8-3.5-2.4-8.6 1-11.5-3.5 2.9-8.8 2.4-11.7-1.1-2.9-3.5-2.4-8.8 1.1-11.7-3.4 2.8-8.5 2.4-11.4-.8H60v6.4c1.3 2.5 1.3 5.5 0 7.9v1.2c3.3-1.4 7.3-.6 9.7 2.4 2.8 3.5 2.4 8.7-1.1 11.6 3.5-3 8.8-2.6 11.8.9s2.6 8.8-.9 11.8c0 0 0 .1-.1.1 3.5-2.9 8.7-2.4 11.7 1 3 3.5 2.6 8.8-.9 11.8l-.2.2c3.5-2.9 8.8-2.4 11.7 1.1 1 1.1 1.5 2.4 1.8 3.7-.3 1.3-.9 2.6-1.8 3.7-2.9 3.6-8.2 4-11.7 1.1 3.6 2.9 4 8.2 1.1 11.7-2.8 3.5-7.8 4-11.3 1.4 3.4 3.1 3.7 8.2.7 11.7-3.1 3.5-8.3 3.8-11.8.8 3.3 3 3.8 8 1 11.5-.3.4-.7.7-1 1 1.7 2.5 3.7 4.9 5.8 7.1.3-1 .9-2 1.6-2.8 3-3.5 8.3-3.9 11.8-.9-3.5-3-4-8.2-1.1-11.7 2.9-3.6 8.1-4.1 11.7-1.2l-.2-.2c-3.5-3-3.9-8.3-.9-11.8s8.3-3.9 11.8-.9c-3.6-2.9-4-8.2-1.1-11.7.6-.7 1.3-1.3 2.1-1.8.8.5 1.5 1.1 2.1 1.8 2.9 3.5 2.4 8.8-1.1 11.7 3.5-3 8.8-2.6 11.8.9s2.6 8.8-.9 11.8l-.2.2c3.5-2.9 8.8-2.4 11.7 1.2 2.9 3.6 2.4 8.8-1.1 11.7 3.5-3 8.8-2.6 11.8.9.7.8 1.1 1.6 1.5 2.5 2.1-2.2 4-4.5 5.7-7-.3-.1-.6-.4-.8-.7Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_91(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevron I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 131.982v14.994a49.785 49.785 0 0 1-11.211 31.543L110 131.979l-38.791 46.537A49.788 49.788 0 0 1 60 146.976v-15L110 72l50 59.979v.003Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_92(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevron II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.213 178.544 110 132l38.787 46.545a49.85 49.85 0 0 0 9.509-18.59L110 102l-48.295 57.954a49.83 49.83 0 0 0 9.508 18.59Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_93(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevron Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.213 178.544A49.784 49.784 0 0 1 60 147v-1.907l7.037 8.464 6.094-7.309L67 138.87l6.082-7.319 6.142 7.387 6.093-7.309-6.152-7.4 6.083-7.319 6.162 7.405 6.09-7.305-6.17-7.41 6.083-7.318 6.187 7.418 6.093-7.309-6.193-7.432 6.5-7.827 6.5 7.827-6.195 7.432 6.095 7.309 6.184-7.422 6.082 7.318-6.166 7.414 6.093 7.309 6.163-7.405 6.083 7.319-6.153 7.4 6.094 7.309 6.141-7.387L153 138.87l-6.131 7.378 6.093 7.309 7.038-8.463V147a49.782 49.782 0 0 1-11.213 31.544L110 132l-38.787 46.544Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_94(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevron Inverted I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 73v60l-50 60-50-59.991V73l50 60 50-60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_95(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevron Inverted II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 102.001 110 162l50-60V72l-50 60-50-60v30.001Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_96(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Bars',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 144h100v3a49.78 49.78 0 0 1-4.624 21H64.624A49.792 49.792 0 0 1 60 147v-3Zm0-24h100V96H60v24Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_97(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Bars',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160,123.429v17.142H60V123.429Zm-8.476,51.428a49.729,49.729,0,0,0,7.313-17.143H61.163a49.729,49.729,0,0,0,7.313,17.143ZM60,89.143v17.143H160V89.143Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_98(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Four Bars',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.309,178.667a49.974,49.974,0,0,1-7.825-13.334h93.032a49.974,49.974,0,0,1-7.825,13.334ZM60,138.667V147q0,2.532.25,5h99.5q.246-2.468.25-5v-8.333ZM60,112v13.333H160V112Zm0-26.667V98.667H160V85.333Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_99(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pallets',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M120 72h20v115a49.777 49.777 0 0 1-20 9V72Zm-20 124V72H80v115a49.775 49.775 0 0 0 20 9Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_100(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Pallets',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M145.714 72v109.979a50.112 50.112 0 0 1-14.285 10.2V72h14.285ZM88.571 192.182V72H74.286v109.979a50.114 50.114 0 0 0 14.285 10.203ZM102.857 72v124.484A50.37 50.37 0 0 0 110 197a50.37 50.37 0 0 0 7.143-.516V72h-14.286Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_101(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Four Pallets',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M115.556 196.686V72h11.111v122.144a49.766 49.766 0 0 1-11.111 2.542Zm-33.334-8.111V72h-11.11v106.415a50.287 50.287 0 0 0 11.11 10.16ZM104.444 72h-11.11v122.144a49.765 49.765 0 0 0 11.11 2.542V72Zm44.445 106.415V72h-11.111v116.575a50.284 50.284 0 0 0 11.111-10.16Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_102(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pales Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M142.5 87a15 15 0 0 0 15 15 15.001 15.001 0 1 0 0 30 15.001 15.001 0 1 0 0 30 14.974 14.974 0 0 0-13.453 21.6 49.889 49.889 0 0 1-21.885 11.9 14.926 14.926 0 0 0-9.662-3.535h.626a14.993 14.993 0 0 0 14.318-15.288A14.993 14.993 0 0 0 112.5 162a15.001 15.001 0 1 0 0-30 15.001 15.001 0 1 0 0-30 15.002 15.002 0 0 0 15.007-14.993A15.003 15.003 0 0 0 112.513 72h44.974A14.999 14.999 0 0 0 142.5 87Zm-35.015-15H62.512a15 15 0 1 1-.013 30 15 15 0 1 1 0 30 15 15 0 1 1 0 30 14.977 14.977 0 0 1 14.98 14.236c.126 2.544-.4 5.079-1.527 7.364a49.9 49.9 0 0 0 21.884 11.9 14.93 14.93 0 0 1 9.663-3.535h-.625A14.992 14.992 0 0 1 107.5 162a15 15 0 1 1 0-30 15 15 0 1 1 0-30 15 15 0 0 1-.014-30h-.001Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_103(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pales Nebuly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi103-a" viewBox="-13.5 -10 26 20"><path d="M-12.5 0c0 3.5-1 10-1 10h1C-12.5 3.73-4.57.59.06 5.02 4.8 9.56 12.6 6.17 12.5 0 12.6-6.17 4.8-9.56.06-5.02-4.57-.59-12.5-3.73-12.5-10h-1s1 6.5 1 10z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi103-b" viewBox="-13.5 -20 26 40"><use height="20" transform="translate(0 -10)" width="26" x="-13.5" xlink:href="#fi103-a" y="-10"/><use height="20" transform="translate(0 10)" width="26" x="-13.5" xlink:href="#fi103-a" y="-10"/></symbol><symbol id="fi103-c" viewBox="-13.5 -40 26 80"><use height="40" transform="translate(0 20)" width="26" x="-13.5" xlink:href="#fi103-b" y="-20"/><use height="40" transform="translate(0 -20)" width="26" x="-13.5" xlink:href="#fi103-b" y="-20"/></symbol><symbol id="fi103-d" viewBox="-13.5 -80 26 160"><use height="80" transform="translate(0 40)" width="26" x="-13.5" xlink:href="#fi103-c" y="-40"/><use height="80" transform="translate(0 -40)" width="26" x="-13.5" xlink:href="#fi103-c" y="-40"/></symbol><symbol id="fi103-g" viewBox="-25 -85 50 170"><use height="160" transform="translate(12.5 -5)" width="26" x="-13.5" xlink:href="#fi103-d" y="-80"/><use height="160" transform="matrix(-1 0 0 1 -12.5 5)" width="26" x="-13.5" xlink:href="#fi103-d" y="-80"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M160 147c0 27.61-22.38 50-49.99 50H110c-27.61 0-50-22.39-50-50V72h100v75z" id="fi103-e"/></defs><clipPath id="fi103-f"><use xlink:href="#fi103-e"/></clipPath><g clip-path="url(#fi103-f)"><use height="170" transform="matrix(1 0 0 -1 85 147)" width="50" x="-25" xlink:href="#fi103-g" y="-85"/><use height="170" transform="matrix(1 0 0 -1 135.012 147)" width="50" x="-25" xlink:href="#fi103-g" y="-85"/></g>'
                    )
                )
            );
    }

    function field_104(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pales Wavy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M77.5 72h25c0 7.181-10 7.819-10 15s10 7.82 10 15-10 7.819-10 15 10 7.819 10 15-10 7.82-10 15 10 7.819 10 15-10 7.82-10 15 10 7.819 10 15a6.717 6.717 0 0 1-1.431 4.188 49.999 49.999 0 0 1-32.988-21.948c2.128-4.74 9.419-6.104 9.419-12.24 0-7.181-10-7.82-10-15s10-7.82 10-15-10-7.819-10-15 10-7.82 10-15-10-7.819-10-15 10-7.819 10-15Zm40 15c0 7.18 10 7.819 10 15s-10 7.82-10 15 10 7.819 10 15-10 7.82-10 15 10 7.819 10 15-10 7.819-10 15 10 7.819 10 15a6.686 6.686 0 0 1-.3 1.961 50.018 50.018 0 0 0 17.957-11.418A7.368 7.368 0 0 1 142.5 177c0-7.181 10-7.82 10-15s-10-7.818-10-15 10-7.82 10-15-10-7.819-10-15 10-7.819 10-15-10-7.82-10-15 10-7.819 10-15h-25c0 7.181-10 7.82-10 15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_105(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pales Wavy II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M135 94.5a7.498 7.498 0 0 0 7.5 7.5h10a7.497 7.497 0 0 1 7.5 7.5 7.497 7.497 0 0 1-7.5 7.5h-10a7.497 7.497 0 0 0-7.5 7.5 7.497 7.497 0 0 0 7.5 7.5h10a7.497 7.497 0 0 1 7.5 7.5 7.497 7.497 0 0 1-7.5 7.5h-10a7.497 7.497 0 0 0-7.5 7.5 7.497 7.497 0 0 0 7.5 7.5h10a7.462 7.462 0 0 1 4.657 1.628A49.897 49.897 0 0 1 150 177h-7.5a7.507 7.507 0 0 0-4.014 1.164 7.505 7.505 0 0 0-3.429 7.258 7.507 7.507 0 0 0 1.649 3.84 49.835 49.835 0 0 1-6.26 3.364A7.418 7.418 0 0 0 127.5 192h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.498 7.498 0 0 1-7.5-7.5 7.498 7.498 0 0 1 7.5-7.5h10a7.499 7.499 0 0 0 5.303-12.803A7.499 7.499 0 0 0 127.5 72h25a7.499 7.499 0 0 1 5.303 12.803A7.499 7.499 0 0 1 152.5 87h-10a7.499 7.499 0 0 0-7.5 7.5ZM102.5 192h-10a7.498 7.498 0 0 1-5.303-12.803A7.498 7.498 0 0 1 92.5 177h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.498 7.498 0 0 1-5.303-12.803A7.498 7.498 0 0 1 92.5 147h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.498 7.498 0 0 1-5.303-12.803A7.498 7.498 0 0 1 92.5 117h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.5 7.5 0 1 1 0-15h10a7.499 7.499 0 0 0 5.303-12.803A7.499 7.499 0 0 0 102.5 72h-25a7.5 7.5 0 0 1 0 15h-10a7.5 7.5 0 0 0 0 15h10a7.498 7.498 0 0 1 5.303 12.803A7.498 7.498 0 0 1 77.5 117h-10a7.498 7.498 0 0 0-5.303 12.803A7.498 7.498 0 0 0 67.5 132h10a7.498 7.498 0 0 1 5.303 12.803A7.498 7.498 0 0 1 77.5 147h-10a7.498 7.498 0 0 0-7.2 5.423 49.905 49.905 0 0 0 1.139 6.48 7.475 7.475 0 0 0 2.658 2.277 7.47 7.47 0 0 0 3.403.82h10a7.498 7.498 0 0 1 5.303 12.803A7.498 7.498 0 0 1 77.5 177H70a49.92 49.92 0 0 0 39.561 19.989A7.495 7.495 0 0 0 102.5 192Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_106(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Pales Dancetty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M72.5 72H85l25 7.5L85 87l25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-22.99 6.9a50.016 50.016 0 0 1-7.931-5.121L85 184.5l-11.64-3.492a50.283 50.283 0 0 1-5.1-6.486L85 169.5l-22.449-6.735a62.623 62.623 0 0 1-.445-1.4L85 154.5 60 147l25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5L60 87l25-7.5L60 72h12.5Zm37.5 0 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-22.99 6.9a49.84 49.84 0 0 0 10.526 4.018 49.989 49.989 0 0 0 24.486-14.808L135 177l18.634-5.59a51.342 51.342 0 0 0 1.7-3.311L135 162l24.413-7.324c.017-.112.029-.226.046-.338L135 147l25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5h-25Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_107(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Orle',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M70 82v65a39.998 39.998 0 0 0 40 40 39.996 39.996 0 0 0 28.284-11.716A39.996 39.996 0 0 0 150 147V82H70Zm70 65a30 30 0 0 1-60 0V92h60v55Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_108(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Orle Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M150 92v-5h-4.54v-5H140v5h-5.46v-5h-5.45v5h-5.46v-5h-5.45v5h-5.46v-5h-5.45v5h-5.46v-5h-5.45v5H90.9v-5h-5.45v5H80v-5h-5v5h-5v5h5v4.58h-5v5h5v4.58h-5v5h5v4.58h-5v5h5v4.58h-5v5h5v4.58h-5v5h5v4.58h-5v5h5l.65 4.16-4.98 1.36 1.29 4.83 5.01-1.34 1.59 3.81-4.49 2.59 2.5 4.33 4.47-2.58 2.54 3.26-3.66 3.66 3.54 3.54 3.66-3.66 3.26 2.54-2.57 4.45 4.33 2.5 2.58-4.47 3.82 1.59-1.33 4.96 4.83 1.3 1.32-4.95 4.11.52V187h5v-5.13l4.11-.52 1.32 4.95 4.83-1.3-1.33-4.96 3.82-1.59 2.58 4.47 4.33-2.5-2.57-4.45 3.26-2.54 3.66 3.66 3.54-3.54-3.66-3.66 2.54-3.26 4.47 2.58 2.5-4.33-4.49-2.59 1.59-3.81 5.01 1.34 1.3-4.83-4.98-1.34.65-4.16h5v-5h-5v-4.58h5v-5h-5v-4.58h5v-5h-5v-4.58h5v-5h-5v-4.58h5v-5h-5v-4.58h5v-5h-5V92H150zm-40 85c-16.56-.02-29.98-13.44-30-30V92h60v55c-.02 16.56-13.44 29.98-30 30z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_109(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pall',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 117.941 71.714 72H60v14.06l41 49.2v60.918a49.592 49.592 0 0 0 18 0v-60.92l41-49.2V72h-11.716L110 117.941Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_110(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pall Inverted',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M119 128.742V72h-18v56.741L65.992 170.75a50.192 50.192 0 0 0 11.545 14.262L110 146.059l32.461 38.955a50.162 50.162 0 0 0 11.546-14.263L119 128.742Z" fill="#',
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