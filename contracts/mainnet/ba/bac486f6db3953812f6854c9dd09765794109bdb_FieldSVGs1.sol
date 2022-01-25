// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs1 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_0(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Perfect',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_1(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.997 49.997 0 0 0 50-50V72h-50v125Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_2(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-15H60v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_3(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Bend Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147V72L71.213 178.544a49.998 49.998 0 0 0 55.529 15.572A49.995 49.995 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_4(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 132h50v65a50 50 0 0 1-50-50v-15Zm50-60v60h50V72h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_5(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M148.787 178.544 110 132l50-60v75a49.787 49.787 0 0 1-11.213 31.544ZM60 147a49.788 49.788 0 0 0 11.213 31.545L110 132 60 72v75Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_6(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132v65a49.903 49.903 0 0 1-38.788-18.456L110 132Zm-50 0h50L60 72v60Zm100 15v-15h-50l38.787 46.544A49.782 49.782 0 0 0 160 147Zm-50-75v60l50-60h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_7(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Chevron',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 102-48.3 57.955a50 50 0 0 0 96.591 0L110 102Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_8(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Chevron Inverted',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m60 102 50 60 50-59.999V72H60v30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_9(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                unicode'Per Chevron Ployé',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 102c-6.1 27.234-23.986 52.3-45.333 66.091A50.006 50.006 0 0 0 110.001 197a50.008 50.008 0 0 0 26.884-7.842 50.007 50.007 0 0 0 18.45-21.067C133.985 154.3 116.1 129.235 110 102Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_10(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                unicode'Per Chevron Inverted Ployé',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 93.1c23.375 12.99 43.456 39.7 50 68.9 6.543-29.2 26.625-55.911 50-68.9V72H60v21.1Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_11(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Indented',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m100 92 20 10-20 10 20 10-20 10 20 10-20 10 20 10-20 10 20 10-20 10 10 5a49.997 49.997 0 0 0 50-50V72h-60l20 10-20 10Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_12(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Raguly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147V72h-54.219L115 82.926v10l-10-11.852v10l10 11.852v10l-10-11.852v10l10 11.852v10l-10-11.852v10l10 11.852v10l-10-11.852v10l10 11.852v10l-10-11.852v10l10 11.852v10l-10-11.852v10l5 5.926a49.997 49.997 0 0 0 50-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_13(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Embattled ',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M104.444 178.785v17.894A49.987 49.987 0 0 0 159.999 147V72h-54.781l-.774.119v13.333h11.111v13.334h-11.111v13.333h11.111v13.333h-11.111v13.333h11.111v13.334h-11.111v13.333h11.111v13.333h-11.111Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_14(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M115 87c0 7.181-10 7.819-10 15s10 7.819 10 15-10 7.82-10 15 10 7.819 10 15-10 7.819-10 15 10 7.82 10 15-10 7.82-10 15a6.977 6.977 0 0 0 2.027 4.9c.985.058 1.975.1 2.974.1a49.997 49.997 0 0 0 50-50V72H105c0 7.18 10 7.819 10 15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_15(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Rayonny',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M95 75.068c8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.677-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.118-11.043-5.1-18.956 13.677-30 7.115 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.437 11 21.564-2.763 30 7.119-11.043-5.1-18.956 13.676-30 7.114 8.105 10.566 20.537-1.707 28.982 6.072A50.013 50.013 0 0 0 160 147V72h-49.913c-4.768 3.258-9.531 6.37-15.087 3.068Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_16(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Nebuly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M95 79.5a10.607 10.607 0 0 0 15 0 10.604 10.604 0 0 1 11.559-2.3A10.607 10.607 0 1 1 110 94.5a10.604 10.604 0 0 0-11.56-2.3A10.607 10.607 0 1 0 110 109.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 124.5a10.603 10.603 0 0 0-11.558-2.299 10.61 10.61 0 0 0-4.76 15.691 10.61 10.61 0 0 0 10.887 4.51A10.603 10.603 0 0 0 110 139.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 154.5a10.603 10.603 0 0 0-11.558-2.299 10.61 10.61 0 0 0-4.76 15.691 10.61 10.61 0 0 0 10.887 4.51A10.603 10.603 0 0 0 110 169.5a10.605 10.605 0 0 1 16.32 1.607 10.61 10.61 0 0 1-4.761 15.693A10.615 10.615 0 0 1 110 184.5a10.596 10.596 0 0 0-12.312-1.949 10.597 10.597 0 0 0-5.653 11.11A50.001 50.001 0 0 0 160 147V72H91.893A10.576 10.576 0 0 0 95 79.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_17(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pall Nebuly II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 177a21.176 21.176 0 0 0-18.835-5.881 21.171 21.171 0 0 0-15.504 12.206 49.98 49.98 0 0 0 54.126 9.598A49.981 49.981 0 0 0 160 147V72H73.787A21.213 21.213 0 0 0 110 87c13.364-13.363 36.213-3.9 36.213 15S123.364 130.363 110 117a21.206 21.206 0 0 0-10.861-5.805 21.205 21.205 0 0 0-21.777 9.02 21.21 21.21 0 0 0 9.52 31.383 21.205 21.205 0 0 0 12.257 1.207A21.206 21.206 0 0 0 110 147c13.364-13.363 36.213-3.9 36.213 15S123.364 190.363 110 177Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_18(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Indented Pometty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M140 72a5.001 5.001 0 0 1-9.9.98l-40.2 8.04a5 5 0 1 0 0 1.96l40.2 8.04a5 5 0 1 1 0 1.96l-40.2 8.04a5 5 0 1 0 0 1.96l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A5.002 5.002 0 0 0 79.997 122a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5 5 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A4.998 4.998 0 0 0 79.997 142a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5.001 5.001 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A4.998 4.998 0 0 0 79.997 162a5 5 0 0 0 9.903.98l40.2 8.04a4.997 4.997 0 0 1 5.395-3.996 5.001 5.001 0 1 1-5.395 5.956l-40.2 8.04a4.998 4.998 0 0 0-5.395-3.996A4.998 4.998 0 0 0 79.997 182a5 5 0 0 0 9.903.98l40.2 8.04a4.974 4.974 0 0 1 3.272-3.753 4.968 4.968 0 0 1 4.885.967A49.928 49.928 0 0 0 160 147V72h-20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_19(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Indented',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M147.5 147 135 117l-12.5 30-12.5-30-12.5 30L85 117l-12.5 30L60 117v30a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-30l-12.5 30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_20(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Raguly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m150.28 127 8.334 10H147.5l-8.334-10h-11.108l8.334 10H125.28l-8.333-10h-11.111l8.333 10h-11.111l-8.333-10H83.614l8.333 10H80.836L72.5 127H61.393l8.333 10H60v10a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-20h-9.72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_21(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M148.889 125.333v13.333h-11.112v-13.333h-11.11v13.333h-11.112v-13.333h-11.111v13.333H93.333v-13.333H82.222v13.333H71.111v-13.333H60v21.684A50 50 0 1 0 160 147v-21.667h-11.111Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_22(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M143.333 137c-7.978 0-8.687-10-16.666-10-7.979 0-8.688 10-16.667 10-7.979 0-8.688-10-16.667-10-7.979 0-8.688 10-16.666 10S67.979 127 60 127v20a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-20c-7.979 0-8.688 10-16.667 10Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_23(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Rayonny',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.996 49.996 0 0 0 50-50v-9.031c-2.447-7.71-12.568-14.388-7.484-22.945-11 8.437 2.763 21.564-7.118 30 5.1-11.043-13.677-18.956-7.115-30-11 8.437 2.764 21.564-7.118 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.677-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.676-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30 5.1-11.043-13.676-18.956-7.114-30-11 8.437 2.763 21.564-7.119 30v1.99A50.001 50.001 0 0 0 110 197Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_24(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Nebuly I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147v-26.111a7.853 7.853 0 0 0-11.111 0 7.858 7.858 0 0 0 0 11.111 7.855 7.855 0 0 1 1.703 8.562 7.856 7.856 0 0 1-14.964-4.539 7.855 7.855 0 0 1 2.15-4.023 7.855 7.855 0 0 0 1.703-8.563 7.853 7.853 0 0 0-7.258-4.85 7.853 7.853 0 0 0-7.706 9.39 7.855 7.855 0 0 0 2.15 4.023 7.855 7.855 0 0 1 1.703 8.562 7.856 7.856 0 0 1-14.964-4.539 7.855 7.855 0 0 1 2.15-4.023 7.855 7.855 0 0 0 1.703-8.563 7.853 7.853 0 0 0-7.258-4.85 7.853 7.853 0 0 0-7.706 9.39 7.855 7.855 0 0 0 2.15 4.023 7.855 7.855 0 0 1-5.556 13.412 7.851 7.851 0 0 1-7.259-4.85A7.855 7.855 0 0 1 93.333 132a7.858 7.858 0 0 0-5.555-13.413 7.86 7.86 0 0 0-7.26 4.85A7.86 7.86 0 0 0 82.222 132a7.858 7.858 0 0 1-5.555 13.413 7.86 7.86 0 0 1-7.26-4.851A7.855 7.855 0 0 1 71.111 132 7.857 7.857 0 0 0 60 120.889v26.123a49.997 49.997 0 0 0 50.006 49.994 50.014 50.014 0 0 0 19.134-3.808A50.003 50.003 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_25(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Nebuly II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.999 49.999 0 1 0 100 0v-45.178a17.681 17.681 0 0 0-16.332 10.913A17.676 17.676 0 0 0 147.5 132c11.136 11.136 3.249 30.178-12.5 30.178S111.364 143.136 122.5 132a17.68 17.68 0 0 0-2.679-27.199 17.674 17.674 0 0 0-26.153 7.933A17.68 17.68 0 0 0 97.5 132c11.136 11.136 3.249 30.178-12.5 30.178S61.364 143.136 72.5 132A17.68 17.68 0 0 0 60 101.822V147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_26(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Indented Pometty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 102.006v.001-.001ZM160 97a5.001 5.001 0 0 0-4.034 7.952 5 5 0 0 0 3.016 1.943L148.519 157.1a5.005 5.005 0 0 1 3.017 1.943 5.004 5.004 0 0 1-4.036 7.952 5.002 5.002 0 0 1-4.974-4.488 5.007 5.007 0 0 1 .938-3.464 5.005 5.005 0 0 1 3.017-1.943l-10.462-50.2a5.005 5.005 0 0 0 3.017-1.943A5.004 5.004 0 0 0 135 97.005a5.002 5.002 0 0 0-4.974 4.488 5.007 5.007 0 0 0 .938 3.464 5.005 5.005 0 0 0 3.017 1.943l-10.462 50.2a5.005 5.005 0 0 1 3.017 1.943 5.004 5.004 0 0 1-4.036 7.952 5.002 5.002 0 0 1-4.974-4.488 5.007 5.007 0 0 1 .938-3.464 5.005 5.005 0 0 1 3.017-1.943l-10.462-50.2a5.005 5.005 0 0 0 3.017-1.943A5.004 5.004 0 0 0 110 97.005a5.002 5.002 0 0 0-4.974 4.488 5.007 5.007 0 0 0 .938 3.464 5.005 5.005 0 0 0 3.017 1.943l-10.462 50.2a5.004 5.004 0 0 1 3.955 5.407 5.004 5.004 0 0 1-4.974 4.488 5 5 0 0 1-1.019-9.895l-10.462-50.2a5.002 5.002 0 0 0 3.955-5.407 5 5 0 1 0-5.993 5.407l-10.462 50.2a5.002 5.002 0 0 1 3.955 5.407 5 5 0 1 1-5.993-5.407l-10.462-50.2A5.001 5.001 0 0 0 60 97v50a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V97Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_27(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess with a Left Step',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.997 49.997 0 0 0 50-50v-30h-50v30H60a49.997 49.997 0 0 0 50 50Z" fill="#',
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