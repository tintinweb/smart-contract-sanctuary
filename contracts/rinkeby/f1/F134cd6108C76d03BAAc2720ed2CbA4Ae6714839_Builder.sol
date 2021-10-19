/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/builder.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Strings.sol

/* pragma solidity ^0.8.0; */

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

////// src/base64.sol

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

////// src/builder.sol
/* pragma solidity ^0.8.7; */
/* import "./base64.sol"; */
/* import "openzeppelin-contracts/utils/Strings.sol"; */

contract Builder {
    function buildMetaData(
        string memory projectName,
        uint256 tokenId,
        uint128 amtPerCycle,
        bool active
    ) public pure returns (string memory) {
        string memory supportRateString = toTwoDecimals(amtPerCycle);
        string memory tokenIdString = Strings.toString(tokenId);
        string memory tokenActiveString = "false";
        if (active) {
            tokenActiveString = "true";
        }

        string memory svg = string(
            abi.encodePacked(
                '<svg class="svgBody" width="300" height="300" viewBox="0 0 300 300" fill="white" xmlns="http://www.w3.org/2000/svg">',
                "<style>svg { background-color: black; }</style>",
                '<text x="20" y="20" font-family="Courier New, Courier, Lucida Sans Typewriter" class="small"> \xf0\x9f\x8c\xb1 Radicle Funding \xf0\x9f\x8c\xb1 </text>',
                '<text x="20" y="80" class="medium">Project Name:</text>  <text x="150" y="80" class="small">',
                projectName,
                "</text>",
                '<text x="20" y="100" class="medium">NFT-ID:</text><text x="150" y="100" class="small">',
                tokenIdString,
                "</text>",
                '<text x="20" y="120" class="medium">Support-Rate:</text><text x="150" y="120" class="small">',
                supportRateString,
                " DAI</text>",
                "</svg>"
            )
        );
        return
            string(
                abi.encodePacked(
                    '{"projectName":"',
                    projectName,
                    '", ',
                    '"tokenId":"',
                    tokenIdString,
                    '", ',
                    '"supportRate":"',
                    supportRateString,
                    " DAI",
                    '", ',
                    '"active":"',
                    tokenActiveString,
                    '", ',
                    '"image": "',
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svg)),
                    '"}'
                )
            );
    }
    function toTwoDecimals(uint128 number) public pure returns(string memory numberString) {
        // decimal after the first two decimals are rounded up or down
        number += 0.005 * 10**18;
        numberString = Strings.toString(number/1 ether);
        uint128 twoDecimals = (number % 1 ether) / 10**16;
        if(twoDecimals > 0) {
            string memory point = ".";
            if (twoDecimals > 0 && twoDecimals < 10) {
                point = ".0";
            }
            numberString = string(
                abi.encodePacked(numberString, point, Strings.toString(twoDecimals))
            );
        }
        return numberString;
    }
}