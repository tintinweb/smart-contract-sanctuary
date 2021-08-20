// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
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

// SPDX-License-Identifier: MIT
// MODIFIED Uniswap-v3-periphery
pragma solidity 0.8.4;

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexStringNoPrefix(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./HexStrings.sol";
import "./NFTSVG.sol";

library NFTDescriptor {
    using Strings for uint256;
    using HexStrings for uint256;

    struct URIParams {
        uint256 tokenId;
        address owner;
        string name;
        string symbol;
    }

    function constructTokenURI(URIParams memory params)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(abi.encodePacked(params.name, "-NFT")),
                                '", "description":"',
                                generateDescription(),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(bytes(generateSVGImage(params))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function escapeQuotes(string memory symbol)
        internal
        pure
        returns (string memory)
    {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes =
                new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function addressToString(address addr)
        internal
        pure
        returns (string memory)
    {
        return uint256(uint160(addr)).toHexString(20);
    }

    function toColorHex(uint256 base, uint256 offset)
        internal
        pure
        returns (string memory str)
    {
        return string((base >> offset).toHexStringNoPrefix(3));
    }

    function generateDescription() private pure returns (string memory) {
        return
            "This NFT represents a 88mph bond. The owner of this NFT can change URI.\\n";
    }

    function generateSVGImage(URIParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        NFTSVG.SVGParams memory svgParams =
            NFTSVG.SVGParams({
                tokenId: params.tokenId,
                owner: addressToString(params.owner),
                name: params.name,
                symbol: params.symbol,
                color0: toColorHex(
                    uint256(
                        keccak256(
                            abi.encodePacked(params.owner, params.tokenId)
                        )
                    ),
                    140
                ),
                color1: toColorHex(
                    uint256(
                        keccak256(
                            abi.encodePacked(params.owner, params.tokenId)
                        )
                    ),
                    0
                )
            });

        return NFTSVG.generateSVG(svgParams);
    }
}

// SPDX-License-Identifier: MIT
///@notice Inspired by Uniswap-v3-periphery NFTSVG.sol
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./HexStrings.sol";

library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        string owner;
        string name;
        string symbol;
        string color0;
        string color1;
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(params),
                    generateSVGBackGround(params.tokenId, params.name),
                    generateSVGFigures(params),
                    "</svg>"
                )
            );
    }

    function generateSVGDefs(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<svg width="419" height="292" viewBox="0 0 419 292" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g1" x1="0%" y1="50%" >',
                generateSVGColorPartOne(params),
                generateSVGColorPartTwo(params),
                "</linearGradient>",
                generateSVGFilter(
                    "filter0_d",
                    ["85.852", "212.189"],
                    ["238.557", "53.1563"],
                    "2"
                ),
                generateSVGFilter(
                    "filter1_d",
                    ["90.075", "103.557"],
                    ["228.372", "171.911"],
                    "6"
                ),
                '<linearGradient id="paint0_linear" x1="209.162" y1="291.796" x2="209.162" y2="1.0534" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE600"/><stop offset="0.307292" stop-color="#FAAD14"/><stop offset="0.671875" stop-color="#F7169C"/><stop offset="1" stop-color="#3435F5"/></linearGradient>',
                generateSVGGradient(),
                "</defs>"
            )
        );
    }

    function generateSVGFigures(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M195.243 283.687C201.373 294.499 216.951 294.499 223.081 283.687L235.238 262.244H183.086L195.243 283.687ZM173.834 245.923L155.328 213.282H262.996L244.49 245.923H173.834ZM146.076 196.961H272.248L290.754 164.32H127.57L146.076 196.961ZM118.318 147.999L99.8123 115.358H318.512L300.006 147.999H118.318ZM90.5596 99.0369H327.764L349.634 60.4607H68.6896L90.5596 99.0369ZM59.437 44.1401L47.9572 23.8909C41.9102 13.2248 49.6149 0 61.876 0H356.448C368.709 0 376.414 13.2248 370.367 23.891L358.887 44.1401H59.437Z" fill="url(#paint0_linear)"/>',
                generateSVGText(params)
            )
        );
    }

    function generateSVGText(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<g fill="black" font-family="monospace" font-style="bold" font-weight="bolder" style="text-shadow:4px 4px #558ABB; text-align:center;">',
                '<text><tspan x="35" y="105" dx="20" font-size="25">',
                params.name,
                '</tspan><tspan x="35" y="165" dx="10" font-size="12" >',
                params.owner,
                '</tspan><tspan x="165" y="190" dx="10" font-size="12" >tokenId :',
                params.tokenId.toString(),
                "</tspan></text></g>"
            )
        );
    }

    function generateSVGFilter(
        string memory id,
        string[2] memory coordinates,
        string[2] memory size,
        string memory stdDeviation
    ) private pure returns (string memory svg) {
        string memory filterFragment =
            string(
                abi.encodePacked(
                    '<filter id="',
                    id,
                    '" x="',
                    coordinates[0],
                    '" y="',
                    coordinates[1],
                    '" width="',
                    size[0],
                    '" height="',
                    size[1],
                    '" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                )
            );
        svg = string(
            abi.encodePacked(
                filterFragment,
                '<feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0"/><feOffset dy="4"/><feGaussianBlur stdDeviation="',
                stdDeviation,
                '"/><feColorMatrix type="matrix" values="0 0 0 0 0.898039 0 0 0 0 0.129412 0 0 0 0 0.615686 0 0 0 0.5 0"/><feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow"/>',
                '<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow" result="shape"/></filter>'
            )
        );
    }

    function generateSVGGradient() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                generateSVGGradientEleOne("paint1_linear"),
                generateSVGGradientEleOne("paint2_linear"),
                generateSVGGradientEleOne("paint3_linear"),
                generateSVGGradientEleTwo("paint4_linear"),
                generateSVGGradientEleTwo("paint5_linear"),
                generateSVGGradientEleTwo("paint6_linear")
            )
        );
    }

    function generateSVGGradientEleOne(string memory id)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<linearGradient id="',
                id,
                '" x1="212.356" y1="140" x2="248.856" y2="265.5" gradientUnits="userSpaceOnUse">',
                '<stop offset="0.223958" stop-color="#FF009D"/><stop offset="0.880208" stop-color="#3435F5"/></linearGradient>'
            )
        );
    }

    function generateSVGGradientEleTwo(string memory id)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<linearGradient id="',
                id,
                '" x1="195.663" y1="154.629" x2="198.752" y2="249" gradientUnits="userSpaceOnUse">',
                '<stop stop-color="white"/><stop offset="1" stop-color="#F7169C"/></linearGradient>'
            )
        );
    }

    function generateSVGColorPartOne(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        string memory values0 =
            string(abi.encodePacked("#", params.color0, "; #", params.color1));
        string memory values1 =
            string(abi.encodePacked("#", params.color1, "; #", params.color0));
        svg = string(
            abi.encodePacked(
                '<stop offset="0%" stop-color="#',
                params.color0,
                '" ><animate id="a1" attributeName="stop-color" values="',
                values0,
                '" begin="0; a2.end" dur="3s" /><animate id="a2" attributeName="stop-color" values="',
                values1,
                '" begin="a1.end" dur="3s" /></stop>'
            )
        );
    }

    function generateSVGColorPartTwo(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        string memory values0 =
            string(abi.encodePacked("#", params.color0, "; #", params.color1));
        string memory values1 =
            string(abi.encodePacked("#", params.color1, "; #", params.color0));
        svg = string(
            abi.encodePacked(
                '<stop offset="100%" stop-color="#',
                params.color1,
                '" >',
                '<animate id="a3" attributeName="stop-color" values="',
                values1,
                '" begin="0; a4.end" dur="3s" /><animate id="a4" attributeName="stop-color" values="',
                values0,
                '" begin="a3.end" dur="3s" /></stop>'
            )
        );
    }

    function generateSVGBackGround(uint256 tokenId, string memory name)
        private
        pure
        returns (string memory svg)
    {
        if (isRare(tokenId, name)) {
            svg = string(
                abi.encodePacked(
                    '<rect id="r" x="0" y="0" width="419" height="512" ',
                    'fill="url(#g1)" />'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    '<rect id="r" x="0" y="0" width="419" height="512" ',
                    'fill="black" />'
                )
            );
        }
    }

    function isRare(uint256 tokenId, string memory name)
        internal
        pure
        returns (bool)
    {
        return uint256(keccak256(abi.encodePacked(tokenId, name))) > 5**tokenId;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}