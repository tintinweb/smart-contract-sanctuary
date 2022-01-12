/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.7;

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
/// @title MathBlocks, Primes
/********************************************
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM *
 * MMMMMMMMMMMMNmdddddddddddddddddmNMMMMMMM *
 * MMMMMMMMMmhyssooooooooooooooooosyhNMMMMM *
 * MMMMMMMmyso+/::::::::::::::::::/osyMMMMM *
 * MMMMMMhys+::/+++++++++++++++++/:+syNMMMM *
 * MMMMNyso/:/+/::::+/:::/+:::::::+oshMMMMM *
 * MMMMmys/-//:/++:/+://-++-+oooossydMMMMMM *
 * MMMMNyso+//+s+/:+/:+/:+/:+syddmNMMMMMMMM *
 * MMMMMNdyyyyso/:++:/+:/+/:+syNMMMMMMMMMMM *
 * MMMMMMMMMhso/:/+/:++:/++-+symMMMMMMMMMMM *
 * MMMMMMMMdys+:/++:/++:/++:/+syNMMMMMMMMMM *
 * MMMMMMMNys+:/++/:+s+:/+++:/oydMMMMMMMMMM *
 * MMMMMMMmys+:/+/:/oso/:///:/sydMMMMMMMMMM *
 * MMMMMMMMhso+///+osyso+///osyhMMMMMMMMMMM *
 * MMMMMMMMMmhyssyyhmMdhyssyydNMMMMMMMMMMMM *
 * MMMMMMMMMMMMMNMMMMMMMMMNMMMMMMMMMMMMMMMM *
 *******************************************/
struct CoreData {
    bool isPrime;
    uint16 primeIndex;
    uint8 primeFactorCount;
    uint16[2] parents;
    uint32 lastBred;
}

struct RentalData {
    bool isRentable;
    bool whitelistOnly;
    uint96 studFee;
    uint32 deadline;
    uint16[6] suitors;
}

struct PrimeData {
    uint16[2] sexyPrimes;
    uint16[2] twins;
    uint16[2] cousins;
}

struct NumberData {
    CoreData core;
    PrimeData prime;
}

struct Activity {
    uint8 tranche0;
    uint8 tranche1;
}

enum Attribute {
    TAXICAB_NUMBER,
    PERFECT_NUMBER,
    EULERS_LUCKY_NUMBER,
    UNIQUE_PRIME,
    FRIENDLY_NUMBER,
    COLOSSALLY_ABUNDANT_NUMBER,
    FIBONACCI_NUMBER,
    REPDIGIT_NUMBER,
    WEIRD_NUMBER,
    TRIANGULAR_NUMBER,
    SOPHIE_GERMAIN_PRIME,
    STRONG_PRIME,
    FRUGAL_NUMBER,
    SQUARE_NUMBER,
    EMIRP,
    MAGIC_NUMBER,
    LUCKY_NUMBER,
    GOOD_PRIME,
    HAPPY_NUMBER,
    UNTOUCHABLE_NUMBER,
    SEMIPERFECT_NUMBER,
    HARSHAD_NUMBER,
    EVIL_NUMBER
}

/// @title MathBlocks, Primes
/********************************************
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM *
 * MMMMMMMMMMMMNmdddddddddddddddddmNMMMMMMM *
 * MMMMMMMMMmhyssooooooooooooooooosyhNMMMMM *
 * MMMMMMMmyso+/::::::::::::::::::/osyMMMMM *
 * MMMMMMhys+::/+++++++++++++++++/:+syNMMMM *
 * MMMMNyso/:/+/::::+/:::/+:::::::+oshMMMMM *
 * MMMMmys/-//:/++:/+://-++-+oooossydMMMMMM *
 * MMMMNyso+//+s+/:+/:+/:+/:+syddmNMMMMMMMM *
 * MMMMMNdyyyyso/:++:/+:/+/:+syNMMMMMMMMMMM *
 * MMMMMMMMMhso/:/+/:++:/++-+symMMMMMMMMMMM *
 * MMMMMMMMdys+:/++:/++:/++:/+syNMMMMMMMMMM *
 * MMMMMMMNys+:/++/:+s+:/+++:/oydMMMMMMMMMM *
 * MMMMMMMmys+:/+/:/oso/:///:/sydMMMMMMMMMM *
 * MMMMMMMMhso+///+osyso+///osyhMMMMMMMMMMM *
 * MMMMMMMMMmhyssyyhmMdhyssyydNMMMMMMMMMMMM *
 * MMMMMMMMMMMMMNMMMMMMMMMNMMMMMMMMMMMMMMMM *
 *******************************************/
