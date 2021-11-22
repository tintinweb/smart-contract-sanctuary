// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../interfaces/IShieldSVGs.sol';
import '../libraries/HexStrings.sol';

/// @dev Generate Shield SVG
contract ShieldSVGs1 is IShieldSVGs {
    using HexStrings for uint24;

    function shield_0(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Perfect',
                'Mythic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_1(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M110 197a49.997 49.997 0 0 0 50-50V72h-50v125Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_2(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M60 147a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-15H60v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_3(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Bend Sinister',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M160 147V72L71.213 178.544a49.998 49.998 0 0 0 55.529 15.572A49.995 49.995 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_4(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Quarterly',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M60 132h50v65a50 50 0 0 1-50-50v-15Zm50-60v60h50V72h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_5(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Saltire',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M148.787 178.544 110 132l50-60v75a49.787 49.787 0 0 1-11.213 31.544ZM60 147a49.788 49.788 0 0 0 11.213 31.545L110 132 60 72v75Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_6(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Gyronny',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M110 132v65a49.903 49.903 0 0 1-38.788-18.456L110 132Zm-50 0h50L60 72v60Zm100 15v-15h-50l38.787 46.544A49.782 49.782 0 0 0 160 147Zm-50-75v60l50-60h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_7(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale Embattled ',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M104.444 178.785v17.894A49.987 49.987 0 0 0 159.999 147V72h-54.781l-.774.119v13.333h11.111v13.334h-11.111v13.333h11.111v13.333h-11.111v13.333h11.111v13.334h-11.111v13.333h11.111v13.333h-11.111Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_8(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale Wavy',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M115 87c0 7.181-10 7.819-10 15s10 7.819 10 15-10 7.82-10 15 10 7.819 10 15-10 7.819-10 15 10 7.82 10 15-10 7.82-10 15a6.977 6.977 0 0 0 2.027 4.9c.985.058 1.975.1 2.974.1a49.997 49.997 0 0 0 50-50V72H105c0 7.18 10 7.819 10 15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_9(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale Rayonny',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M95 75.068c8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.677-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.118-11.043-5.1-18.956 13.677-30 7.115 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.105 10.566 20.537-1.707 28.982 6.072A50.013 50.013 0 0 0 160 147V72h-49.913c-4.768 3.258-9.531 6.37-15.087 3.068Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_10(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale Nebuly',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M95 79.5a10.607 10.607 0 0 0 15 0 10.604 10.604 0 0 1 11.559-2.3A10.607 10.607 0 1 1 110 94.5a10.604 10.604 0 0 0-11.56-2.3A10.607 10.607 0 1 0 110 109.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 124.5a10.603 10.603 0 0 0-11.558-2.299 10.61 10.61 0 0 0-4.76 15.691 10.61 10.61 0 0 0 10.887 4.51A10.603 10.603 0 0 0 110 139.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 154.5a10.603 10.603 0 0 0-11.558-2.299 10.61 10.61 0 0 0-4.76 15.691 10.61 10.61 0 0 0 10.887 4.51A10.603 10.603 0 0 0 110 169.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 184.5a10.596 10.596 0 0 0-12.312-1.949 10.597 10.597 0 0 0-5.653 11.11A50.001 50.001 0 0 0 160 147V72H91.893A10.576 10.576 0 0 0 95 79.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_11(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pall Nebuly II',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M110 177a21.176 21.176 0 0 0-18.835-5.881 21.171 21.171 0 0 0-15.504 12.206 49.98 49.98 0 0 0 54.126 9.598A49.981 49.981 0 0 0 160 147V72H73.787A21.213 21.213 0 0 0 110 87c13.364-13.363 36.213-3.9 36.213 15S123.364 130.363 110 117a21.206 21.206 0 0 0-10.861-5.805 21.205 21.205 0 0 0-21.777 9.02 21.21 21.21 0 0 0 9.52 31.383 21.205 21.205 0 0 0 12.257 1.207A21.206 21.206 0 0 0 110 147c13.364-13.363 36.213-3.9 36.213 15S123.364 190.363 110 177Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_12(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Pale Indented Pometty',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M140 72a5.001 5.001 0 0 1-9.9.98l-40.2 8.04a5 5 0 1 0 0 1.96l40.2 8.04a5 5 0 1 1 0 1.96l-40.2 8.04a5 5 0 1 0 0 1.96l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A5.002 5.002 0 0 0 79.997 122a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A5.002 5.002 0 0 0 79.997 142a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A5.002 5.002 0 0 0 79.997 162a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A5.002 5.002 0 0 0 79.997 182a5 5 0 0 0 9.903.98l40.2 8.04a4.974 4.974 0 0 1 3.272-3.753 4.968 4.968 0 0 1 4.885.967A49.928 49.928 0 0 0 160 147V72h-20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_13(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Indented',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M147.5 147 135 117l-12.5 30-12.5-30-12.5 30L85 117l-12.5 30L60 117v30a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-30l-12.5 30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_14(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Raguly',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="m150.28 127 8.334 10H147.5l-8.334-10h-11.108l8.334 10H125.28l-8.333-10h-11.111l8.333 10h-11.111l-8.333-10H83.614l8.333 10H80.836L72.5 127H61.393l8.333 10H60v10a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-20h-9.72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_15(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Embattled',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M148.889 125.333v13.333h-11.112v-13.333h-11.11v13.333h-11.112v-13.333h-11.111v13.333H93.333v-13.333H82.222v13.333H71.111v-13.333H60v21.684A50 50 0 1 0 160 147v-21.667h-11.111Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_16(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Wavy',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M143.333 137c-7.978 0-8.687-10-16.666-10-7.979 0-8.688 10-16.667 10-7.979 0-8.688-10-16.667-10-7.979 0-8.688 10-16.666 10S67.979 127 60 127v20a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-20c-7.979 0-8.688 10-16.667 10Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_17(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Rayonny',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M110 197a49.996 49.996 0 0 0 50-50v-9.031c-2.447-7.71-12.568-14.388-7.484-22.945-11 8.437 2.763 21.564-7.118 30 5.1-11.043-13.677-18.956-7.115-30-11 8.437 2.764 21.564-7.118 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.676-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.676-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30v1.99A50.001 50.001 0 0 0 110 197Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_18(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Fess Nebuly I',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M160 147v-26.111a7.853 7.853 0 0 0-11.111 0 7.858 7.858 0 0 0 0 11.111 7.855 7.855 0 0 1 1.703 8.562 7.856 7.856 0 0 1-14.964-4.539 7.855 7.855 0 0 1 2.15-4.023 7.855 7.855 0 0 0 1.703-8.563 7.853 7.853 0 0 0-7.258-4.85 7.853 7.853 0 0 0-7.706 9.39 7.855 7.855 0 0 0 2.15 4.023 7.855 7.855 0 0 1 1.703 8.562 7.856 7.856 0 0 1-14.964-4.539 7.855 7.855 0 0 1 2.15-4.023 7.855 7.855 0 0 0 1.703-8.563 7.853 7.853 0 0 0-7.258-4.85 7.853 7.853 0 0 0-7.706 9.39 7.855 7.855 0 0 0 2.15 4.023 7.855 7.855 0 0 1-5.556 13.412 7.851 7.851 0 0 1-7.259-4.85A7.856 7.856 0 0 1 93.333 132a7.858 7.858 0 0 0-5.555-13.413 7.86 7.86 0 0 0-7.26 4.85A7.86 7.86 0 0 0 82.222 132a7.858 7.858 0 0 1-5.555 13.413 7.86 7.86 0 0 1-7.26-4.851A7.855 7.855 0 0 1 71.111 132 7.857 7.857 0 0 0 60 120.889v26.123a49.997 49.997 0 0 0 50.006 49.994 50.014 50.014 0 0 0 19.134-3.808A50.003 50.003 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_19(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Per Bend Sinister Bevilled',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M110 162v-60l-40.939 73.69a49.995 49.995 0 0 0 81.267.872A49.998 49.998 0 0 0 160 147V72l-50 90Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }

    function shield_20(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Quarterly Embattled',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><path d="M98.461 136.615h7.692v9.231h7.693v9.231h-7.693v9.231h7.693v9.23h-7.693v9.231h7.693V192h-7.693v4.838A49.99 49.99 0 0 1 60 147v-19.615h7.692v9.23h7.692v-9.23h7.693v9.23h7.692v-9.23h7.692v9.23Zm7.692 0h7.693v-9.23h-7.693v9.23Zm7.693-55.384v9.231h-7.693v9.23h7.693v9.231h-7.693v9.231h7.693v9.231h7.692v9.23h7.693v-9.23h7.692v9.23h7.692v-9.23h7.692v9.23H160V72h-53.847v9.231h7.693Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Generate Shield SVG
interface IShieldSVGs {
    struct ShieldData {
        string title;
        string svgType;
        string svgString;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}