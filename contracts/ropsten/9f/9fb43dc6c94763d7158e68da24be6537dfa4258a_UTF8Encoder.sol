/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title A library for encoding UTF-8 strings
/// @author Devin Stein
library UTF8Encoder {
  /// @notice Get the UTF-8 string for `self`
  /// @dev UTF8Encode will error if the code point is not valid
  /// @param self The code point to UTF-8 encode
  /// @return The UTF-8 string for the given code point
  function UTF8Encode(uint32 self) external pure returns (string memory) {
    bytes memory out;
    if (self <= 0x7F) {
      // Plain ASCII
      out = bytes.concat(bytes1(uint8(self)));
      return string(out);
    } else if (self <= 0x07FF) {
      // 2-byte unicode
      bytes1 b0 = bytes1(((uint8(self) >> 6) & (uint8(0x1F))) | (uint8(0xC0)));
      bytes1 b1 = bytes1(((uint8(self) >> 0) & (uint8(0x3F))) | (uint8(0x80)));
      out = bytes.concat(b0, b1);
      return string(out);
    } else if (self <= 0xFFFF) {
      // 3-byte unicode
      bytes1 b0 = bytes1(uint8(((self >> 12) & 0x0F) | 0xE0));
      bytes1 b1 = bytes1(uint8(((self >> 6) & 0x3F) | 0x80));
      bytes1 b2 = bytes1(uint8(((self >> 0) & 0x3F) | 0x80));
      out = bytes.concat(b0, b1, b2);
      return string(out);
    } else if (self <= 0x10FFFF) {
      // 4-byte unicode
      bytes1 b0 = bytes1(uint8(((self >> 18) & 0x07) | 0xF0));
      bytes1 b1 = bytes1(uint8((self >> 12) & 0x3F) | 0x80);
      bytes1 b2 = bytes1(uint8(((self >> 6) & 0x3F) | 0x80));
      bytes1 b3 = bytes1(uint8(((self >> 0) & 0x3F) | 0x80));
      out = bytes.concat(b0, b1, b2, b3);
      return string(out);
    }
    require(false, "invalid unicode code point");
    return "";
  }
}