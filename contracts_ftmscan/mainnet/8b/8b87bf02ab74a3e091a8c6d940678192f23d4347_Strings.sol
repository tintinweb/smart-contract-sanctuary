/**
 *Submitted for verification at FtmScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Small library for working with strings
 * @author yearn.finance
 */

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
   * @notice Find the index of a string in another string
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
    for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
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
   * @dev Supports strings of arbitrary length
   * @param input0 First string to compare
   * @param input1 Second string to compare
   * @return Returns true if strings are exactly equal, false if not
   */
  function stringsEqual(string memory input0, string memory input1)
    public
    pure
    returns (bool)
  {
    uint256 input0Length = bytes(input0).length;
    uint256 input1Length = bytes(input1).length;
    uint256 maxLength;
    if (input0Length > input1Length) {
      maxLength = input0Length;
    } else {
      maxLength = input1Length;
    }
    uint256 numberOfRowsToCompare = (maxLength / 32) + 1;
    bytes32 input0Bytes32;
    bytes32 input1Bytes32;
    for (uint256 rowIdx; rowIdx < numberOfRowsToCompare; rowIdx++) {
      uint256 offset = 0x20 * (rowIdx + 1);
      assembly {
        input0Bytes32 := mload(add(input0, offset))
        input1Bytes32 := mload(add(input1, offset))
      }
      if (input0Bytes32 != input1Bytes32) {
        return false;
      }
    }
    return true;
  }

  /**
   * @notice Convert ASCII to integer
   * @param input Integer as a string (ie. "345")
   * @param base Base to use for the conversion (10 for decimal)
   * @return output Returns uint256 representation of input string
   * @dev Based on GemERC721 utility but includes a fix
   */
  function atoi(string memory input, uint8 base)
    public
    pure
    returns (uint256 output)
  {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    bytes memory buf = bytes(input);
    for (uint256 idx = 0; idx < buf.length; idx++) {
      uint8 digit = uint8(buf[idx]) - 0x30;
      if (digit > 10) {
        digit -= 7;
      }
      require(digit < base);
      output *= base;
      output += digit;
    }
    return output;
  }

  /**
   * @notice Convert integer to ASCII
   * @param input Integer as a string (ie. "345")
   * @param base Base to use for the conversion (10 for decimal)
   * @return output Returns string representation of input integer
   * @dev Based on GemERC721 utility but includes a fix
   */
  function itoa(uint256 input, uint8 base)
    public
    pure
    returns (string memory output)
  {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    if (input == 0) {
      return "0";
    }
    bytes memory buf = new bytes(256);
    uint256 idx = 0;
    while (input > 0) {
      uint8 digit = uint8(input % base);
      uint8 ascii = digit + 0x30;
      if (digit > 9) {
        ascii += 7;
      }
      buf[idx++] = bytes1(ascii);
      input /= base;
    }
    uint256 length = idx;
    for (idx = 0; idx < length / 2; idx++) {
      buf[idx] ^= buf[length - 1 - idx];
      buf[length - 1 - idx] ^= buf[idx];
      buf[idx] ^= buf[length - 1 - idx];
    }
    output = string(buf);
  }
}