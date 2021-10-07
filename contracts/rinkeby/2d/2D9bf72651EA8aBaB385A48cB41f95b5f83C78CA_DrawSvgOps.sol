// SPDX-License-Identifier: Mixed...
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/utils/Strings.sol";

/// Copyright (c) Sterling Crispin
/// All rights reserved.
/// @title DrawSvgOps
/// @notice Provides some drawing functions used in MESSAGE
/// @author Sterling Crispin <[email protected]>
library DrawSvgOps {

    string internal constant elli1 = '<ellipse cx="';
    string internal constant elli2 = '" cy="';
    string internal constant elli3 = '" rx="';
    string internal constant elli4 = '" ry="';
    string internal constant elli5 = '" stroke="mediumpurple" stroke-dasharray="';
    string internal constant upgradeShapeEnd = '"  fill-opacity="0"/>';
    string internal constant strBlank = ' ';

    function rand(uint num) internal view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, num))) % num;
    }
    function Ellipse(uint256 size) external view returns (string memory){
        string memory xLoc = Strings.toString(rand(size-1));
        string memory yLoc = Strings.toString(rand(size-2));
        string memory output = string(abi.encodePacked(
            elli1,xLoc,
            elli2,yLoc,
            elli3,Strings.toString(rand(size-3)),
            elli4,Strings.toString(rand(size-3))));
        output = string(abi.encodePacked(
            output,
            elli5,Strings.toString(rand(7)+1),upgradeShapeEnd,
            elli1,xLoc,
            elli2,yLoc
        ));
        output = string(abi.encodePacked(
            output,elli3,
            Strings.toString(rand(size-4)),
            elli4,Strings.toString(rand(size-5)),
            elli5,Strings.toString(rand(6)+1),upgradeShapeEnd
            ));
        output = string(abi.encodePacked(
            output,
            elli1,xLoc,
            elli2,yLoc,
            elli3,Strings.toString(rand(size-5)),
            elli4));
        output = string(abi.encodePacked(
            output,Strings.toString(rand(size-6)),
            elli5,Strings.toString(rand(4)+1),upgradeShapeEnd
        ));
        return output;
    }

    function Wiggle(uint256 size) external view returns (string memory){
        string memory output = string(abi.encodePacked(
            '<path d="M ',
            Strings.toString(rand(size-1)), strBlank,
            Strings.toString(rand(size-2)), strBlank,
            'Q ', Strings.toString(rand(size-3)), strBlank));
        output = string(abi.encodePacked(output,
            Strings.toString(rand(size-4)), ', ',
            Strings.toString(rand(size-5)), strBlank,
            Strings.toString(rand(size-6)), strBlank,
            'T ',  Strings.toString(rand(size-7)), strBlank,
            Strings.toString(rand(size-8)), '"'
            ));
        output = string(abi.encodePacked(output,
            ' stroke="red" stroke-dasharray="',Strings.toString(rand(7)+1), upgradeShapeEnd
        ));
        return output;
    }
}

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}