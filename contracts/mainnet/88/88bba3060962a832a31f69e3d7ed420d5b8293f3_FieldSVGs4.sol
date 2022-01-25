// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs4 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_67(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Razor Bordure',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60Zm97.5 17.8-3.3 11.3v11.3l3.3-11.3v11.3l-3.3 11.3V135l3.3-11.3V135l-3.3 11.3v1.3l-.1 1.2-.1 2.5-.4 2.5c-.1.8-.2 1.7-.4 2.5.5-.7.8-1.5 1.2-2.3l1.2-2.4c.6-1.7 1.3-3.4 1.9-5.2 0 1.9-.2 3.6-.2 5.4l-.4 2.7c-.2.9-.2 1.8-.5 2.6-1.8 3.2-4 6.1-6.5 8.7l-1.1 2.3-1.3 2.1c-.9 1.4-1.8 2.8-2.8 4.1 1.5-1 2.9-2 4.3-3.2l2.1-1.8 1.9-2-1.2 2.4-1.4 2.3c-.9 1.5-1.9 3-3.1 4.4-.4.3-.7.6-1.1.8l-1.2.7-2.4 1.4c-.8.4-1.7.8-2.5 1.1-.8.3-1.6.8-2.4 1l-2 1.5-1 .8-1.1.6-2.1 1.3c-.7.4-1.5.8-2.2 1.1.9-.1 1.8-.2 2.6-.4l2.6-.6 1.3-.3 1.3-.4 2.6-.9-2.2 1.6-1.1.8-1.1.7-2.3 1.4c-.8.5-1.6.8-2.4 1.2-.9.1-1.8.3-2.7.4l-2.8.1c-1.8.1-3.6 0-5.3-.2l-1.2.3-1.2.2-2.5.4c-1.7.2-3.3.2-5 .3 1.7.4 3.4 1 5.2 1.4l2.7.4 1.4.2c.5.1.9.1 1.4.1-.4.1-.9.2-1.3.3l-1.3.2-2.7.4c-1.8.2-3.6.2-5.4.3-1.8-.7-3.5-1.2-5.2-2l-2.4-1.2-1.2-.6c-.4-.2-.8-.5-1.1-.7-1.6-.4-3.2-.8-4.8-1.4l-2.3-.9c-.8-.3-1.5-.7-2.3-1.1.6.6 1.3 1.2 1.9 1.8l2.1 1.7c1.5 1.1 3 2.2 4.6 3.1-1.7-.4-3.5-.9-5.1-1.5l-2.5-.9-2.4-1.2c-.7-.6-1.4-1.3-2-1.9l-1.8-2.1-.9-1-.8-1.1-1.5-2.2c-.7-.5-1.2-1.1-1.9-1.6-.6-.6-1.3-1.1-1.8-1.7l-1.7-1.9-.8-.9c-.3-.3-.5-.7-.8-1 .1.4.3.9.4 1.3l.5 1.2 1.1 2.5c.4.8.9 1.6 1.3 2.4.5.8.9 1.6 1.5 2.4-.7-.5-1.3-1.2-2-1.8-.7-.6-1.3-1.2-2-1.8l-1.8-2-.9-1c-.3-.3-.5-.7-.8-1.1-.7-1.7-1.2-3.5-1.6-5.3l-.6-2.6-.3-2.6c-1.4-3-2.5-6.2-3.2-9.4-.4 3.6-.3 7.2.2 10.8-1.5-3.2-2.7-6.6-3.5-10.1 0-.9.3-1.9.4-2.8.1-.9.3-1.8.4-2.7l.7-2.6.3-1.3.4-1.3v-11.3l-3.3 11.3v-11.3l3.3-11.3v-11.3l-3.3 11.3v-11.3l3.3-11.3V89.8l-3.3 11.3V89.8l3.3-11.1-3.3-4.2h3l10.4 3.3h11.5L76 74.5h11.3l11.3 3.3H110l-11.3-3.3H110l11.3 3.3h11.3l-11.3-3.3h11.3l11.3 3.3h10.2l-10.2-3.3h11.6l-1.4 3.3v12l3.3-11.3v11.3h.1Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_68(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Canton',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h50v60H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_69(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Canton Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72h50v60h-50V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_70(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_71(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 72v42.489a12.499 12.499 0 0 0-21.343-8.829A12.501 12.501 0 0 0 135 114.5a12.501 12.501 0 0 0-25 0 12.501 12.501 0 0 0-25 0 12.5 12.5 0 0 0-25 0V72" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_72(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Indented',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 91.765 72.5 122 85 91.764 97.5 122 110 91.765 122.5 122 135 91.764 147.5 122 160 91.766V72H60v19.765Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_73(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Nebuly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 71.988v41.923a7.855 7.855 0 0 0 12.815-8.562 7.863 7.863 0 0 0-1.703-2.549 7.855 7.855 0 0 1 1.19-12.088 7.857 7.857 0 0 1 9.921 12.088 7.858 7.858 0 0 0 5.555 13.413 7.86 7.86 0 0 0 7.26-4.85 7.86 7.86 0 0 0-1.704-8.563 7.855 7.855 0 0 1 1.19-12.088 7.857 7.857 0 0 1 9.921 12.088 7.855 7.855 0 0 0-1.703 8.563 7.848 7.848 0 0 0 7.259 4.85 7.859 7.859 0 0 0 7.258-4.85 7.855 7.855 0 0 0-1.703-8.563 7.852 7.852 0 0 1-1.703-8.562 7.852 7.852 0 0 1 7.259-4.85 7.856 7.856 0 0 1 5.555 13.412 7.855 7.855 0 0 0-1.703 8.563 7.848 7.848 0 0 0 7.259 4.85 7.861 7.861 0 0 0 7.258-4.85 7.855 7.855 0 0 0-1.703-8.563 7.852 7.852 0 0 1-1.703-8.562 7.852 7.852 0 0 1 7.258-4.85 7.86 7.86 0 0 1 7.259 4.85 7.852 7.852 0 0 1-1.703 8.562A7.856 7.856 0 1 0 160 113.911v-41.91l-100-.013Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_74(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60.001 71.983V102H60v9.231h7.693V102h7.692v9.231h7.692V102h7.693v9.231h7.692V102h7.692v9.231h7.693V102h7.692v9.231h7.693V102h7.692v9.231h7.692V102h7.693v9.231H160v-39.23l-99.999-.018Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_75(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v40c7.979 0 8.689-10 16.667-10 7.978 0 8.688 10 16.667 10 7.979 0 8.688-10 16.667-10 7.979 0 8.687 10 16.666 10 7.979 0 8.688-10 16.667-10 7.979 0 8.688 10 16.666 10V72H60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_76(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Rayonny',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 101.414V72h100v29.426c-2.707-4.549-5.066-9.126-2.3-14.424-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.011-18.954-6.248-30-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.011-18.954-6.248-30-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.012-18.954-6.248-30-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.012-18.954-6.248-30-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.012-18.954-6.248-30-9.66 8.435 2.426 21.561-6.252 30 4.478-11.042-12.012-18.954-6.248-30-9.66 8.435 2.426 21.561-6.253 30 4.479-11.042-12.011-18.954-6.247-30-9.66 8.435 2.426 21.561-6.253 30 2.332-5.752-1.013-10.652-3.947-15.588Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_77(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Triangular',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 72H60l50 30.001L160 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_78(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chief Urdy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v38.49l5.555 6.657 5.556-6.667V95.202l5.555-6.667 5.556 6.667v15.278l5.556 6.667 5.555-6.667V95.202l5.556-6.667 5.555 6.667v15.278l5.556 6.667 5.555-6.667V95.202l5.556-6.667 5.555 6.667v15.278l5.556 6.667 5.556-6.667V95.202l5.555-6.667 5.556 6.667v15.278l5.555 6.667L160 110.48V72H60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_79(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M157.707 162H62.292a50.013 50.013 0 0 0 95.415 0Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_80(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M159.751 151.982a12.497 12.497 0 0 1-21.52 5.904A12.501 12.501 0 0 1 135 149.5a12.501 12.501 0 0 1-25 0 12.501 12.501 0 0 1-25 0 12.497 12.497 0 0 1-11.26 12.435 12.502 12.502 0 0 1-13.493-9.966 49.999 49.999 0 0 0 99.5.013h.004Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_81(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Indented',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M147.5 142 135 172.236 122.5 142 110 172.235 97.5 142 85 172.236 72.5 142l-9.324 22.553a50.011 50.011 0 0 0 75.308 23.543 50.012 50.012 0 0 0 18.34-23.543L147.5 142Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_82(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Nebuly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M148.889 150.077a7.862 7.862 0 0 0-2.302 5.556 7.847 7.847 0 0 0 2.302 5.555 7.864 7.864 0 0 1 2.151 4.023 7.856 7.856 0 1 1-13.262-4.023 7.856 7.856 0 1 0-11.111 0 7.855 7.855 0 0 1-1.191 12.089 7.859 7.859 0 0 1-11.624-3.526 7.866 7.866 0 0 1 1.703-8.563 7.856 7.856 0 1 0-11.111 0 7.864 7.864 0 0 1 2.151 4.023 7.856 7.856 0 1 1-13.262-4.023 7.85 7.85 0 0 0 1.704-8.562 7.853 7.853 0 0 0-7.26-4.851 7.853 7.853 0 0 0-7.258 4.851 7.856 7.856 0 0 0 1.703 8.562 7.858 7.858 0 0 1-5.555 13.413 7.852 7.852 0 0 1-7.26-4.85 7.86 7.86 0 0 1 1.704-8.563 7.852 7.852 0 0 0-.02-10.992 7.853 7.853 0 0 0-10.99-.206 49.99 49.99 0 0 0 49.903 47.003 49.994 49.994 0 0 0 49.903-47.003 7.855 7.855 0 0 0-11.018.087Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_83(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M152.308 152.769V162h-7.693v-9.231h-7.692V162h-7.692v-9.231h-7.693V162h-7.692v-9.231h-7.693V162h-7.692v-9.231H90.77V162h-7.693v-9.231h-7.692V162h-7.692v-9.231h-7.35a49.99 49.99 0 0 0 99.316 0h-7.35Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_84(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Wavy',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M143.334 162c-7.979 0-8.688-10-16.667-10-7.979 0-8.688 10-16.667 10-7.979 0-8.687-10-16.666-10-7.979 0-8.688 10-16.667 10-7.893 0-8.677-9.78-16.417-9.99a50 50 0 0 0 99.5 0c-7.74.211-8.524 9.99-16.416 9.99Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_85(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Base Rayonny',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M157.411 162.875c-2.975-5.033-6.5-10.012-4.128-15.874-8.679 8.435 3.408 21.561-6.252 30 5.763-11.043-10.726-18.954-6.248-30-8.679 8.435 3.408 21.561-6.252 30 5.764-11.043-10.726-18.954-6.247-30-8.679 8.435 3.407 21.561-6.253 30 5.764-11.043-10.726-18.954-6.248-30-8.678 8.435 3.408 21.561-6.252 30 5.764-11.043-10.726-18.954-6.248-30-8.679 8.435 3.408 21.561-6.252 30 5.764-11.043-10.726-18.954-6.248-30-8.679 8.435 3.408 21.561-6.252 30 5.764-11.043-10.726-18.954-6.248-30-8.679 8.435 3.408 21.561-6.252 30 5.763-11.043-10.726-18.954-6.248-30-5.175 5.03-2.968 11.728-2.389 18.1a49.997 49.997 0 0 0 47.791 31.877 50.002 50.002 0 0 0 46.226-34.107v.004Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_86(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M117.5 139H160v-14h-42.5V72h-15v53H60v14h42.5v57.438a50.348 50.348 0 0 0 15 0V139Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_87(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 117h-35V72H95v45H60v30h35v47.708A49.973 49.973 0 0 0 110 197a49.942 49.942 0 0 0 15-2.293V147h35v-30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_88(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M103.4 134.45c.71.71 1.28 1.55 1.69 2.47-4.23-1.87-9.17.04-11.04 4.26a8.47 8.47 0 0 0-.72 3.32c-.52-10.93-16.16-10.92-16.67 0-.51-10.93-16.16-10.92-16.67 0v-25c.28 11.15 16.38 11.15 16.67.01.29 11.15 16.39 11.14 16.67 0-.15 5.95 6.55 10.21 11.87 7.54a8.312 8.312 0 0 1-3.11 3.63 8.384 8.384 0 0 1-4.59 1.33c2.21-.01 4.34.87 5.9 2.44zm6.6-14.94v-.01a8.329 8.329 0 0 0 4.97 7.52 8.378 8.378 0 0 1 3.61-10.63c1.2-.67 2.55-1.03 3.92-1.06-11.04-.42-11.03-16.25 0-16.67-10.93-.52-10.92-16.16 0-16.67-6.79-.05-8.83-6.63-8.17-10h-8.67c.97 4.94-2.69 9.96-8.16 10 11.15.28 11.14 16.39 0 16.67 11.04.42 11.03 16.25 0 16.67 5.86-.25 10.27 6.43 7.7 11.71a8.333 8.333 0 0 0 4.8-7.53zm.61 21.77a8.454 8.454 0 0 0-.61 3.22 8.34 8.34 0 0 0-4.9-7.59c1.87 4.23-.05 9.17-4.28 11.04-1.05.46-2.17.7-3.32.71 10.93.52 10.92 16.16 0 16.67 10.93.52 10.92 16.16 0 16.67 7.54-.07 11.24 9.52 5.58 14.51 4.59.65 9.25.65 13.85 0-5.66-4.99-1.95-14.57 5.58-14.51-11.15-.29-11.14-16.39 0-16.67-11.15-.29-11.14-16.39 0-16.67-4.38-.03-8-3.44-8.29-7.81-.09-1.4.17-2.79.75-4.06a8.299 8.299 0 0 0-4.36 4.49zM160 119.5c-.52 10.93-16.15 10.92-16.67 0-.41 11.04-16.25 11.03-16.67 0a8.355 8.355 0 0 1-3.84 6.88 8.39 8.39 0 0 1-7.85.65 8.336 8.336 0 0 0 7.53 4.97c-3.22 0-6.16 1.87-7.53 4.79 5.28-2.55 11.94 1.86 11.69 7.71.42-11.04 16.25-11.03 16.67 0 .29-11.15 16.39-11.14 16.67 0v-25z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_89(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m98.284 132-32.293 38.748a50.186 50.186 0 0 0 11.545 14.263L110 146.057l32.464 38.955a50.22 50.22 0 0 0 11.545-14.263L121.714 132 160 86.06V72h-11.716L110 117.941 71.714 72H60v14.06L98.284 132Z" fill="#',
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