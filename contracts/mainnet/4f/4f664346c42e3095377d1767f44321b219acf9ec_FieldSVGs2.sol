// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs2 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_28(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Fess Enarched',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-5s-17.443-20-50-20-50 20-50 20v5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_29(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Bend Sinister Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147V72h-.433a12.47 12.47 0 0 1-8.614 6.634 12.464 12.464 0 0 1-10.544-2.65 12.495 12.495 0 0 1 4.665 8.511 12.52 12.52 0 0 1-.478 4.928 12.515 12.515 0 0 1-6.214 7.456 12.497 12.497 0 0 1-13.973-1.695 12.5 12.5 0 1 1-16 19.206 12.5 12.5 0 1 1-16 19.2 12.506 12.506 0 0 1 4.086 13.392 12.505 12.505 0 0 1-10.904 8.783 12.5 12.5 0 0 1-9.182-2.969A12.495 12.495 0 0 1 68.5 174.9a49.994 49.994 0 0 0 24.751 19.223 49.995 49.995 0 0 0 56.934-17.36A49.995 49.995 0 0 0 160 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_30(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Bend Sinister Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.997 49.997 0 0 0 50-50V79.012c-4.7 2.885-11.538-1.225-15.621 3.675-4.6 5.516 2.676 12.408-1.921 17.924s-12.688-.394-17.285 5.122c-4.597 5.516 2.676 12.409-1.92 17.926-4.596 5.517-12.689-.4-17.286 5.122-4.597 5.522 2.677 12.408-1.92 17.925-4.597 5.517-12.688-.395-17.286 5.122-4.598 5.517 2.677 12.408-1.92 17.925-4.418 5.3-12.06.054-16.73 4.533A49.95 49.95 0 0 0 110 197Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_31(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Bend Sinister Bevilled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 162v-60l-40.939 73.69a49.995 49.995 0 0 0 81.267.872A49.991 49.991 0 0 0 160 147V72l-50 90Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_32(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M98.461 136.615h7.692v9.231h7.693v9.231h-7.693v9.231h7.693v9.23h-7.693v9.231h7.693V192h-7.693v4.838A49.99 49.99 0 0 1 60 147v-19.615h7.692v9.23h7.692v-9.23h7.693v9.23h7.692v-9.23h7.692v9.23Zm7.692 0h7.693v-9.23h-7.693v9.23Zm7.693-55.384v9.231h-7.693v9.23h7.693v9.231h-7.693v9.231h7.693v9.231h7.692v9.23h7.693v-9.23h7.692v9.23h7.692v-9.23h7.692v9.23H160V72h-53.847v9.231h7.693Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_33(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly Arrondi',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72s-10.1 14.1-10.1 30 10.1 30 10.1 30 11.7-10.1 25-10.1 25 10.1 25 10.1V72h-50Zm-50 60v15c0 26.5 20.6 48.3 47 49.9.9-1.7 1.9-3.3 3-4.9 0 0 10.1-14.1 10.1-30S110 132 110 132s-11.7 10.1-25 10.1S60 132 60 132Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_34(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny Arrondi of Twelve',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132s10.046-1.4 23.9 6.6c8.8 5.078 19.167 18.459 18.266 35.253a49.973 49.973 0 0 1-50.164 22.5c4.508-.376 10.362-1.208 14.172-3.056C135.143 184.45 140.1 149.376 110 132Zm-43.858 39.02A50.207 50.207 0 0 0 88.3 192.056c19.7-5.894 27.941-24.53 27.941-36.057 0-16-6.238-24-6.238-24-.003 30.949-26.047 44.823-43.861 39.021ZM160 138.676v-25.985c-12.21-4.607-25.027-2.312-32.335 1.907C113.809 122.6 110 132 110 132c20.681-11.94 40.323-5.369 50 6.676ZM60 125.323V147c0 1.478.077 2.938.2 4.384 12.15 4.506 24.865 2.214 32.133-1.982C106.191 141.4 110 132 110 132c-20.682 11.941-40.324 5.369-50-6.677ZM101.466 72h-28.28c-13.5 24.868 1.121 46.6 12.911 53.4 13.857 8 23.9 6.6 23.9 6.6-28.797-16.629-25.491-49.449-8.531-60Zm2.3 36c0 16 6.238 24 6.238 24 0-34.753 32.852-48 50-36V72h-28.49c-19.561 5.956-27.752 24.511-27.752 36h.004Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_35(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny From Base',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M62.292 162 110 197a50.017 50.017 0 0 1-47.708-35Zm29.736-90L110 197l17.972-125H92.028ZM60 132l50 65L60 72v60Zm97.707 30L110 197a50.018 50.018 0 0 0 47.707-35ZM160 72l-50 125 50-65V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_36(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny From Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 72 42.332 101.6A49.751 49.751 0 0 0 160 147v-15l-50-60 50 32.132V87l-50-15-50 15v17.132L110 72l-50 60v15.019a49.754 49.754 0 0 0 7.668 26.581L110 72 92.482 193.837a50.093 50.093 0 0 0 35.035 0L110 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_37(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny Wavy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132c-.576-2.671-1.152-5.341.827-7.716 3.958-4.749 10.922.34 14.88-4.409s-2.3-10.682 1.654-15.431c3.954-4.749 10.923.339 14.88-4.41 3.957-4.749-2.3-10.682 1.654-15.431 3.954-4.749 10.923.339 14.88-4.41A5.662 5.662 0 0 0 160 77.7v56.277a6.348 6.348 0 0 1-4.8 2.33c-6.182 0-6.732-8.608-12.913-8.608s-6.732 8.608-12.914 8.608c-6.182 0-6.731-8.608-12.914-8.608-3.093.001-4.776 2.149-6.459 4.301Zm-4.3-32.283c0-6.182 8.609-6.732 8.609-12.914 0-6.182-8.609-6.731-8.609-12.914a5.728 5.728 0 0 1 .314-1.889H60c3.068 0 5.765.192 7.84 2.682 3.957 4.749-2.3 10.683 1.653 15.432 3.953 4.749 10.923-.34 14.881 4.409s-2.3 10.683 1.653 15.432c3.953 4.749 10.923-.34 14.88 4.409 3.957 4.749-2.3 10.682 1.654 15.431 1.978 2.374 4.709 2.289 7.44 2.2-2.152-1.683-4.3-3.366-4.3-6.456 0-6.182 8.609-6.732 8.609-12.914 0-6.182-8.61-6.725-8.61-12.908Zm3.773 97.27c.177 0 .353.013.531.013a49.937 49.937 0 0 0 41.32-21.846 5.858 5.858 0 0 0-.812-1.268c-3.957-4.749-10.923.34-14.88-4.409-3.957-4.749 2.3-10.683-1.654-15.432-3.954-4.749-10.922.34-14.88-4.409s2.3-10.682-1.654-15.432c-1.979-2.374-4.709-2.289-7.44-2.2-1.683 2.152-3.366 4.3-6.456 4.3-6.182 0-6.731-8.608-12.913-8.608S83.9 136.3 77.717 136.3c-6.183 0-6.732-8.6-12.917-8.6a6.369 6.369 0 0 0-4.8 2.332V147a49.81 49.81 0 0 0 13.529 34.184 5.69 5.69 0 0 0 2.578-1.787c3.957-4.749-2.3-10.682 1.653-15.432s10.923.34 14.881-4.409-2.3-10.682 1.653-15.431c3.953-4.749 10.923.34 14.88-4.409 1.978-2.375 1.4-5.045.826-7.716 2.152 1.683 4.305 3.366 4.305 6.456 0 6.182-8.609 6.731-8.609 12.913s8.608 6.731 8.608 12.913-8.604 6.733-8.604 12.918 8.608 6.731 8.608 12.913c-.008 3.344-2.525 5.041-4.839 6.874h.004Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_38(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Chevron Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a50 50 0 0 1-50-50v-1.907l7.037 8.464 6.093-7.309L67 138.87l6.083-7.319 6.142 7.387 6.093-7.309-6.153-7.4 6.083-7.319 6.163 7.405 6.089-7.305-6.17-7.41 6.082-7.318 6.188 7.418 6.093-7.309-6.193-7.432 6.5-7.827 6.5 7.827-6.195 7.432 6.095 7.309 6.184-7.422 6.083 7.318-6.167 7.414 6.094 7.309 6.162-7.405 6.083 7.319-6.152 7.4 6.093 7.309 6.142-7.387L153 138.87l-6.13 7.378 6.093 7.309 7.037-8.463V147a49.999 49.999 0 0 1-50 50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_39(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.91 49.91 0 0 0 16.667-2.856V72H93.333v122.144A49.909 49.909 0 0 0 110 197Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_40(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M122.5 72h-25v123.425A50.102 50.102 0 0 0 110 197a50.102 50.102 0 0 0 12.5-1.575V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_41(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M87.5 72h.013a15 15 0 1 1-.013 30 15 15 0 1 1 0 30 15 15 0 1 1 0 30 14.986 14.986 0 0 1 15.012 14.678 14.992 14.992 0 0 1-14.388 15.29A49.781 49.781 0 0 0 110 197a49.777 49.777 0 0 0 21.875-5.032 14.993 14.993 0 0 1-14.388-15.291A14.993 14.993 0 0 1 132.5 162a15.001 15.001 0 1 1 0-30 15.001 15.001 0 1 1 0-30 15.002 15.002 0 0 1-15.007-14.993A15.003 15.003 0 0 1 132.487 72H87.5Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_42(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Lozengy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m85 87 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-25 7.5 25 7.5-23.532 6.619A49.774 49.774 0 0 0 110 197a49.774 49.774 0 0 0 23.532-5.881L110 184.5l25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5-25-7.5 25-7.5H85l25 7.5L85 87Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_43(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Nebuly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M97.5 77c4.613-4.455 12.5-1.3 12.5 5s-7.887 9.454-12.5 5a7.509 7.509 0 0 0-10.356 0 6.9 6.9 0 0 0 0 10A7.51 7.51 0 0 0 97.5 97a7.507 7.507 0 0 1 10.355 0 6.899 6.899 0 0 1 0 10 7.506 7.506 0 0 1-10.355 0 7.51 7.51 0 0 0-10.356 0 6.901 6.901 0 0 0 0 10 7.511 7.511 0 0 0 10.356 0c4.613-4.455 12.5-1.3 12.5 5s-7.887 9.454-12.5 5a7.51 7.51 0 0 0-10.356 0 6.901 6.901 0 0 0 0 10 7.511 7.511 0 0 0 10.356 0c4.613-4.455 12.5-1.3 12.5 5s-7.887 9.454-12.5 5a7.507 7.507 0 0 0-10.356 0 6.901 6.901 0 0 0 0 10 7.511 7.511 0 0 0 10.356 0c4.613-4.455 12.5-1.3 12.5 5s-7.887 9.454-12.5 5a7.51 7.51 0 0 0-10.356 0 6.901 6.901 0 0 0 0 10 7.511 7.511 0 0 0 10.356 0c4.613-4.454 12.5-1.3 12.5 5s-7.887 9.455-12.5 5a7.51 7.51 0 0 0-10.356 0 6.97 6.97 0 0 0-1.949 3.406A49.74 49.74 0 0 0 110 197c.7 0 1.4-.024 2.095-.053a6.912 6.912 0 0 1-1.555-2.278 6.909 6.909 0 0 1 1.604-7.669 7.507 7.507 0 0 1 10.356 0 7.51 7.51 0 0 0 10.355 0 6.901 6.901 0 0 0 0-10 7.51 7.51 0 0 0-10.355 0c-4.613 4.455-12.5 1.3-12.5-5s7.887-9.455 12.5-5a7.51 7.51 0 0 0 10.355 0 6.901 6.901 0 0 0 0-10 7.51 7.51 0 0 0-10.355 0 7.507 7.507 0 0 1-10.356 0 6.901 6.901 0 0 1 0-10 7.51 7.51 0 0 1 10.356 0 7.507 7.507 0 0 0 10.355 0 6.901 6.901 0 0 0 0-10 7.51 7.51 0 0 0-10.355 0c-4.613 4.454-12.5 1.3-12.5-5s7.887-9.455 12.5-5a7.51 7.51 0 0 0 10.355 0 6.901 6.901 0 0 0 0-10 7.506 7.506 0 0 0-10.355 0c-4.613 4.454-12.5 1.3-12.5-5s7.887-9.455 12.5-5a7.51 7.51 0 0 0 10.355 0 6.901 6.901 0 0 0 0-10 7.507 7.507 0 0 0-10.355 0c-4.613 4.454-12.5 1.3-12.5-5s7.887-9.455 12.5-5a7.509 7.509 0 0 0 10.355 0 6.899 6.899 0 0 0 0-10 7.508 7.508 0 0 0-10.355 0 7.507 7.507 0 0 1-10.356 0A6.924 6.924 0 0 1 110 72H85a6.93 6.93 0 0 0 2.144 5A7.51 7.51 0 0 0 97.5 77Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_44(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Offset',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M85 72h25v60.108H85V72Zm50 118.294v-58.186h-25V197a49.747 49.747 0 0 0 25-6.706Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_45(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M101.346 81.231v9.231h-7.692v9.23h7.692v9.231h-7.692v9.231h7.692v9.231h-7.692v9.23h7.692v9.231h-7.692v9.231h7.692v9.231h-7.692v9.23h7.692v9.231h-7.692V192h7.692v4.238c2.857.503 5.753.758 8.654.762a49.886 49.886 0 0 0 16.346-2.748V192h-7.692v-9.231h7.692v-9.23h-7.692v-9.231h7.692v-9.231h-7.692v-9.231h7.692v-9.231h-7.692v-9.23h7.692v-9.231h-7.692v-9.231h7.692v-9.231h-7.692v-9.23h7.692v-9.231h-7.692V72h-25v9.231h7.692Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_46(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Raguly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M100 72v2l-5 6v10l5-6v10l-5 6v10l5-6v10l-5 6v10l5-6v10l-5 6v10l5-6v10l-5 6v10l5-6v10l-5 6v10l5-6v12a50.207 50.207 0 0 0 10 1 50.207 50.207 0 0 0 10-1v-12l5 6v-10l-5-6v-10l5 6v-10l-5-6v-10l5 6v-10l-5-6v-10l5 6v-10l-5-6v-10l5 6v-10l-5-6V84l5 6V80l-5-6v-2h-20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_47(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Wavy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M127.5 72h-25c0 7.181-10 7.82-10 15s10 7.819 10 15-10 7.82-10 15 10 7.819 10 15-10 7.82-10 15 10 7.82 10 15-10 7.819-10 15 10 7.819 10 15a6.716 6.716 0 0 1-1.431 4.187 49.91 49.91 0 0 0 26.152-2.233A6.768 6.768 0 0 0 127.5 192c0-7.18-10-7.818-10-15s10-7.82 10-15-10-7.818-10-15 10-7.82 10-15-10-7.819-10-15 10-7.819 10-15-10-7.819-10-15 10-7.819 10-15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_48(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Wavy II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M102.5 72a7.499 7.499 0 0 1 5.303 12.803A7.499 7.499 0 0 1 102.5 87h-10a7.5 7.5 0 0 0 0 15h10a7.497 7.497 0 0 1 7.5 7.5 7.497 7.497 0 0 1-7.5 7.5h-10a7.498 7.498 0 0 0-5.303 12.803A7.498 7.498 0 0 0 92.5 132h10a7.497 7.497 0 0 1 7.5 7.5 7.497 7.497 0 0 1-7.5 7.5h-10a7.498 7.498 0 0 0-5.303 12.803A7.498 7.498 0 0 0 92.5 162h10a7.497 7.497 0 0 1 7.5 7.5 7.497 7.497 0 0 1-7.5 7.5h-10a7.498 7.498 0 0 0-5.303 12.803A7.498 7.498 0 0 0 92.5 192h10a7.497 7.497 0 0 1 7.06 4.989c.147 0 .293.011.44.011a49.801 49.801 0 0 0 20.471-4.385A7.461 7.461 0 0 0 127.5 192h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.497 7.497 0 0 1-7.5-7.5 7.497 7.497 0 0 1 7.5-7.5h10a7.497 7.497 0 0 0 7.5-7.5 7.497 7.497 0 0 0-7.5-7.5h-10a7.498 7.498 0 0 1-7.5-7.5 7.498 7.498 0 0 1 7.5-7.5h10a7.499 7.499 0 0 0 5.303-12.803A7.499 7.499 0 0 0 127.5 72h-25Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_49(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Bevilled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m85 162.216 25-30.108V72H85v90.216Zm50 28.078V102l-25 30.108V197a49.747 49.747 0 0 0 25-6.706Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_50(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fess',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147c0 1.688.083 3.355.25 5h99.5c.164-1.645.247-3.312.25-5v-35H60v35Z" fill="#',
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