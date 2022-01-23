/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title A library for validating, parsing, and manipulating UTF-8 encoded Unicode strings
/// @author Devin Stein
/// @notice For character introspection or more complex transformations, checkout the UnicodeData contract.
/// @dev All external and public functions use self as their first parameter to allow "using Unicode for strings;". If you have ideas for new functions or improvements, please contribute!
library Unicode {
  /// @notice Check if `self` contains only single byte ASCII characters (0-127)
  /// @dev If a string is only ASCII, then it's safe to treat each byte as a character. This returns false for extended ASCII (128-255) because they are use two bytes in UTF-8.
  /// @param self The input string
  /// @return True if  the `self` only contains ASCII
  function isASCII(string calldata self) external pure returns (bool) {
    bytes calldata _b = bytes(self);
    uint256 len = _b.length;

    for (uint256 i = 0; i < len; i++) {
      if ((_b[i] & 0x80) != 0x00) return false;
    }
    return true;
  }

  // ASCII
  /* 1 byte sequence: U+0000..U+007F */
  function isOneBytesSequence(bytes1 _b) private pure returns (bool) {
    return _b[0] <= 0x7F;
  }

  /* 0b110xxxxx: 2 bytes sequence */
  /* U+0080..U+07FF */
  function isTwoBytesSequence(bytes1 _b) private pure returns (bool) {
    return bytes1(0xC2) <= _b[0] && _b[0] <= bytes1(0xDF);
  }

  /* 0b1110xxxx: 3 bytes sequence */
  /* 3 bytes sequence: U+0800..U+FFFF */
  function isThreeBytesSequence(bytes1 _b) private pure returns (bool) {
    return bytes1(0xE0) <= _b[0] && _b[0] <= bytes1(0xEF);
  }

  /* 4 bytes sequence: U+10000..U+10FFFF */
  /* 0b11110xxx: 4 bytes sequence */
  function isFourBytesSequence(bytes1 _b) private pure returns (bool) {
    return bytes1(0xF0) <= _b[0] && _b[0] <= bytes1(0xF4);
  }

  function isContinuationByte(bytes1 _b) private pure returns (bool) {
    return ((_b & 0xC0) != 0x80);
  }

  function twoBytesCodePoint(bytes memory _b) private pure returns (uint32) {
    return (uint16(uint8(_b[0] & 0x1f)) << 6) + uint16(uint8(_b[1] & 0x3f));
  }

  function threeBytesCodePoint(bytes memory _b) private pure returns (uint32) {
    return
      (uint16(uint8(_b[0] & bytes1(0x0f))) << 12) +
      (uint16(uint8((_b[1] & bytes1(0x3f)))) << 6) +
      uint16(uint8(_b[2] & 0x3f));
  }

  function fourBytesCodePoint(bytes memory _b) private pure returns (uint32) {
    return
      ((uint32(uint8(_b[0] & 0x07)) << 18)) +
      (uint32(uint8(_b[1] & 0x3f)) << 12) +
      (uint32(uint8(_b[2] & 0x3f)) << 6) +
      uint8(_b[3] & 0x3f);
  }

  /// @notice Get length of `self`
  /// @dev For efficiency, length assumes valid UTF-8 encoded input. It only does simple checks for bytes sequences
  /// @param self The input string
  /// @return The number of UTF-8 characters in `self`
  function length(string calldata self) public pure returns (uint256) {
    bytes memory _b = bytes(self);
    uint256 end = _b.length;
    uint256 len;
    uint256 i;

    while (i < end) {
      len++;

      if (isOneBytesSequence(_b[i])) {
        i += 1;
        continue;
      } else if (isTwoBytesSequence(_b[i])) {
        i += 2;
        continue;
      } else if (isThreeBytesSequence(_b[i])) {
        i += 3;
        continue;
      } else if (isFourBytesSequence(_b[i])) {
        i += 4;
        continue;
      }

      require(false, "invalid utf8");
    }

    return len;
  }

  /// @notice Get the code point of character: `self`
  /// @dev This function requires a valid UTF-8 character
  /// @param self The input character
  /// @return The code point of `self`
  function toCodePoint(string memory self) public pure returns (uint32) {
    bytes memory _b = bytes(self);
    uint256 len = _b.length;

    require(
      len <= 4,
      "invalid utf8 character: a character cannot be more than four bytes"
    );
    require(len > 0, "invalid utf8 character: empty string");

    if (isOneBytesSequence(_b[0])) return uint8(bytes1(_b[0]));

    require(len > 1, "invalid utf8 character");

    /* 0b110xxxxx: 2 bytes sequence */
    /* U+0080..U+07FF */
    if (isTwoBytesSequence(_b[0])) {
      return twoBytesCodePoint(_b);
    }

    require(len > 2, "invalid utf8 character");

    /* 0b1110xxxx: 3 bytes sequence */
    /* 3 bytes sequence: U+0800..U+FFFF */
    if (isThreeBytesSequence(_b[0])) {
      return threeBytesCodePoint(_b);
    }

    require(len > 3, "invalid utf8 character");

    /* 0b11110xxx: 4 bytes sequence */
    /* 4 bytes sequence: U+10000..U+10FFFF */
    if (isFourBytesSequence(_b[0])) {
      return fourBytesCodePoint(_b);
    }

    require(false, "invalid utf8 character");
    return 0;
  }

  /// @notice Check if `self` is valid UTF-8
  /// @param self The input string
  /// @return True if the string is UTF-8 encoded
  function isUTF8(string calldata self) external pure returns (bool) {
    bytes memory _b = bytes(self);
    uint256 end = _b.length;
    uint32 cp;
    uint256 i;

    while (i < end) {
      if (isOneBytesSequence(_b[i])) {
        i += 1;
        continue;
      }

      /* Check continuation bytes: bit 7 should be set, bit 6 should be
       * unset (b10xxxxxx). */
      if (isContinuationByte(_b[i + 1])) return false;

      /* 0b110xxxxx: 2 bytes sequence */
      /* U+0080..U+07FF */
      if (isTwoBytesSequence(_b[i])) {
        cp = twoBytesCodePoint(bytes.concat(_b[i], _b[i + 1]));

        if (cp < 0x0080 || cp > 0x07FF) return false;

        i += 2;
        continue;
      }

      if (isContinuationByte(_b[i + 2])) return false;

      /* 0b1110xxxx: 3 bytes sequence */
      /* 3 bytes sequence: U+0800..U+FFFF */
      if (isThreeBytesSequence(_b[i])) {
        cp = threeBytesCodePoint(bytes.concat(_b[i], _b[i + 1], _b[i + 2]));

        /* (0xff & 0x0f) << 12 | (0xff & 0x3f) << 6 | (0xff & 0x3f) = 0xffff,
                   so cp <= 0xffff */
        if (cp < 0x0800) return false;

        /* surrogates (U+D800-U+DFFF) are invalid in UTF-8:
                   test if (0xD800 <= cp && cp <= 0xDFFF) */
        if ((cp >> 11) == 0x1b) return false;
        i += 3;
        continue;
      }

      if (isContinuationByte(_b[i + 3])) return false;

      /* 4 bytes sequence: U+10000..U+10FFFF */
      /* 0b11110xxx: 4 bytes sequence */
      if (isFourBytesSequence(_b[i])) {
        cp = fourBytesCodePoint(
          bytes.concat(_b[i], _b[i + 1], _b[i + 2], _b[i + 3])
        );

        if ((cp < 0x10000) && (cp > 0x10FFFF)) return false;

        i += 4;
        continue;
      }

      // invalid
      return false;
    }

    return true;
  }

  /// @notice Decode the next UTF-8 character in `self` given a starting position of `_cursor`
  /// @dev decodeChar is useful for functions want to iterate over the string in one pass and check each category for a condition
  /// @param self The input string
  /// @param _cursor The starting bytes position (inclusive) of the character
  /// @return The next character as a string and the starting position of the next character.
  function decodeChar(string calldata self, uint256 _cursor)
    public
    pure
    returns (string memory, uint256)
  {
    bytes memory _b = bytes(self);
    uint256 len = _b.length;
    bytes memory output;
    uint32 cp;

    require(_cursor < len, "invalid cursor: cursor out of bounds");
    output = bytes.concat(output, _b[_cursor]);
    _cursor++;

    // ASCII
    /* 1 byte sequence: U+0000..U+007F */
    if (isOneBytesSequence(output[0])) return (string(output), _cursor);

    require(_cursor < len, "invalid cursor: cursor out of bounds");
    /* Check continuation bytes: bit 7 should be set, bit 6 should be
     * unset (b10xxxxxx). */
    require(
      !isContinuationByte(_b[_cursor]),
      "only bit 7 should contain a continuation byte"
    );
    output = bytes.concat(output, _b[_cursor]);
    _cursor++;

    /* 0b110xxxxx: 2 bytes sequence */
    /* U+0080..U+07FF */
    if (isTwoBytesSequence(output[0])) {
      cp = twoBytesCodePoint(output);
      require(
        cp >= 0x0080 && cp <= 0x07FF,
        "invalid character: out of two bytes sequence range U+0080..U+07FF"
      );

      return (string(output), _cursor);
    }

    require(_cursor < len, "invalid cursor: cursor out of bounds");
    /* Check continuation bytes: bit 7 should be set, bit 6 should be
     * unset (b10xxxxxx). */
    require(
      !isContinuationByte(_b[_cursor]),
      "only bit 7 should contain a continuation byte"
    );
    output = bytes.concat(output, _b[_cursor]);
    _cursor++;

    /* 0b1110xxxx: 3 bytes sequence */
    /* 3 bytes sequence: U+0800..U+FFFF */
    if (isThreeBytesSequence(output[0])) {
      cp = threeBytesCodePoint(output);
      /* threeBytesCodePoint(cp) will always be <= 0xFFFF */
      require(
        cp >= 0x0800,
        "invalid character: out of three bytes sequence range U+0800..U+FFFF"
      );

      /* surrogates (U+D800-U+DFFF) are invalid in UTF-8:
               test if (0xD800 <= cp && cp <= 0xDFFF) */
      require((cp >> 11) != 0x1b, "surrogates are invalid in UTF-8");

      return (string(output), _cursor);
    }

    require(_cursor < len, "invalid cursor: cursor out of bounds");
    /* Check continuation bytes: bit 7 (left-most) should be set, bit 6 should be
     * unset (b10xxxxxx). */
    require(
      !isContinuationByte(_b[_cursor]),
      "only bit 7 should contain a continuation byte"
    );
    output = bytes.concat(output, _b[_cursor]);
    _cursor++;

    /* 0b11110xxx: 4 bytes sequence */
    /* 4 bytes sequence: U+10000..U+10FFFF */
    if (isFourBytesSequence(output[0])) {
      cp = fourBytesCodePoint(output);

      require(
        (cp >= 0x10000) && (cp <= 0x10FFFF),
        "invalid character: out of four bytes sequence range  U+10000..U+10FFFF"
      );

      return (string(output), _cursor);
    }

    require(false, "invalid utf8");
    return ("", 0);
  }

  /// @notice Decode every UTF-8 characters in `self`
  /// @param self The input string
  /// @return An ordered array of all UTF-8 characters  in `self`
  function decode(string calldata self)
    external
    pure
    returns (string[] memory)
  {
    // The charaters array must be initialized to a fixed size.
    // Loop over the string to get the number of charcters before decoding.
    uint256 size = length(self);
    string[] memory characters = new string[](size);

    string memory char;
    uint256 cursor = 0;
    uint256 len = bytes(self).length;
    uint256 idx;

    while (cursor < len) {
      (char, cursor) = decodeChar(self, cursor);
      characters[idx] = char;
      idx++;
    }

    return characters;
  }

  /// @notice Get the UTF-8 character at `_idx` for `self`
  /// @dev charAt will error if the idx is out of bounds
  /// @param self The input string
  /// @param _idx The index of the character to get
  /// @return The character at the given index
  function charAt(string calldata self, uint256 _idx)
    public
    pure
    returns (string memory)
  {
    string memory char;
    uint256 len = bytes(self).length;
    uint256 cursor;

    for (uint256 i = 0; i <= _idx; i++) {
      (char, cursor) = decodeChar(self, cursor);
      // if we hit the end, it must be the _idx
      require(cursor < len || i == _idx, "index out of bounds");
    }

    return char;
  }

  /// @notice Get the Unicode code point at `_idx` for `self`
  /// @dev codePointAt requires a valid UTF-8 string
  /// @param self The input string
  /// @param _idx The index of the code point to get
  /// @return The Unicode code point at the given index
  function codePointAt(string calldata self, uint256 _idx)
    external
    pure
    returns (uint32)
  {
    return toCodePoint(charAt(self, _idx));
  }

  /// @notice The return value of indexOf and bytesIndicesOf if the character is not found
  /// @dev Use CHAR_NOT_FOUND to check if indexOf or bytesIndicesOf does not find the inputted character
  uint256 public constant CHAR_NOT_FOUND = type(uint256).max;

  /// @notice Get the character index of `_of` in string `self`
  /// @dev indexOf returns CHAR_NOT_FOUND if `_of` isn't found in `self`
  /// @param self The input string
  /// @param _of The character to find the index of
  /// @return The index of the character in the given string
  function indexOf(string calldata self, string calldata _of)
    external
    pure
    returns (uint256)
  {
    string memory char;
    uint256 cursor = 0;
    uint256 len = bytes(self).length;
    uint256 idx;

    while (cursor < len) {
      (char, cursor) = decodeChar(self, cursor);
      if (keccak256(bytes(char)) == keccak256(bytes(_of))) return idx;
      idx++;
    }

    return CHAR_NOT_FOUND;
  }

  /// @notice Get the starting (inclusive) and ending (exclusive) bytes indices of character `_of` in string `self`
  /// @dev bytesIndicesOf returns (CHAR_NOT_FOUND, CHAR_NOT_FOUND) if `_of` isn't found in `self`
  /// @param self The input string
  /// @param _of The character to find the bytes indices of
  /// @return The starting (inclusive) and ending (exclusive) indites the character in the bytes underlying the string
  function bytesIndicesOf(string calldata self, string calldata _of)
    external
    pure
    returns (uint256, uint256)
  {
    string memory char;
    uint256 start;
    uint256 cursor = 0;
    uint256 len = bytes(self).length;

    while (cursor < len) {
      // start is the prev cursor before the character
      start = cursor;
      (char, cursor) = decodeChar(self, cursor);
      if (keccak256(bytes(char)) == keccak256(bytes(_of)))
        return (start, cursor);
    }

    return (CHAR_NOT_FOUND, CHAR_NOT_FOUND);
  }
}