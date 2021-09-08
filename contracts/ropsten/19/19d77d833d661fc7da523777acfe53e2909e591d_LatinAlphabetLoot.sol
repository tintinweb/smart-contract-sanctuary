// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract LatinAlphabetLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    string[] private letters = [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIRST", letters);
    }

    function getSecond(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SECOND", letters);
    }

    function getThird(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "THIRD", letters);
    }

    function getFourth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOURTH", letters);
    }

    function getFifth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIFTH", letters);
    }

    function getSixth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SIXTH", letters);
    }

    function getSeventh(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SEVENT", letters);
    }

    function getEight(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EIGHT", letters);
    }
    
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function pluck(
      uint256 tokenId,
      string memory keyPrefix,
      string[] memory sourceArray
      ) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 luck = rand % 21;
        if (luck > 14) {
            output = toLower(output);
        }
        if (luck >= 19) {
            if (luck == 19) {
                output = "Z";
            } else if (luck == 20) {
                output = "z";
            } else {
                output = string(abi.encodePacked(output, output));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getFirst(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSecond(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getThird(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getFourth(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFifth(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getSixth(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getSeventh(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getEight(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Loot #', toString(tokenId), '", "description": "Latin Alphabet Loot is randomized modern Latin alphabet letters generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Latin Alphabet Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

     function claim(uint256 tokenId) public nonReentrant {
         require(tokenId > 0 && tokenId < 8889, "Token ID invalid");
         _safeMint(_msgSender(), tokenId);
     }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    constructor() ERC721("Latin Alphabet Loot", "LALOOT") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}