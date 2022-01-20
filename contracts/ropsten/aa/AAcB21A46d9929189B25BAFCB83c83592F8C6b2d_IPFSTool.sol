/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library IPFSTool {
    bytes constant sha256MultiHash = hex"1220";
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /// @return The IPFS hash in base58
    function ipfsToString(bytes32 ipfs) public pure returns (string memory) {
        return toBase58(concat(sha256MultiHash, toBytes(ipfs)));
    }

    /// @dev Converts hex string to base 58
    function toBase58(bytes memory source) internal pure returns (string memory) {
        if (source.length == 0) return "";
        uint8[] memory digits = new uint8[](48);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        //return digits;
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function lengthEncode(uint256 length) internal pure returns (bytes memory) {
        if (length < 128) {
            return to_binary(length);
        } else {
            return concat(to_binary((length % 128) + 128), to_binary(length / 128));
        }
    }

    function toBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = input[i];
        }
        return output;
    }

    function equal(bytes memory one, bytes memory two) internal pure returns (bool) {
        if (!(one.length == two.length)) {
            return false;
        }
        for (uint256 i = 0; i < one.length; i++) {
            if (!(one[i] == two[i])) {
                return false;
            }
        }
        return true;
    }

    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (string memory) {
        string memory output = "";
        for (uint256 i = 0; i < indices.length; i++) {
            string memory temp = string(abi.encodePacked(output, ALPHABET[indices[i]]));
            output = temp;
        }
        return output;
    }

    function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
        bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
        uint256 i = 0;
        for (i; i < byteArray.length; i++) {
            returnArray[i] = byteArray[i];
        }
        for (i; i < (byteArray.length + byteArray2.length); i++) {
            returnArray[i] = byteArray2[i - byteArray.length];
        }
        return returnArray;
    }

    function to_binary(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return new bytes(0);
        } else {
            bytes1 s = bytes1(uint8(x % 256));
            bytes memory r = new bytes(1);
            r[0] = s;
            return concat(to_binary(x / 256), r);
        }
    }
}