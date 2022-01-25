// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs24 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_299(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tiles III',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi299-c" viewBox="-18.5 -15.1 37 30.3"><path d="m2.5 6 4 3.9-5.4-1.6 1.6 5.4-3.9-4-1.4 5.4-1.3-5.4-3.9 4 1.5-5.4-5.4 1.6 4-3.9-5.4-1.4 5.4-1.3-4-3.9L-6.3.9l-1.5-5.4 3.9 4.1 1.3-5.5 1.4 5.5 3.9-4.1L1.1.9 6.5-.6l-4 3.9 5.4 1.3z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="7.9" overflow="visible" transform="translate(-2.58 -9.8)" width="7.9" x="-3.9" xlink:href="#fi299-a" y="-3.9"/><use height="7.9" overflow="visible" transform="rotate(60 7.2 7.3)" width="7.9" x="-3.9" xlink:href="#fi299-a" y="-3.9"/><use height="7.9" overflow="visible" transform="rotate(-60 -9.77 11.77)" width="7.9" x="-3.9" xlink:href="#fi299-a" y="-3.9"/><use height="10.7" overflow="visible" transform="translate(13.2 4.64)" width="10.6" x="-5.3" xlink:href="#fi299-b" y="-5.3"/><use height="10.7" overflow="visible" transform="rotate(-60 -5.17 -9.12)" width="10.6" x="-5.3" xlink:href="#fi299-b" y="-5.3"/></symbol><symbol id="fi299-a" viewBox="-3.9 -3.9 7.9 7.9"><path d="M.8.8 0 3.9-.8.8-3.9 0l3.1-.8.8-3.1.8 3.1 3.1.8z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi299-b" viewBox="-5.3 -5.3 10.6 10.7"><path d="m2 .7 2 4.6-3.1-4-2.2 2.5 1-3.1-5-.7 5-.7-1-3.1L.9-1.3l3.1-4L2-.7l3.3.7z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi299-f" viewBox="-18.5 -87 37 174.6"><use height="30.3" overflow="visible" transform="translate(0 72.5)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/><use height="30.3" overflow="visible" transform="translate(0 43.63)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/><use height="30.3" overflow="visible" transform="translate(0 14.77)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/><use height="30.3" overflow="visible" transform="translate(0 -14.1)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/><use height="30.3" overflow="visible" transform="translate(0 -42.97)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/><use height="30.3" overflow="visible" transform="translate(0 -71.84)" width="37" x="-18.5" xlink:href="#fi299-c" y="-15.1"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi299-d"/></defs><clipPath id="fi299-e"><use overflow="visible" xlink:href="#fi299-d"/></clipPath><g clip-path="url(#fi299-e)"><use height="174.6" overflow="visible" transform="matrix(1 0 0 -1.0379 62.58 121.86)" width="37" x="-18.5" xlink:href="#fi299-f" y="-87"/><use height="174.6" overflow="visible" transform="matrix(1 0 0 -1.0379 87.58 136.84)" width="37" x="-18.5" xlink:href="#fi299-f" y="-87"/></g><g clip-path="url(#fi299-e)"><use height="174.6" overflow="visible" transform="matrix(1 0 0 -1.0379 112.58 121.86)" width="37" x="-18.5" xlink:href="#fi299-f" y="-87"/><use height="174.6" overflow="visible" transform="matrix(1 0 0 -1.0379 137.58 136.84)" width="37" x="-18.5" xlink:href="#fi299-f" y="-87"/></g><g clip-path="url(#fi299-e)"><use height="174.6" overflow="visible" transform="matrix(1 0 0 -1.0379 162.58 121.86)" width="37" x="-18.5" xlink:href="#fi299-f" y="-87"/></g>'
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