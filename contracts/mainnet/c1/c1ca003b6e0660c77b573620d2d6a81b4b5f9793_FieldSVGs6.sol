// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs6 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_111(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pile',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M77.104 72 110 197l32.895-125H77.104Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_112(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                unicode'Pile Ployé',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M59.5 72C110 132 110 192 110 192s0-60 50.5-120h-101Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_113(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pile Inverted',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72 79.783 186.821a49.936 49.936 0 0 0 60.433 0L110 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_114(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                unicode'Pile Inverted Ployé',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M149.4 177.7C110 122.9 110 72 110 72s0 50.9-39.4 105.7C79.7 189.5 94 197 110 197s30.3-7.5 39.4-19.3Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_115(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Two Piles',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m160 72-50 120 16.667-120H160Zm-66.667 0H60l50 120L93.333 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_116(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Flaunches',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.213 178.544A49.784 49.784 0 0 1 60 147V72c18.066 21.679 25 41.2 25 60 0 18.8-9.149 40.972-13.787 46.544Zm77.574 0A49.782 49.782 0 0 0 160 147V72c-18.066 21.679-25 41.2-25 60 0 18.8 9.149 40.972 13.787 46.544Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_117(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyron',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m60 72 50 60H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_118(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Pale',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 72H60v30h33.333v92.144A49.909 49.909 0 0 0 110 197a49.91 49.91 0 0 0 16.667-2.856V102H160V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_119(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierce',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M85 190.294V72H60v75a49.97 49.97 0 0 0 25 43.294Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_120(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierce Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147V72h-25v118.294A49.969 49.969 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_121(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierces',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147V72h25v118.294A49.965 49.965 0 0 1 60 147Zm100 0V72h-25v118.294A49.969 49.969 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_122(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gore',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m109.999 196.998-.002.002H110l-.001-.002Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.997 49.997 0 0 0 50 50 44.671 44.671 0 0 1 0-65h-.079c-19.026-.036-35.557-12.826-43.981-31.626a64.134 64.134 0 0 1-5.67-22.151c-.009-.106-.015-.213-.024-.32A79.168 79.168 0 0 1 60 72.018V72v75Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_123(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gore Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m109.999 196.998-.002.002H110l-.001-.002Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M159.837 147a49.997 49.997 0 0 1-50 50 44.676 44.676 0 0 0 14.025-32.5 44.668 44.668 0 0 0-14.025-32.5h.078c19.027-.036 35.558-12.826 43.982-31.626a64.15 64.15 0 0 0 5.67-22.151c.009-.106.015-.213.024-.32.063-.84.124-1.681.161-2.543.051-1.106.081-2.218.081-3.339V72l.004 75Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_124(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gores',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.997 49.997 0 0 0 50 50 44.671 44.671 0 0 1 0-65h-.079c-19.026-.036-35.557-12.826-43.981-31.626a64.134 64.134 0 0 1-5.67-22.151c-.009-.106-.015-.213-.024-.32A79.168 79.168 0 0 1 60 72.018V72v75Zm99.837-75v.018c0 1.121-.03 2.233-.081 3.339-.037.862-.1 1.7-.161 2.543-.009.107-.015.214-.024.32a64.127 64.127 0 0 1-5.67 22.151c-8.424 18.8-24.955 31.59-43.982 31.626h-.078a44.676 44.676 0 0 1 14.025 32.5 44.668 44.668 0 0 1-14.025 32.5 49.993 49.993 0 0 0 35.355-14.645 50.007 50.007 0 0 0 14.645-35.355L159.837 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_125(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly of Four',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M135 72h25v75a49.97 49.97 0 0 1-25 43.294V72ZM85 190.294A49.746 49.746 0 0 0 110 197V72H85v118.294Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_126(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M72.5 180.054V72H85v118.294a50.197 50.197 0 0 1-12.5-10.24Zm25 15.371A50.102 50.102 0 0 0 110 197V72H97.5v123.425Zm50-15.371A49.8 49.8 0 0 0 160 147V72h-12.5v108.054Zm-25 15.371a49.654 49.654 0 0 0 12.5-5.131V72h-12.5v123.425Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_127(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly Dancetty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m143.333 162 16.063-7.228a49.613 49.613 0 0 1-3.8 12.745L143.333 162ZM62.7 163.217a49.73 49.73 0 0 0 4.941 10.343l9.022-4.06-13.963-6.283ZM60 147c0 4.769.682 9.513 2.026 14.088l14.641-6.588L60 147Zm88.235 32.206a50.138 50.138 0 0 0 4.658-6.508l-9.56 4.3 4.902 2.208ZM160 72h-16.667L160 79.5 143.333 87 160 94.5l-16.667 7.5L160 109.5l-16.667 7.5L160 124.5l-16.667 7.5L160 139.5l-16.667 7.5 16.136 7.261c.352-2.404.529-4.831.531-7.261V72Zm-33.333 0H110l16.667 7.5L110 87l16.667 7.5L110 102l16.667 7.5L110 117l16.667 7.5L110 132l16.667 7.5L110 147l16.666 7.5L110 162l16.667 7.5L110 177l16.667 7.5L110 192l9.2 4.141a49.59 49.59 0 0 0 10.04-2.983L126.667 192l16.086-7.239c.132-.115.266-.228.4-.344L126.667 177l16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5 16.666-7.5-16.666-7.5Zm-23.2 124.562L93.334 192 110 184.5 93.334 177 110 169.5 93.334 162 110 154.5 93.334 147 110 139.5 93.334 132 110 124.5 93.334 117 110 109.5 93.334 102 110 94.5 93.334 87 110 79.5 93.334 72H76.667l16.667 7.5L76.667 87l16.667 7.5-16.667 7.5 16.667 7.5-16.667 7.5 16.667 7.5-16.667 7.5 16.667 7.5-16.667 7.5 16.667 7.5-16.667 7.5 16.667 7.5-16.667 7.5 16.667 7.5-10.264 4.618a49.664 49.664 0 0 0 20.401 7.444h-.004ZM60 87v15l16.667-7.5L60 87Zm0-15v15l16.667-7.5L60 72Zm0 60v15l16.667-7.5L60 132Zm0-30v15l16.667-7.5L60 102Zm0 15v15l16.667-7.5L60 117Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_128(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M89.651 182H85v-10h4.651v-10H85v-10h4.651v-10H85v-10h4.651v-10H85v-10h4.651v-10H85V92h4.651V82H85V72H74.535v10h-4.651v10h4.651v10h-4.651v10h4.651v10h-4.651v10h4.651v10h-4.651v10h4.651v10h-4.651v10h4.651v10h-.229a50.129 50.129 0 0 0 13.881 10h1.464v-10Zm60.465-110H135v10h-4.651v10H135v10h-4.651v10H135v10h-4.651v10H135v10h-4.651v10H135v10h-4.651v10H135v10h-4.651v10h1.464a50.124 50.124 0 0 0 13.881-10h-.229v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651V92h4.651V82h-4.651V72h4.651Zm-30.232 120v-10h-4.651v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651v-10h4.651v-10h-4.651V92h4.651V82h-4.651V72h-10.465v10h-4.652v10h4.652v10h-4.652v10h4.652v10h-4.652v10h4.652v10h-4.652v10h4.652v10h-4.652v10h4.652v10h-4.652v10h4.652v4.727a50.507 50.507 0 0 0 10.465 0V192h4.651Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_129(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly Wavy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147a49.77 49.77 0 0 1-5.539 22.866c-1.579-2.926-6.127-3.908-6.127-7.866 0-4.788 6.666-5.213 6.666-10s-6.666-5.213-6.666-10S155 136.787 155 132s-6.666-5.213-6.666-10S155 116.786 155 112s-6.666-5.213-6.666-10S155 96.786 155 92s-6.666-5.213-6.666-10S155 76.786 155 72h5v75Zm-21.667-75h-16.666c0 4.786-6.667 5.212-6.667 10s6.667 5.212 6.667 10S115 97.211 115 102s6.667 5.212 6.667 10S115 117.212 115 122s6.667 5.213 6.667 10c0 4.788-6.667 5.213-6.667 10s6.667 5.212 6.667 10S115 157.212 115 162s6.667 5.212 6.667 10S115 177.213 115 182s6.667 5.213 6.667 10a5.233 5.233 0 0 1-2.217 4.1 49.676 49.676 0 0 0 17.726-7.135c-1.908-2.274-5.509-3.439-5.509-6.961 0-4.787 6.666-5.213 6.666-10s-6.666-5.213-6.666-10 6.666-5.213 6.666-10-6.666-5.212-6.666-10 6.666-5.213 6.666-10-6.666-5.213-6.666-10 6.666-5.213 6.666-10-6.666-5.213-6.666-10 6.666-5.213 6.666-10-6.666-5.212-6.666-10 6.665-5.219 6.666-10.004Zm-66.667 0H60v75a49.76 49.76 0 0 0 9.387 29.148A5.3 5.3 0 0 0 71.666 172c0-4.788-6.667-5.213-6.667-10s6.667-5.213 6.667-10S65 146.787 65 142s6.667-5.213 6.667-10S65 126.787 65 122s6.667-5.213 6.667-10S65 106.786 65 102s6.667-5.213 6.667-10S65 86.786 65 82s6.664-5.215 6.666-10ZM105 72H88.333c0 4.786-6.667 5.212-6.667 10s6.667 5.212 6.667 10-6.667 5.213-6.667 10 6.667 5.212 6.667 10-6.667 5.213-6.667 10 6.667 5.213 6.667 10-6.667 5.213-6.667 10 6.667 5.212 6.667 10-6.667 5.213-6.667 10 6.667 5.212 6.667 10-6.667 5.213-6.667 10 6.667 5.213 6.667 10c0 .025-.006.046-.006.071a49.638 49.638 0 0 0 14.063 4.353c1.393-1.132 2.61-2.38 2.61-4.424 0-4.787-6.666-5.213-6.666-10S105 176.787 105 172s-6.667-5.213-6.667-10S105 156.787 105 152s-6.667-5.212-6.667-10S105 136.786 105 132c0-4.787-6.666-5.213-6.666-10S105 116.786 105 112s-6.667-5.213-6.667-10S105 96.786 105 92s-6.667-5.212-6.667-10S105 76.785 105 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_130(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Paly Wavy II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi130-a" viewBox="-8.33 -10 18.71 20"><path d="M8.33 10c0-2.76-2.24-5-5-5h-6.67c-2.76 0-5-2.24-5-5s2.24-5 5-5h6.67c2.76 0 5-2.24 5-5h2.04S8.33-6.14 8.33 0s2.04 10 2.04 10H8.33z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi130-b" viewBox="-8.33 -20 18.71 40"><use height="20" transform="translate(0 -10)" width="18.71" x="-8.33" xlink:href="#fi130-a" y="-10"/><use height="20" transform="translate(0 10)" width="18.71" x="-8.33" xlink:href="#fi130-a" y="-10"/></symbol><symbol id="fi130-c" viewBox="-8.33 -40 18.71 80"><use height="40" transform="translate(0 20)" width="18.71" x="-8.33" xlink:href="#fi130-b" y="-20"/><use height="40" transform="translate(0 -20)" width="18.71" x="-8.33" xlink:href="#fi130-b" y="-20"/></symbol><symbol id="fi130-d" viewBox="-8.33 -80 18.71 160"><use height="80" transform="translate(0 40)" width="18.71" x="-8.33" xlink:href="#fi130-c" y="-40"/><use height="80" transform="translate(0 -40)" width="18.71" x="-8.33" xlink:href="#fi130-c" y="-40"/></symbol><symbol id="fi130-g" viewBox="-16.58 -85 33.33 170"><use height="160" transform="translate(-8.25 -5)" width="18.71" x="-8.33" xlink:href="#fi130-d" y="-80"/><use height="160" transform="matrix(-1 0 0 1 8.417 5)" width="18.71" x="-8.33" xlink:href="#fi130-d" y="-80"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M160 147c0 27.61-22.38 50-49.99 50H110c-27.61 0-50-22.39-50-50V72h100v75z" id="fi130-e"/></defs><clipPath id="fi130-f"><use xlink:href="#fi130-e"/></clipPath><g clip-path="url(#fi130-f)"><use height="170" transform="matrix(1 0 0 -1 93.25 132)" width="33.33" x="-16.58" xlink:href="#fi130-g" y="-85"/><use height="170" transform="matrix(1 0 0 -1 59.916 132)" width="33.33" x="-16.58" xlink:href="#fi130-g" y="-85"/><use height="170" transform="matrix(1 0 0 -1 126.584 132)" width="33.33" x="-16.58" xlink:href="#fi130-g" y="-85"/><use height="170" transform="matrix(1 0 0 -1 159.917 132)" width="33.33" x="-16.58" xlink:href="#fi130-g" y="-85"/></g>'
                    )
                )
            );
    }

    function field_131(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry of Four',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 102h100v30H60v-30Zm2.292 60A50.023 50.023 0 0 0 110 197a50.024 50.024 0 0 0 47.708-35H62.292Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_132(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 132H60v-15h100v15Zm-10 45H70a49.928 49.928 0 0 0 40 20h.01a49.911 49.911 0 0 0 22.359-5.273A49.91 49.91 0 0 0 150 177Zm-90-30a49.97 49.97 0 0 0 2.292 15h95.416A49.976 49.976 0 0 0 160 147.01V147H60Zm0-45h100V87H60v15Z" fill="#',
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