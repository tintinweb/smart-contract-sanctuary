/**
 *Submitted for verification at FtmScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Strings {
    /**
     * @notice Search for a needle in a haystack
     * @param haystack The string to search
     * @param needle The string to search for
     */
    function stringStartsWith(string memory haystack, string memory needle)
        public
        pure
        returns (bool)
    {
        return indexOfStringInString(needle, haystack) == 0;
    }

    /**
     * @notice Case insensitive string search
     * @param needle The string to search for
     * @param haystack The string to search
     * @return Returns -1 if no match is found, otherwise returns the index of the match
     */
    function indexOfStringInString(string memory needle, string memory haystack)
        public
        pure
        returns (int256)
    {
        bytes memory _needle = bytes(needle);
        bytes memory _haystack = bytes(haystack);
        if (_haystack.length < _needle.length) {
            return -1;
        }
        bool _match;
        for (
            uint256 haystackIdx;
            haystackIdx < _haystack.length;
            haystackIdx++
        ) {
            for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
                uint8 needleChar = uint8(_needle[needleIdx]);
                if (haystackIdx + needleIdx >= _haystack.length) {
                    return -1;
                }
                uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
                if (needleChar == haystackChar) {
                    _match = true;
                    if (needleIdx == _needle.length - 1) {
                        return int256(haystackIdx);
                    }
                } else {
                    _match = false;
                    break;
                }
            }
        }
        return -1;
    }

    /**
     * @notice Check to see if two strings are exactly equal
     */
    function stringsEqual(string memory input1, string memory input2)
        public
        pure
        returns (bool)
    {
        uint256 input1Length = bytes(input1).length;
        uint256 input2Length = bytes(input2).length;
        uint256 maxLength;
        if (input1Length > input2Length) {
            maxLength = input1Length;
        } else {
            maxLength = input2Length;
        }
        uint256 numberOfRowsToCompare = (maxLength / 32) + 1;
        bytes32 input1Bytes32;
        bytes32 input2Bytes32;
        for (uint256 rowIdx; rowIdx < numberOfRowsToCompare; rowIdx++) {
            uint256 offset = 0x20 * (rowIdx + 1);
            assembly {
                input1Bytes32 := mload(add(input1, offset))
                input2Bytes32 := mload(add(input2, offset))
            }
            if (input1Bytes32 != input2Bytes32) {
                return false;
            }
        }
        return true;
    }

    function atoi(string memory a, uint8 base) public pure returns (uint256 i) {
        require(base == 2 || base == 8 || base == 10 || base == 16);
        bytes memory buf = bytes(a);
        for (uint256 p = 0; p < buf.length; p++) {
            uint8 digit = uint8(buf[p]) - 0x30;
            if (digit > 10) {
                digit -= 7;
            }
            require(digit < base);
            i *= base;
            i += digit;
        }
        return i;
    }

    function itoa(uint256 i, uint8 base) public pure returns (string memory a) {
        require(base == 2 || base == 8 || base == 10 || base == 16);
        if (i == 0) {
            return "0";
        }
        bytes memory buf = new bytes(256);
        uint256 p = 0;
        while (i > 0) {
            uint8 digit = uint8(i % base);
            uint8 ascii = digit + 0x30;
            if (digit > 9) {
                ascii += 7;
            }
            buf[p++] = bytes1(ascii);
            i /= base;
        }
        uint256 length = p;
        for (p = 0; p < length / 2; p++) {
            buf[p] ^= buf[length - 1 - p];
            buf[length - 1 - p] ^= buf[p];
            buf[p] ^= buf[length - 1 - p];
        }
        return string(buf);
    }
}