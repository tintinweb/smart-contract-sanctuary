// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < count; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }

    /**
     * Load 16
     *
     * Converts two bytes to a 16 bit unsigned integer
     *
     * @param _leadingBytes the first byte of the unsigned integer in [256, 65536]
     * @param _endingBytes the second byte of the unsigned integer in [0, 255]
     * @return uint16 The resulting integer value
     */
    function load16(bytes1 _leadingBytes, bytes1 _endingBytes)
        public
        pure
        returns (uint16)
    {
        return
            (uint16(uint8(_leadingBytes)) << 8) + uint16(uint8(_endingBytes));
    }

    /**
     * Load 12
     *
     * Converts three bytes into two uint12 integers
     *
     * @return (uint16, uint16) The two uint16 values up to 2^12 each
     */
    function load12x2(
        bytes1 first,
        bytes1 second,
        bytes1 third
    ) public pure returns (uint16, uint16) {
        return (
            (uint16(uint8(first)) << 4) + (uint16(uint8(second)) >> 4),
            (uint16(uint8(second & hex"0f")) << 8) + uint16(uint8(third))
        );
    }
}