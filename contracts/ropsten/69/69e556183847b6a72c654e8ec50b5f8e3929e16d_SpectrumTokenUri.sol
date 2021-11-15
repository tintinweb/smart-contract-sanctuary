// SPDX-License-Identifier: GPL-v2-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./ITokenUriOracle.sol";
import "./vendor/base64.sol";

// Interpretation of cosmetic data in a token URI. This data is read starting
// from the most significant bit of the token URI, so new fields can be
// compatibly added to the *end* of the struct.
struct Cosmetics {
    uint24 rgb;
    uint8 alpha;
    uint16 width;
    uint16 height;
}

contract SpectrumTokenUri is ITokenUriOracle {
    using Strings for uint256;

    function tokenURI(address _tokenContract, uint256 _tokenId)
        external
        pure
        override
        returns (string memory)
    {
        _tokenContract;
        Cosmetics memory _cosmetics = _extractCosmetics(_tokenId);
        bytes memory _svgDataUri = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(_svgBytes(_cosmetics))
        );
        string memory _widthString = uint256(_cosmetics.width).toString();
        string memory _heightString = uint256(_cosmetics.height).toString();
        // Concatenate in chunks of no more than 16 arguments, to work around
        // an internal compiler error in solc 0.8.4 when the optimizer is
        // enabled.
        bytes memory _jsonData1 = abi.encodePacked(
            '{"name":"Spectrum ',
            Strings.toHexString(_tokenId, 32),
            '","description":"',
            _widthString,
            "\\u00d7",
            _heightString,
            " rectangle filled with rgba(",
            uint256(uint8(_cosmetics.rgb >> 16)).toString(),
            ", ",
            uint256(uint8(_cosmetics.rgb >> 8)).toString(),
            ", ",
            uint256(uint8(_cosmetics.rgb)).toString(),
            ", ",
            uint256(_cosmetics.alpha).toString(),
            ').","image":"',
            _svgDataUri
        );
        bytes memory _jsonData2 = abi.encodePacked('"}');
        bytes memory _jsonData = abi.encodePacked(_jsonData1, _jsonData2);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(_jsonData)
                )
            );
    }

    function _svgBytes(Cosmetics memory _cosmetics)
        internal
        pure
        returns (bytes memory)
    {
        uint256 _opacityBp = (uint256(_cosmetics.alpha) * 10000) / 255;
        string memory _widthString = uint256(_cosmetics.width).toString();
        string memory _heightString = uint256(_cosmetics.height).toString();
        bytes memory _rgbStringBuf = bytes(
            uint256(_cosmetics.rgb).toHexString()
        );
        // `Strings.toHexString` results start with `0x`, but we want something
        // like `fill="#123456"`, so do a bit of surgery.
        _rgbStringBuf[0] = '"';
        _rgbStringBuf[1] = "#";
        string memory _quoteThenRgbString = string(_rgbStringBuf);
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
                _widthString,
                " ",
                _heightString,
                '"><path fill=',
                _quoteThenRgbString,
                '" fill-opacity="',
                _opacityBp.toString(),
                'e-4" d="M0 0H',
                _widthString,
                "V",
                _heightString,
                'H0z"/></svg>'
            );
    }

    function svg(uint256 _tokenId) external pure returns (string memory) {
        return string(_svgBytes(_extractCosmetics(_tokenId)));
    }

    function _extractCosmetics(uint256 _tokenId)
        internal
        pure
        returns (Cosmetics memory)
    {
        _tokenId >>= 192;
        uint16 _height = uint16(_tokenId);
        _tokenId >>= 16;
        uint16 _width = uint16(_tokenId);
        _tokenId >>= 16;
        uint8 _alpha = uint8(_tokenId);
        _tokenId >>= 8;
        uint24 _rgb = uint24(_tokenId);
        _tokenId >>= 24;
        return
            Cosmetics({
                rgb: _rgb,
                alpha: _alpha,
                width: _width,
                height: _height
            });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-v2-only
pragma solidity ^0.8.0;

interface ITokenUriOracle {
    /// Computes the token URI for a given token. It is implementation-defined
    /// whether the token ID need actually exist, or whether there are extra
    /// restrictions on the `_tokenContract`.
    function tokenURI(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
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