library PrimesTokenURI {
    string internal constant DESCRIPTION = "Primes is MathBlocks Collection #1.";
    string internal constant STYLE =
        "<style>.p #bg{fill:#ddd} .c #bg{fill:#222} .p .factor,.p #text{fill:#222} .c .factor,.c #text{fill:#ddd} .sexy{fill:#e44C21} .cousin{fill:#348C47} .twin {fill:#3C4CE1} #grid .factor{r: 8} .c #icons *{fill: #ddd} .p #icons * {fill:#222} #icons .stroke *{fill:none} #icons .stroke {fill:none;stroke:#222;stroke-width:8} .c #icons .stroke{stroke:#ddd} .square{stroke-width:2;fill:none;stroke:#222;r:8} .c .square{stroke:#ddd} #icons #i-4 circle{stroke-width:20}</style>";

    function tokenURI(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) public pure returns (string memory output) {
        string[24] memory parts;

        // 23 attributes revealed with merkle proof
        for (uint8 i = 0; i < 23; i++) {
            parts[i] = _attributeValues[i]
                ? string(abi.encodePacked('{ "value": "', _attributeNames(i), '" }'))
                : "";
        }

        // Last attribute: Unit/Prime/Composite
        parts[23] = string(
            abi.encodePacked(
                '{ "value": "',
                _tokenId == 1 ? "Unit" : _numberData.core.isPrime ? "Prime" : "Composite",
                '" }'
            )
        );

        string memory json = string(
            abi.encodePacked(
                '{ "name": "Primes #',
                _toString(_tokenId),
                '", "description": "',
                DESCRIPTION,
                '", "attributes": [',
                _getAttributes(parts),
                '], "image": "',
                _getImage(_tokenId, _numberData, _factors, _attributeValues),
                '" }'
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json)))
        );
    }

    function _getImage(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        // 350x350 canvas
        // padding: 14
        // 14x14 grid (bottom row for icons etc)
        // grid square: 23
        // inner square: 16 (circle r=8)
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">',
                _svgContent(_tokenId, _numberData, _factors, _attributeValues),
                "</svg>"
            )
        );

        output = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function _svgContent(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                STYLE,
                '<g class="',
                _numberData.core.isPrime && _tokenId != 1 ? "p" : "c",
                '"><rect id="bg" width="100%" height="100%" />',
                _circles(_tokenId, _numberData, _factors),
                _text(_tokenId),
                _icons(_tokenId, _numberData.core.isPrime, _attributeValues),
                "</g>"
            )
        );
    }

    function _text(uint256 _tokenId) internal pure returns (string memory output) {
        uint256[] memory digits = _getDigits(_tokenId);

        // 16384 has an extra row; move the text to the top right to avoid an overlap
        uint256 dx = _tokenId == 16384 ? 277 : 18;
        uint256 dy = _tokenId == 16384 ? 18 : 318;

        output = string(
            abi.encodePacked(
                '<g id="text" transform="translate(',
                _toString(dx),
                ",",
                _toString(dy),
                ')">',
                _getNumeralPath(digits, 0),
                _getNumeralPath(digits, 1),
                _getNumeralPath(digits, 2),
                _getNumeralPath(digits, 3),
                _getNumeralPath(digits, 4),
                "</g>"
            )
        );
    }

    function _getNumeralPath(uint256[] memory _digits, uint256 _index)
        internal
        pure
        returns (string memory output)
    {
        if (_digits.length <= _index) {
            return output;
        }
        output = string(
            abi.encodePacked(
                '<g transform="translate(',
                _toString(_index * 12),
                ',0)"><path d="',
                _getNumeralPathD(_digits[_index]),
                '" /></g>'
            )
        );
    }

    // Space Mono numerals
    function _getNumeralPathD(uint256 _digit) internal pure returns (string memory) {
        if (_digit == 0) {
            return
                "M0 5.5a6 6 0 0 1 1.3-4C2 .4 3.3 0 4.7 0c1.5 0 2.7.5 3.5 1.4a6 6 0 0 1 1.3 4.1v3c0 1.8-.5 3.2-1.3 4.1-.8 1-2 1.4-3.5 1.4s-2.6-.5-3.5-1.4C.4 11.6 0 10.3 0 8.5v-3Zm4.7 7c1 0 1.8-.3 2.4-1 .5-.8.7-1.8.7-3.1V5.6L7.7 4 7 2.6l-1-.8c-.4-.2-.9-.3-1.4-.3-.5 0-1 0-1.3.3l-1 .8c-.3.4-.5.8-.6 1.3l-.2 1.7v2.8c0 1.3.3 2.3.8 3 .5.8 1.3 1.1 2.3 1.1ZM3.5 7c0-.3.1-.6.4-.9.2-.2.5-.3.8-.3.4 0 .7 0 .9.3.2.3.4.6.4.9 0 .3-.2.6-.4.9-.2.2-.5.3-.9.3-.3 0-.6 0-.8-.3-.3-.3-.4-.6-.4-.9Z";
        } else if (_digit == 1) {
            return "M4 12.2V1h-.2L1.6 6H0L2.5.2h3.2v12h3.8v1.4H.2v-1.5H4Z";
        } else if (_digit == 2) {
            return
                "M9.2 12.2v1.5h-9v-2.3c0-.6 0-1.1.2-1.6.2-.4.5-.8.9-1.1.4-.4.8-.7 1.4-.9l1.8-.5c1.1-.3 2-.7 2.5-1.1.5-.5.7-1 .7-1.8l-.1-1.1-.6-1c-.2-.2-.5-.4-1-.5-.3-.2-.7-.3-1.3-.3a3 3 0 0 0-2.3.9c-.5.6-.8 1.4-.8 2.4v.9H0v-1l.3-1.8c.2-.5.5-1 1-1.5.3-.4.8-.8 1.4-1a5 5 0 0 1 2-.4c.8 0 1.5.1 2 .4.6.2 1.1.5 1.5 1 .4.3.7.7.9 1.2.2.5.2 1 .2 1.5v.4c0 1-.3 1.9-1 2.6-.6.7-1.6 1.2-3 1.6-1.2.2-2.1.6-2.7 1-.6.5-.9 1.1-.9 2v.5h7.5Z";
        } else if (_digit == 3) {
            return
                "M3.3 7V4.8L7.7 2v-.2H.1V.3h9v2.4L4.7 5.5v.3h.8a3.7 3.7 0 0 1 4 3.8v.3a3.8 3.8 0 0 1-1.3 3A4.8 4.8 0 0 1 4.9 14c-.8 0-1.5-.1-2-.3a4.4 4.4 0 0 1-2.5-2.4C0 10.7 0 10.2 0 9.5v-1h1.6v1c0 .4 0 .8.2 1.2l.7 1 1 .6a3.8 3.8 0 0 0 2.5 0 3 3 0 0 0 1-.6c.3-.2.5-.5.6-.9.2-.3.2-.7.2-1v-.2c0-.8-.2-1.4-.7-1.9-.5-.4-1.2-.7-2-.7H3.4Z";
        } else if (_digit == 4) {
            return "M4.7.3h3.1v9.4H10v1.5H8v2.5H6.1v-2.5H0V9L4.7.3ZM1.4 9.5v.2h4.8V1H6L1.4 9.5Z";
        } else if (_digit == 5) {
            return
                "M.2 7.4V.3h8.5v1.5H1.8v4.8H2l.5-.8a3.4 3.4 0 0 1 1.7-1l1.1-.2c.7 0 1.2.1 1.7.3a3.9 3.9 0 0 1 2.3 2.2c.2.6.3 1.1.3 1.8v.3c0 .7-.1 1.3-.3 1.9-.2.5-.5 1-1 1.5-.3.4-.8.8-1.4 1a5 5 0 0 1-2 .4c-.8 0-1.5-.1-2.1-.3-.6-.3-1.1-.6-1.5-1-.5-.4-.8-.9-1-1.4C.1 10.7 0 10 0 9.3V9h1.6v.4c0 1 .3 1.9.9 2.4.6.5 1.4.8 2.3.8.6 0 1 0 1.4-.3l1-.7.6-1.1L8 9V9a3 3 0 0 0-.8-2c-.2-.3-.5-.5-.9-.7a2.6 2.6 0 0 0-1.8 0 2 2 0 0 0-.6.2l-.4.4-.2.5h-3Z";
        } else if (_digit == 6) {
            return
                "M7.5 4.2c0-.8-.3-1.5-.8-2s-1.2-.8-2.1-.8l-1.2.3c-.4.1-.7.3-1 .6a3.2 3.2 0 0 0-.8 2.4v2h.2c.4-.6.8-1 1.4-1.4.5-.3 1.2-.5 1.9-.5.6 0 1.2.1 1.7.4.5.1 1 .4 1.3.8l1 1.4.2 1.9v.2A4.5 4.5 0 0 1 8 12.8c-.4.3-.9.7-1.5.9a5.2 5.2 0 0 1-3.7 0c-.6-.2-1-.5-1.5-1-.4-.3-.7-.8-1-1.3L0 9.6v-5c0-.7.1-1.3.4-1.9.2-.5.5-1 1-1.4.4-.4.9-.8 1.4-1a5.4 5.4 0 0 1 3.6 0 4 4 0 0 1 2.7 3.9H7.5Zm-2.8 8.4c.4 0 .9 0 1.2-.2l1-.7c.3-.2.5-.6.6-1 .2-.3.2-.7.2-1.2v-.2c0-.4 0-.9-.2-1.2a2.7 2.7 0 0 0-1.6-1.6c-.4-.2-.8-.2-1.2-.2a3.1 3.1 0 0 0-2.2.8 3 3 0 0 0-.9 2.1v.4c0 .4 0 .8.2 1.2a2.7 2.7 0 0 0 1.6 1.6l1.3.2Z";
        } else if (_digit == 7) {
            return
                "M0 .3h9v2.3l-5.7 8.6-.6 1a2 2 0 0 0-.2 1v.5H.9V12.4a3.9 3.9 0 0 1 .7-1.3l.5-.8L7.6 2v-.2H0V.3Z";
        } else if (_digit == 8) {
            return
                "M4.5 14a6 6 0 0 1-1.8-.3L1.2 13l-.9-1.2c-.2-.4-.3-1-.3-1.5v-.2A3.3 3.3 0 0 1 .8 8a3.3 3.3 0 0 1 1.7-1v-.3a3 3 0 0 1-.8-.4c-.3-.1-.5-.4-.7-.6a3 3 0 0 1-.6-1.9v-.2A3.2 3.2 0 0 1 1.4 1a5.4 5.4 0 0 1 3.1-1h.1C5.4 0 6 0 6.5.3c.5.1 1 .4 1.3.7A3.1 3.1 0 0 1 9 3.5v.2c0 .4 0 .7-.2 1 0 .4-.2.7-.5.9a3 3 0 0 1-.6.6 3 3 0 0 1-.9.4V7a3.7 3.7 0 0 1 1.8 1 3.3 3.3 0 0 1 .7 2.2v.2A3.3 3.3 0 0 1 8.1 13l-1.4.7a6 6 0 0 1-1.9.3h-.3Zm.3-1.5c.9 0 1.6-.2 2.1-.6.6-.5.8-1 .8-1.8V10c0-.8-.3-1.4-.8-1.8-.6-.5-1.3-.7-2.2-.7-1 0-1.7.2-2.3.7-.5.4-.8 1-.8 1.8v.1c0 .7.3 1.3.8 1.8.6.4 1.3.6 2.2.6h.2ZM4.7 6a3 3 0 0 0 2-.6c.4-.5.7-1 .7-1.6v-.1A2 2 0 0 0 6.6 2a3 3 0 0 0-2-.6 3 3 0 0 0-2 .6A2 2 0 0 0 2 3.7c0 .7.2 1.2.7 1.7a3 3 0 0 0 2 .6Z";
        } else {
            return
                "M1.8 9.8c0 .8.3 1.5.8 2a3 3 0 0 0 2.1.8c.5 0 .9-.1 1.2-.3.4-.1.7-.3 1-.6.3-.3.5-.6.6-1 .2-.4.2-.9.2-1.4v-2h-.2c-.3.6-.7 1-1.3 1.4-.5.3-1.2.5-1.9.5a5 5 0 0 1-1.7-.3A3.8 3.8 0 0 1 .3 6.6C.1 6.1 0 5.5 0 4.8v-.2c0-.7.1-1.3.3-1.9A4.2 4.2 0 0 1 2.8.3 5 5 0 0 1 4.7 0 4.9 4.9 0 0 1 8 1.3c.4.4.8.8 1 1.4.2.5.3 1.1.3 1.8v4.8a5 5 0 0 1-.3 2 4.3 4.3 0 0 1-2.5 2.4 5.5 5.5 0 0 1-3.6 0L1.5 13l-1-1.3-.3-1.8h1.6Zm2.9-8.4c-.5 0-1 .1-1.3.3a2.8 2.8 0 0 0-1.6 1.6l-.2 1.2v.3c0 .4 0 .8.2 1.2l.7 1 1 .5c.3.2.7.2 1.2.2.4 0 .8 0 1.2-.2a3 3 0 0 0 1-.6l.6-1c.2-.3.2-.7.2-1v-.4c0-.5 0-.9-.2-1.2-.1-.4-.3-.7-.6-1-.3-.3-.6-.5-1-.6-.3-.2-.8-.3-1.2-.3Z";
        }
    }

    function _getIconGeometry(uint256 _attribute) internal pure returns (string memory) {
        if (_attribute == 0) {
            // Taxicab Number
            return
                '<rect y="45" width="15" height="15" rx="2"/><rect x="15" y="30" width="15" height="15" rx="2"/><rect x="30" y="15" width="15" height="15" rx="2"/><path d="M45 2c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H47a2 2 0 0 1-2-2V2Z"/><path d="M45 32c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H47a2 2 0 0 1-2-2V32Z"/><path d="M30 47c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H32a2 2 0 0 1-2-2V47Z"/><path d="M0 17c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V17Z"/><path d="M15 2c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H17a2 2 0 0 1-2-2V2Z"/>';
        } else if (_attribute == 1) {
            // Perfect Number
            return
                '<g class="stroke"><path d="m12 12 37 37"/><path d="m12 49 37-37"/><path d="M5.4 30H56"/><path d="M30.7 55.3V4.7"/></g>';
        } else if (_attribute == 2) {
            // Euler's Lucky Numbers
            return
                '<path d="M30.8 7.3c-10 0-15.4 5.9-16.4 17.8 0 .6.3.8 1 .8h29c.6 0 1-.2 1-.8C44.8 13.2 40 7.3 30.7 7.3Zm2.3 52c-8.8 0-15.6-2.4-20.2-7.2C8.3 47 6 39.9 6 30c0-10 2.2-17.3 6.6-22A23.8 23.8 0 0 1 30.8 1C45 1 52.5 9.4 53.4 26.2c0 1.7-.5 3.2-1.8 4.4a6.2 6.2 0 0 1-4.5 1.7h-32c-.5 0-.8.3-.8 1C15 46.5 21.5 53 34 53c4 0 8.3-.8 12.6-2.3.8-.3 1.5-.2 2.3.3.7.4 1 1 1 2 0 2.4-1 4-3.3 4.5-4.6 1.1-9 1.7-13.4 1.7Z"/>';
        } else if (_attribute == 3) {
            // Unique Prime
            return '<circle class="stroke" cx="30" cy="30" r="20"/>';
        } else if (_attribute == 4) {
            // Friendly Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M30 60a30 30 0 1 0 0-60 30 30 0 0 0 0 60ZM17.5 31c3.6 0 6.5-4.3 6.5-9.5S21 12 17.5 12c-3.6 0-6.5 4.3-6.5 9.5s3 9.5 6.5 9.5ZM49 21.5c0 5.2-3 9.5-6.5 9.5-3.6 0-6.5-4.3-6.5-9.5s3-9.5 6.5-9.5c3.6 0 6.5 4.3 6.5 9.5Zm-2.8 21.9a4 4 0 1 0-6.4-4.8c-5.1 7-15.2 7.3-20.6 0a4 4 0 0 0-6.4 4.8 20.5 20.5 0 0 0 33.4 0Z"/>';
        } else if (_attribute == 5) {
            // Colossally Abundant Number
            return
                '<path d="M34 4a4 4 0 0 0-8 0v22H4a4 4 0 0 0 0 8h22v22a4 4 0 0 0 8 0V34h22a4 4 0 0 0 0-8H34V4Z"/>';
        } else if (_attribute == 6) {
            // Fibonacci Number
            return
                '<path class="stroke" d="M31.3 23a.6.6 0 0 0 0-.4.6.6 0 0 0-.5-.2h-.3a.8.8 0 0 0-.5.3l-.1.4v.3a1 1 0 0 0 .5.7 1.2 1.2 0 0 0 .9.2l.5-.2.4-.5.2-.5a1.7 1.7 0 0 0-.3-1.3 2 2 0 0 0-1.3-.8h-.9l-.8.4c-.3.1-.5.4-.7.7-.2.3-.3.6-.3 1a3 3 0 0 0 .5 2.2 3.3 3.3 0 0 0 2.2 1.4h1.5a4 4 0 0 0 1.4-.7c.5-.3.9-.7 1.2-1.2a5.1 5.1 0 0 0-.2-5.6 5.8 5.8 0 0 0-3.9-2.4c-.8-.2-1.7-.2-2.6 0a7 7 0 0 0-2.5 1.2 8 8 0 0 0-2 2.1c-.5.9-.9 1.9-1 3a8.8 8.8 0 0 0 1.5 6.7 10 10 0 0 0 6.6 4.1c1.4.3 3 .3 4.4 0a13 13 0 0 0 7.8-5.6c1-1.6 1.6-3.4 2-5.2a15.2 15.2 0 0 0-2.7-11.6 17.2 17.2 0 0 0-11.5-7.2c-2.4-.4-5-.4-7.6.2-2.6.6-5.2 1.7-7.5 3.3a22.6 22.6 0 0 0-6 6.4 24.5 24.5 0 0 0-3.3 8.9A26.3 26.3 0 0 0 11 43a29.7 29.7 0 0 0 19.8 12.4A33.5 33.5 0 0 0 54.2 51"/>';
        } else if (_attribute == 7) {
            // Repdigit Number
            return
                '<g class="stroke"><path d="M44 20.8h13.8V7"/><path d="M12 11a25.4 25.4 0 0 1 36 0l9.8 9.8"/><path d="M16 37.2H2.3V51"/><path d="M48 47a25.4 25.4 0 0 1-36 0l-9.8-9.8"/></g>';
        } else if (_attribute == 8) {
            // Weird Number
            return
                '<path d="M28.8 41.6c-1.8 0-3.3-1.5-3-3.3.1-1.3.4-2.4.7-3.3a17 17 0 0 1 3.6-5.4l4.6-4.7c2-2.3 3-4.7 3-7.2s-.7-4.4-2-5.8c-1.3-1.4-3.2-2.1-5.6-2.1-2.4 0-4.3.6-5.8 1.9-.6.6-1.1 1.2-1.5 2-.8 1.6-2.1 3.1-3.9 3.1-1.8 0-3.3-1.5-2.9-3.2.6-2.4 1.8-4.4 3.7-6 2.7-2.3 6.1-3.5 10.4-3.5 4.4 0 7.9 1.2 10.3 3.6 2.5 2.4 3.7 5.6 3.7 9.8 0 4-1.9 8.1-5.6 12.1l-3.9 3.8a10 10 0 0 0-2.3 5c-.3 1.7-1.7 3.2-3.5 3.2Zm-3.5 11.1c0-1 .3-1.9 1-2.6.6-.7 1.5-1.1 2.8-1.1 1.3 0 2.2.4 2.9 1 .6.8 1 1.7 1 2.7 0 1-.4 2-1 2.7-.7.6-1.6 1-2.9 1-1.3 0-2.2-.4-2.9-1-.6-.7-1-1.6-1-2.7Z"/>';
        } else if (_attribute == 9) {
            // Triangular Number
            return
                '<path d="M2 51 28.2 8.6a2 2 0 0 1 3.4 0L58.1 51a2 2 0 0 1-1.7 3.1H3.6A2 2 0 0 1 2 51Z"/>';
        } else if (_attribute == 10) {
            // Sophie Germain Prime
            return
                '<path d="M11.6 32.2c-4.1-1.4-7-3.1-9-5.1C1 25.1 0 22.7 0 19.9c0-3.2 1-5.8 3-7.6 2-1.9 4.8-2.8 8.3-2.8 3.3 0 6.2.4 8.7 1.2.8.3 1.4.7 1.9 1.5.5.7.7 1.5.7 2.3 0 .6-.3 1.1-.8 1.5-.5.3-1 .3-1.7 0a21 21 0 0 0-8.3-1.7c-1.9 0-3.4.5-4.4 1.5-1 1-1.6 2.3-1.6 4a6 6 0 0 0 1.5 4c1 1.1 2.4 2 4.3 2.6 4.7 1.7 8 3.4 9.8 5.4 1.9 2 2.8 4.5 2.8 7.5 0 3.7-1 6.5-3.3 8.4-2.2 1.9-5.5 2.8-9.9 2.8-2.8 0-5.4-.4-7.7-1.3-1.6-.7-2.5-2-2.5-4 0-.7.3-1.1.8-1.4.6-.3 1-.3 1.6 0a15 15 0 0 0 7.3 1.8c5.2 0 7.8-2.1 7.8-6.3 0-1.6-.5-3-1.6-4.1-1-1.1-2.7-2.1-5.1-3Z"/><path d="M47.6 50.5c-5.5 0-10-1.9-13.5-5.6A20.8 20.8 0 0 1 28.8 30c0-6.3 1.8-11.3 5.3-15 3.6-3.7 8.4-5.5 14.6-5.5 2.5 0 4.8.2 7 .5a3.1 3.1 0 0 1 2.5 3.1c0 .7-.3 1.2-.8 1.6a2 2 0 0 1-1.7.3c-2-.5-4-.7-6.5-.7-4.6 0-8.2 1.4-10.7 4C36 21 34.8 25 34.8 30a17 17 0 0 0 3.7 11.5c2.4 2.8 5.6 4.2 9.7 4.2 2 0 4-.3 5.8-.9.2 0 .3-.2.3-.5V31.5c0-.3-.1-.5-.4-.5H45c-.7 0-1.2-.2-1.7-.6-.4-.5-.6-1-.6-1.7s.2-1.2.6-1.7c.5-.4 1-.7 1.7-.7h11.8a3 3 0 0 1 2.2 1 3 3 0 0 1 .9 2.2v15.4c0 1-.3 1.8-.8 2.6s-1.2 1.3-2 1.6c-2.9 1-6 1.4-9.6 1.4Z"/>';
        } else if (_attribute == 11) {
            // Strong Prime
            return
                '<g class="stroke"><path d="M4 28h52"/><path d="M16 40V15"/><path d="M10 34V21"/><path d="M43.6 40V15"/><path d="M50 34.8V20.2"/></g>';
        } else if (_attribute == 12) {
            // Frugal Number
            return
                '<circle cx="8" cy="29" r="8"/><circle cx="30" cy="29" r="8"/><circle cx="52" cy="29" r="8"/>';
        } else if (_attribute == 13) {
            // Square Number
            return '<rect width="60" height="60" rx="2"/>';
        } else if (_attribute == 14) {
            // EMIRP
            return
                '<path d="m14.8 27.7 21.4-16.1a4 4 0 0 0 1.6-3.2V4a2 2 0 0 0-3.2-1.6L2.3 26.8l-.6.4c-.9.6-1.7 1.2-1.7 2.1 0 .7.3 1.4.7 1.7l33.8 28a2 2 0 0 0 3.3-1.5v-5.1a4 4 0 0 0-1.4-3L14.7 30.8a2 2 0 0 1 .1-3.2ZM59.8 5v52.6a2 2 0 0 1-3.3 1.5L22.7 31a2 2 0 0 1 0-3l34-25.7c1.2-1 3.1 1 3.1 2.6Z"/>';
        } else if (_attribute == 15) {
            // Magic Number
            return
                '<path d="M28.1 2.9a2 2 0 0 1 3.8 0l5.5 16.9a2 2 0 0 0 2 1.4H57a2 2 0 0 1 1.2 3.6L44 35.3a2 2 0 0 0-.7 2.2l5.5 17a2 2 0 0 1-3.1 2.2L31.2 46.2a2 2 0 0 0-2.4 0L14.4 56.7a2 2 0 0 1-3-2.2l5.4-17a2 2 0 0 0-.7-2.2L1.7 24.8a2 2 0 0 1 1.2-3.6h17.8a2 2 0 0 0 1.9-1.4l5.5-17Z"/>';
        } else if (_attribute == 16) {
            // Lucky Number
            return
                '<path d="M31.3 23.8a2 2 0 0 1-2.6 0C20.3 16.4 16 12.4 16 7.5 16 3.4 19.3 0 23.5 0a9 9 0 0 1 4.8 1.3c1 .7 2.4.7 3.4 0C33 .5 34.7 0 36.3 0 40.5 0 44 3.2 44 7.3c0 5-4.3 9.1-12.7 16.5Z"/><path d="M23.8 28.7C16.4 20.3 12.4 16 7.3 16c-4 0-7.3 3.5-7.3 7.7 0 1.7.5 3.3 1.3 4.6.7 1 .7 2.4 0 3.4A9 9 0 0 0 0 36.5C0 40.7 3.4 44 7.5 44c4.9 0 9-4.3 16.3-12.7a2 2 0 0 0 0-2.6Z"/><path d="M52.7 44c-5 0-9.1-4.3-16.5-12.7a2 2 0 0 1 0-2.6C43.6 20.3 47.6 16 52.5 16c4 0 7.5 3.3 7.5 7.5a9 9 0 0 1-1.3 4.8c-.7 1-.7 2.4 0 3.4.8 1.3 1.3 3 1.3 4.6 0 4.2-3.2 7.7-7.3 7.7Z"/><path d="M28.7 36.2C20.3 43.6 16 47.6 16 52.7c0 4 3.5 7.3 7.7 7.3 1.7 0 3.3-.5 4.6-1.3 1-.7 2.4-.7 3.4 0a9 9 0 0 0 4.8 1.3c4.2 0 7.5-3.4 7.5-7.5 0-4.9-4.3-9-12.7-16.3a2 2 0 0 0-2.6 0Z"/>';
        } else if (_attribute == 17) {
            // Good Prime
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M56.6 8.3c2 1.4 2.5 4.2 1 6.3l-29.2 42a4.5 4.5 0 0 1-7.3.1L2.4 32.2a4.5 4.5 0 1 1 7.2-5.4l15 19.6 25.7-37c1.4-2 4.2-2.5 6.3-1Z"/>';
        } else if (_attribute == 18) {
            // Happy Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M30 60a30 30 0 1 0 0-60 30 30 0 0 0 0 60ZM17.5 23c5 0 6.5 3.7 6.5-1.5S21 12 17.5 12c-3.6 0-6.5 4.3-6.5 9.5s1.5 1.5 6.5 1.5ZM49 21.5c0 5.2-2 1.5-6.5 1.5-5 0-6.5 3.7-6.5-1.5s3-9.5 6.5-9.5c3.6 0 6.5 4.3 6.5 9.5Zm-2.8 21.9c1.3-1.8 1.4-5.6-.8-5.6H13.6a4 4 0 0 0-.8 5.6 20.5 20.5 0 0 0 33.4 0Z"/>';
        } else if (_attribute == 19) {
            // Untouchable Number
            return
                '<path d="M8.8 2.2a4 4 0 0 0-5.6 5.6l21.6 21.7L3.2 51.2a4 4 0 1 0 5.6 5.6l21.7-21.6 21.7 21.6a4 4 0 1 0 5.6-5.6L36.2 29.5 57.8 7.8a4 4 0 1 0-5.6-5.6L30.5 23.8 8.8 2.2Z"/>';
        } else if (_attribute == 20) {
            // Semiperfect Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M42.7 1a4 4 0 0 1 4 4v50.6a4 4 0 1 1-8 0V40.2l-11.9 12a4 4 0 1 1-5.6-5.7l12.1-12.2H17a4 4 0 0 1 0-8h15.3L21.2 15a4 4 0 1 1 5.6-5.6l12 11.8V5a4 4 0 0 1 4-4Z"/>';
        } else if (_attribute == 21) {
            // Harshad Number
            return
                '<path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0Z"/><path d="M3.2 57.8a4 4 0 0 1 0-5.6l49-49a4 4 0 0 1 5.6 5.6l-49 49a4 4 0 0 1-5.6 0Z"/><path d="M52 60a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z"/>';
        } else if (_attribute == 22) {
            // Evil Number
            return
                '<path d="M28.3 2.6 23 11a2 2 0 0 0 1.7 3.1H26v12h-7a6 6 0 0 1-6-6v-6h.4a2 2 0 0 0 1.8-3L13 7.4V7h-.3l-2.5-4.2a2 2 0 0 0-3.4 0l-5 8.2a2 2 0 0 0 1.8 3H5v6a14 14 0 0 0 14 14h7v22a4 4 0 1 0 8 0V34h8a14 14 0 0 0 14-14v-6h.4a2 2 0 0 0 1.8-3L56 7.4V7h-.3l-2.5-4.2a2 2 0 0 0-3.4 0l-5 8.2a2 2 0 0 0 1.8 3H48v6a6 6 0 0 1-6 6h-8V14h1.3a2 2 0 0 0 1.7-3l-5.3-8.4a2 2 0 0 0-3.4 0Z"/>';
        } else if (_attribute == 23) {
            // Unit
            return
                '<path d="M30-.5c.7 0 1.4.2 2 .5h12a4 4 0 0 1 0 8h-9.5v44H44a4 4 0 0 1 0 8H32a4.5 4.5 0 0 1-4 0H17a4 4 0 0 1 0-8h8.5V8H17a4 4 0 0 1 0-8h11c.6-.3 1.3-.5 2-.5Z"/>';
        } else if (_attribute == 24) {
            // Prime
            return '<circle cx="30" cy="30" r="30"/>';
        } else {
            // Composite
            return '<circle class="stroke" cx="30" cy="30" r="26"/>';
        }
    }

    function _icons(
        uint256 _tokenId,
        bool _isPrime,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        string memory icons;
        uint256 count = 0;
        for (uint256 i = 24; i > 0; i--) {
            string memory icon;

            if (i == 24) {
                uint256 specialIdx = _tokenId == 1 ? 23 : _isPrime ? 24 : 25;
                icon = _getIconGeometry(specialIdx);
            } else if (_attributeValues[i - 1]) {
                icon = _getIconGeometry(i - 1);
            } else {
                continue;
            }

            // icon geom width = 60
            // scale = 16/60 = 0.266
            // spacing = (60/16) * 23 = 86.25
            uint256 x = ((count * 1e2) * (8625)) / 1e2;
            icons = string(
                abi.encodePacked(
                    icons,
                    '<g id="i-',
                    _toString(i),
                    '" transform="scale(.266) translate(-',
                    _toDecimalString(x, 2),
                    ',0)">',
                    icon,
                    "</g>"
                )
            );
            count = count + 1;
        }
        output = string(
            abi.encodePacked('<g id="icons" transform="translate(317,317)">', icons, "</g>")
        );
    }

    function _circles(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors
    ) internal pure returns (string memory output) {
        uint256 nFactor = _factors.length;
        string memory factorStr;
        string memory twinStr;
        string memory cousinStr;
        string memory sexyStr;
        string memory squareStr;

        {
            bool[14][] memory factorRows = _getBitRows(_factors);
            for (uint256 i = 0; i < nFactor; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (factorRows[i][j]) {
                        factorStr = string(abi.encodePacked(factorStr, _circle(j, i, "factor")));
                    }
                }
            }
        }

        {
            uint16[] memory squares = _getSquares(_tokenId);
            bool[14][] memory squareRows = _getBitRows(squares);

            for (uint256 i = 0; i < squareRows.length; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (squareRows[i][j]) {
                        squareStr = string(
                            abi.encodePacked(squareStr, _circle(j, nFactor + i, "square"))
                        );
                    }
                }
            }
            squareStr = string(abi.encodePacked('<g opacity=".2">', squareStr, "</g>"));
        }

        {
            bool[14][] memory twinRows = _getBitRows(_numberData.prime.twins);
            bool[14][] memory cousinRows = _getBitRows(_numberData.prime.cousins);
            bool[14][] memory sexyRows = _getBitRows(_numberData.prime.sexyPrimes);

            for (uint256 i = 0; i < 2; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (twinRows[i][j]) {
                        twinStr = string(
                            abi.encodePacked(twinStr, _circle(j, nFactor + i, "twin"))
                        );
                    }
                    if (cousinRows[i][j]) {
                        cousinStr = string(
                            abi.encodePacked(cousinStr, _circle(j, nFactor + 2 + i, "cousin"))
                        );
                    }
                    if (sexyRows[i][j]) {
                        sexyStr = string(
                            abi.encodePacked(sexyStr, _circle(j, nFactor + 4 + i, "sexy"))
                        );
                    }
                }
            }
        }

        output = string(
            abi.encodePacked(
                '<g id="grid" transform="translate(26,26)">',
                squareStr,
                twinStr,
                cousinStr,
                sexyStr,
                factorStr,
                "</g>"
            )
        );
    }

    function _getSquares(uint256 _tokenId) internal pure returns (uint16[] memory) {
        uint16[] memory squares = new uint16[](14);
        if (_tokenId > 1) {
            for (uint256 i = 0; i < 14; i++) {
                uint256 square = _tokenId**(i + 2);
                if (square > 16384) {
                    break;
                }
                squares[i] = uint16(square);
            }
        }
        return squares;
    }

    function _circle(
        uint256 _xIndex,
        uint256 _yIndex,
        string memory _class
    ) internal pure returns (string memory output) {
        string memory duration;

        uint256 index = (_yIndex * 14) + _xIndex + 1;
        if (index == 1) {
            duration = "40";
        } else {
            uint256 reciprocal = (1e6 * 1e6) / (1e6 * index);
            duration = _toDecimalString(reciprocal * 40, 6);
        }

        output = string(
            abi.encodePacked(
                '<circle r="8" cx="',
                _toString(23 * _xIndex),
                '" cy="',
                _toString(23 * _yIndex),
                '" class="',
                _class,
                '">',
                '<animate attributeName="opacity" values="1;.3;1" dur="',
                duration,
                's" repeatCount="indefinite"/>',
                "</circle>"
            )
        );
    }

    function _getBits(uint16 _input) internal pure returns (bool[14] memory) {
        bool[14] memory bits;
        for (uint8 i = 0; i < 14; i++) {
            uint16 flag = (_input >> i) & uint16(1);
            bits[i] = flag == 1;
        }
        return bits;
    }

    function _getBitRows(uint16[] memory _inputs) internal pure returns (bool[14][] memory) {
        bool[14][] memory rows = new bool[14][](_inputs.length);
        for (uint8 i = 0; i < _inputs.length; i++) {
            rows[i] = _getBits(_inputs[i]);
        }
        return rows;
    }

    function _getBitRows(uint16[2] memory _inputs) internal pure returns (bool[14][] memory) {
        bool[14][] memory rows = new bool[14][](_inputs.length);
        for (uint8 i = 0; i < _inputs.length; i++) {
            rows[i] = _getBits(_inputs[i]);
        }
        return rows;
    }

    function _getAttributes(string[24] memory _parts) internal pure returns (string memory output) {
        for (uint256 i = 0; i < _parts.length; i++) {
            string memory input = _parts[i];

            if (bytes(input).length == 0) {
                continue;
            }

            output = string(abi.encodePacked(output, bytes(output).length > 0 ? "," : "", input));
        }
        return output;
    }

    function _getDigits(uint256 _value) internal pure returns (uint256[] memory) {
        if (_value == 0) {
            uint256[] memory zero = new uint256[](1);
            return zero;
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        uint256[] memory result = new uint256[](digits);
        temp = _value;
        while (temp != 0) {
            digits -= 1;
            result[digits] = uint256(temp % 10);
            temp /= 10;
        }
        return result;
    }

    function _toString(uint256 _value) internal pure returns (string memory) {
        uint256[] memory digits = _getDigits(uint256(_value));
        bytes memory buffer = new bytes(digits.length);
        for (uint256 i = 0; i < digits.length; i++) {
            buffer[i] = bytes1(uint8(48 + digits[i]));
        }
        return string(buffer);
    }

    function _toDecimalString(uint256 _value, uint256 _decimals)
        internal
        pure
        returns (string memory)
    {
        if (_decimals == 0 || _value == 0) {
            return _toString(_value);
        }

        uint256[] memory digits = _getDigits(_value);
        uint256 len = digits.length;
        bool undersized = len <= _decimals;

        // Index of the decimal point
        uint256 ptIdx = undersized ? 1 : len - _decimals;

        // Leading zeroes
        uint256 leading = undersized ? 1 + (_decimals - len) : 0;

        // Create buffer for total length
        uint256 bufferLen = len + 1 + leading;
        bytes memory buffer = new bytes(bufferLen);
        uint256 offset = 0;

        // Fill buffer
        for (uint256 i = 0; i < bufferLen; i++) {
            if (i == ptIdx) {
                // Add decimal point
                buffer[i] = bytes1(uint8(46));
                offset++;
            } else if (leading > 0 && i <= leading) {
                // Add leading zero
                buffer[i] = bytes1(uint8(48));
                offset++;
            } else {
                // Add digit with index offset for added bytes
                buffer[i] = bytes1(uint8(48 + digits[i - offset]));
            }
        }

        return string(buffer);
    }

    function _attributeNames(uint256 _i) internal pure returns (string memory) {
        string[23] memory attributeNames = [
            "Taxicab",
            "Perfect",
            "Euler's Lucky Number",
            "Unique Prime",
            "Friendly",
            "Colossally Abundant",
            "Fibonacci",
            "Repdigit",
            "Weird",
            "Triangular",
            "Sophie Germain Prime",
            "Strong Prime",
            "Frugal",
            "Square",
            "Emirp",
            "Magic",
            "Lucky",
            "Good Prime",
            "Happy",
            "Untouchable",
            "Semiperfect",
            "Harshad",
            "Evil"
        ];
        return attributeNames[_i];
    }
}