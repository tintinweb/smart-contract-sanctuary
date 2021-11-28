/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

//SPDX-License-Identifier: MIT
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

contract BlockdemyLootAttributes {
    using Strings for uint256;
    uint256 random;

    string[] private _profile = ["Trader", "Consultant", "Dev", "Lawyer"];

    string[] private _instructor = [
        "Mark Munoz",
        "Ernesto Garcia",
        "Jorge Tavares",
        "Isaac Lopez"
    ];

    string[] private _communityFriend = [
        "Camila Pineda",
        "Fer Saldivar",
        "Juan Salas",
        "Claudia Melendez",
        "Abraham Leon",
        "Diego De Leon"
    ];

    string[] private _leverage = [
        "2x",
        "3x",
        "5x",
        "10x",
        "15x",
        "20x",
        "50x",
        "125x"
    ];

    string[] private _exchange = [
        "Coinbase",
        "Bitso",
        "Uniswap",
        "Buda",
        "Kraken",
        "Binance"
    ];

    string[] private _shitcoin = ["SHIBA", "DOGE", "XYO", "CATE"];

    string[] private _tokenProject = [
        "Gaming",
        "Real State",
        "Casino",
        "Stocks",
        "Art",
        "Memes"
    ];

    string[] private _program = [
        "Code and Hacks",
        "Crypto Webinar Series",
        "Blockdemy Legal",
        "Trading Nights",
        "Crypto News"
    ];

    function setRandom(uint256 _random) internal {
      random = _random;
    }

    function deterministicNoise(string memory input)
        internal
        view
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(input, random)));
    }

    function getAttribute(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) private view returns (string memory) {
        uint256 noise = deterministicNoise(
            string(abi.encodePacked(keyPrefix, tokenId.toString()))
        );
        return sourceArray[noise % sourceArray.length];
    }

    function getProfile(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "PROFILE", _profile);
    }

    function getInstructor(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "INSTRUCTOR", _instructor);
    }

    function getCommunityFriend(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "COMMUNITY_FRIEND", _communityFriend);
    }

    function getLeverage(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "LEVERAGE", _leverage);
    }

    function getExchange(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "EXCHANGE", _exchange);
    }

    function getShitcoin(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "SHITCOIN", _shitcoin);
    }

    function getTokenProject(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "TOKEN_PROJECT", _tokenProject);
    }

    function getProgram(uint256 tokenId) internal view returns (string memory) {
        return getAttribute(tokenId, "PROGRAM", _program);
    }
}