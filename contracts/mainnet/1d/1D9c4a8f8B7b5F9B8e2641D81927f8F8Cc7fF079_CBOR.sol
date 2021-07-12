/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

// File: contracts/BufferLib.sol
/**
 * @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
 * @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
 * start with the byte that goes right after the last one in the previous read.
 * @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
 * theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
 */
library BufferLib {
  struct Buffer {
    bytes data;
    uint32 cursor;
  }

  // Ensures we access an existing index in an array
  modifier notOutOfBounds(uint32 index, uint256 length) {
    require(index < length, "Tried to read from a consumed Buffer (must rewind it first)");
    _;
  }

  /**
  * @notice Read and consume a certain amount of bytes from the buffer.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @param _length How many bytes to read and consume from the buffer.
  * @return A `bytes memory` containing the first `_length` bytes from the buffer, counting from the cursor position.
  */
  function read(Buffer memory _buffer, uint32 _length) internal pure returns (bytes memory) {
    // Make sure not to read out of the bounds of the original bytes
    require(_buffer.cursor + _length <= _buffer.data.length, "Not enough bytes in buffer when reading");

    // Create a new `bytes memory destination` value
    bytes memory destination = new bytes(_length);

    // Early return in case that bytes length is 0
    if (_length != 0) {
      bytes memory source = _buffer.data;
      uint32 offset = _buffer.cursor;

      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(source, 32), offset)
        destinationPointer := add(destination, 32)
      }
      // Copy `_length` bytes from source to destination
      memcpy(destinationPointer, sourcePointer, uint(_length));

      // Move the cursor forward by `_length` bytes
      seek(_buffer, _length, true);
    }

    return destination;
  }

  /**
  * @notice Read and consume the next byte from the buffer.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The next byte in the buffer counting from the cursor position.
  */
  function next(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (bytes1) {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return _buffer.data[_buffer.cursor++];
  }

  /**
  * @notice Move the inner cursor of the buffer to a relative or absolute position.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @param _offset How many bytes to move the cursor forward.
  * @param _relative Whether to count `_offset` from the last position of the cursor (`true`) or the beginning of the
  * buffer (`true`).
  * @return The final position of the cursor (will equal `_offset` if `_relative` is `false`).
  */
  // solium-disable-next-line security/no-assign-params
  function seek(Buffer memory _buffer, uint32 _offset, bool _relative) internal pure returns (uint32) {
    // Deal with relative offsets
    if (_relative) {
      require(_offset + _buffer.cursor > _offset, "Integer overflow when seeking");
      _offset += _buffer.cursor;
    }
    // Make sure not to read out of the bounds of the original bytes
    require(_offset <= _buffer.data.length, "Not enough bytes in buffer when seeking");
    _buffer.cursor = _offset;
    return _buffer.cursor;
  }

  /**
  * @notice Move the inner cursor a number of bytes forward.
  * @dev This is a simple wrapper around the relative offset case of `seek()`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @param _relativeOffset How many bytes to move the cursor forward.
  * @return The final position of the cursor.
  */
  function seek(Buffer memory _buffer, uint32 _relativeOffset) internal pure returns (uint32) {
    return seek(_buffer, _relativeOffset, true);
  }

  /**
  * @notice Move the inner cursor back to the first byte in the buffer.
  * @param _buffer An instance of `BufferLib.Buffer`.
  */
  function rewind(Buffer memory _buffer) internal pure {
    _buffer.cursor = 0;
  }

  /**
  * @notice Read and consume the next byte from the buffer as an `uint8`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint8` value of the next byte in the buffer counting from the cursor position.
  */
  function readUint8(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (uint8) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint8 value;
    assembly {
      value := mload(add(add(bytesValue, 1), offset))
    }
    _buffer.cursor++;

    return value;
  }

  /**
  * @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  */
  function readUint16(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 1, _buffer.data.length) returns (uint16) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint16 value;
    assembly {
      value := mload(add(add(bytesValue, 2), offset))
    }
    _buffer.cursor += 2;

    return value;
  }

  /**
  * @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  */
  function readUint32(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 3, _buffer.data.length) returns (uint32) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint32 value;
    assembly {
      value := mload(add(add(bytesValue, 4), offset))
    }
    _buffer.cursor += 4;

    return value;
  }

  /**
  * @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  */
  function readUint64(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 7, _buffer.data.length) returns (uint64) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint64 value;
    assembly {
      value := mload(add(add(bytesValue, 8), offset))
    }
    _buffer.cursor += 8;

    return value;
  }

  /**
  * @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  */
  function readUint128(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 15, _buffer.data.length) returns (uint128) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint128 value;
    assembly {
      value := mload(add(add(bytesValue, 16), offset))
    }
    _buffer.cursor += 16;

    return value;
  }

  /**
  * @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  * @return The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  * @param _buffer An instance of `BufferLib.Buffer`.
  */
  function readUint256(Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 31, _buffer.data.length) returns (uint256) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint256 value;
    assembly {
      value := mload(add(add(bytesValue, 32), offset))
    }
    _buffer.cursor += 32;

    return value;
  }

  /**
  * @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  * `int32`.
  * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  * use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  * expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  * @param _buffer An instance of `BufferLib.Buffer`.
  * @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  */
  function readFloat16(Buffer memory _buffer) internal pure returns (int32) {
    uint32 bytesValue = readUint16(_buffer);
    // Get bit at position 0
    uint32 sign = bytesValue & 0x8000;
    // Get bits 1 to 5, then normalize to the [-14, 15] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(bytesValue & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 significand = int32(bytesValue & 0x03ff);

    // Add 1024 to the fraction if the exponent is 0
    if (exponent == 15) {
      significand |= 0x400;
    }

    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    int32 result = 0;
    if (exponent >= 0) {
      result = int32((int256(1 << uint256(int256(exponent))) * 10000 * int256(uint256(int256(significand)) | 0x400)) >> 10);
    } else {
      result = int32(((int256(uint256(int256(significand)) | 0x400) * 10000) / int256(1 << uint256(int256(- exponent)))) >> 10);
    }

    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= - 1;
    }
    return result;
  }

  /**
  * @notice Copy bytes from one memory address into another.
  * @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  * of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  * @param _dest Address of the destination memory.
  * @param _src Address to the source memory.
  * @param _len How many bytes to copy.
  */
  // solium-disable-next-line security/no-assign-params
  function memcpy(uint _dest, uint _src, uint _len) private pure {
    require(_len > 0, "Cannot copy 0 bytes");

    // Copy word-length chunks while possible
    for (; _len >= 32; _len -= 32) {
      assembly {
        mstore(_dest, mload(_src))
      }
      _dest += 32;
      _src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - _len) - 1;
    assembly {
      let srcpart := and(mload(_src), not(mask))
      let destpart := and(mload(_dest), mask)
      mstore(_dest, or(destpart, srcpart))
    }
  }

}
// File: contracts/CBOR.sol
/**
 * @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
 * @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
 * the gas cost of decoding them into a useful native type.
 * @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
 * TODO: add support for Array (majorType = 4)
 * TODO: add support for Map (majorType = 5)
 * TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
 * TODO: add support for Float64 (majorType = 7, additionalInformation = 27)
 */
library CBOR {
  using BufferLib for BufferLib.Buffer;

  uint32 constant internal UINT32_MAX = type(uint32).max;

  uint64 constant internal UINT64_MAX = type(uint64).max;

  struct Value {
    BufferLib.Buffer buffer;
    uint8 initialByte;
    uint8 majorType;
    uint8 additionalInformation;
    uint64 len;
    uint64 tag;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `bool` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `bool` value.
   */
  function decodeBool(Value memory _cborValue) public pure returns(bool) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(_cborValue.majorType == 7, "Tried to read a `bool` value from a `CBOR.Value` with majorType != 7");
    if (_cborValue.len == 20) {
      return false;
    } else if (_cborValue.len == 21) {
      return true;
    } else {
      revert("Tried to read `bool` from a `CBOR.Value` with len different than 20 or 21");
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `bytes` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `bytes` value.
   */
  function decodeBytes(Value memory _cborValue) public pure returns(bytes memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == UINT32_MAX) {
      bytes memory bytesData;

      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
      if (itemLength < UINT32_MAX) {
        bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
        if (itemLength < UINT32_MAX) {
          bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        }
      }
      return bytesData;
    } else {
      return _cborValue.buffer.read(uint32(_cborValue.len));
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a `fixed16` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeFixed16(Value memory _cborValue) public pure returns(int32) {
    require(_cborValue.majorType == 7, "Tried to read a `fixed` value from a `CBOR.Value` with majorType != 7");
    require(_cborValue.additionalInformation == 25, "Tried to read `fixed16` from a `CBOR.Value` with additionalInformation != 25");
    return _cborValue.buffer.readFloat16();
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128[]` value whose inner values follow the same convention.
   * as explained in `decodeFixed16`.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeFixed16Array(Value memory _cborValue) external pure returns(int32[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int32[] memory array = new int32[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeFixed16(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeInt128(Value memory _cborValue) public pure returns(int128) {
    if (_cborValue.majorType == 1) {
      uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
      return int128(-1) - int128(uint128(length));
    } else if (_cborValue.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int128(uint128(decodeUint64(_cborValue)));
    }
    revert("Tried to read `int128` from a `CBOR.Value` with majorType not 0 or 1");
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeInt128Array(Value memory _cborValue) external pure returns(int128[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int128[] memory array = new int128[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeInt128(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `string` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `string` value.
   */
  function decodeString(Value memory _cborValue) public pure returns(string memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == UINT64_MAX) {
      bytes memory textData;
      bool done;
      while (!done) {
        uint64 itemLength = readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType);
        if (itemLength < UINT64_MAX) {
          textData = abi.encodePacked(textData, readText(_cborValue.buffer, itemLength / 4));
        } else {
          done = true;
        }
      }
      return string(textData);
    } else {
      return string(readText(_cborValue.buffer, _cborValue.len));
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `string[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `string[]` value.
   */
  function decodeStringArray(Value memory _cborValue) external pure returns(string[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `string[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    string[] memory array = new string[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeString(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `uint64` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `uint64` value.
   */
  function decodeUint64(Value memory _cborValue) public pure returns(uint64) {
    require(_cborValue.majorType == 0, "Tried to read `uint64` from a `CBOR.Value` with majorType != 0");
    return readLength(_cborValue.buffer, _cborValue.additionalInformation);
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `uint64[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `uint64[]` value.
   */
  function decodeUint64Array(Value memory _cborValue) external pure returns(uint64[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `uint64[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    uint64[] memory array = new uint64[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeUint64(item);
    }

    return array;
  }

  /**
   * @notice Decode a CBOR.Value structure from raw bytes.
   * @dev This is the main factory for CBOR.Value instances, which can be later decoded into native EVM types.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `CBOR.Value` instance containing a partially decoded value.
   */
  function valueFromBytes(bytes memory _cborBytes) external pure returns(Value memory) {
    BufferLib.Buffer memory buffer = BufferLib.Buffer(_cborBytes, 0);

    return valueFromBuffer(buffer);
  }

  /**
   * @notice Decode a CBOR.Value structure from raw bytes.
   * @dev This is an alternate factory for CBOR.Value instances, which can be later decoded into native EVM types.
   * @param _buffer A Buffer structure representing a CBOR-encoded value.
   * @return A `CBOR.Value` instance containing a partially decoded value.
   */
  function valueFromBuffer(BufferLib.Buffer memory _buffer) public pure returns(Value memory) {
    require(_buffer.data.length > 0, "Found empty buffer when parsing CBOR value");

    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;

    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = _buffer.readUint8();
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;

      // Early CBOR tag parsing.
      if (majorType == 6) {
        tag = readLength(_buffer, additionalInformation);
      } else {
        isTagged = false;
      }
    }

    require(majorType <= 7, "Invalid CBOR major type");

    return CBOR.Value(
      _buffer,
      initialByte,
      majorType,
      additionalInformation,
      0,
      tag);
  }

  // Reads the length of the next CBOR item from a buffer, consuming a different number of bytes depending on the
  // value of the `additionalInformation` argument.
  function readLength(BufferLib.Buffer memory _buffer, uint8 additionalInformation) private pure returns(uint64) {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return _buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return _buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return _buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return _buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert("Invalid length encoding (non-existent additionalInformation value)");
  }

  // Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  // as many bytes as specified by the first byte.
  function readIndefiniteStringLength(BufferLib.Buffer memory _buffer, uint8 majorType) private pure returns(uint64) {
    uint8 initialByte = _buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    uint64 length = readLength(_buffer, initialByte & 0x1f);
    require(length < UINT64_MAX && (initialByte >> 5) == majorType, "Invalid indefinite length");
    return length;
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  // but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(BufferLib.Buffer memory _buffer, uint64 _length) private pure returns(bytes memory) {
    bytes memory result;
    for (uint64 index = 0; index < _length; index++) {
      uint8 value = _buffer.readUint8();
      if (value & 0x80 != 0) {
        if (value < 0xe0) {
          value = (value & 0x1f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 1;
        } else if (value < 0xf0) {
          value = (value & 0x0f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 2;
        } else {
          value = (value & 0x0f) << 18 |
            (_buffer.readUint8() & 0x3f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6  |
            (_buffer.readUint8() & 0x3f);
          _length -= 3;
        }
      }
      result = abi.encodePacked(result, value);
    }
    return result;
  }
}
// File: contracts/Request.sol
/**
 * @title The serialized form of a Witnet data request
 */
contract Request {
  bytes public bytecode;

 /**
  * @dev A `Request` is constructed around a `bytes memory` value containing a well-formed Witnet data request serialized
  * using Protocol Buffers. However, we cannot verify its validity at this point. This implies that contracts using
  * the WRB should not be considered trustless before a valid Proof-of-Inclusion has been posted for the requests.
  * The hash of the request is computed in the constructor to guarantee consistency. Otherwise there could be a
  * mismatch and a data request could be resolved with the result of another.
  * @param _bytecode Witnet request in bytes.
  */
  constructor(bytes memory _bytecode) {
    bytecode = _bytecode;
  }
}
// File: contracts/Witnet.sol
/**
 * @title A library for decoding Witnet request results
 * @notice The library exposes functions to check the Witnet request success.
 * and retrieve Witnet results from CBOR values into solidity types.
 */
library Witnet {
  using CBOR for CBOR.Value;

  /*
   *  STRUCTS
   */
  struct Result {
    bool success;
    CBOR.Value cborValue;
  }

  /*
   *  ENUMS
   */
  enum ErrorCodes {
    // 0x00: Unknown error. Something went really bad!
    Unknown,
    // Script format errors
    /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
    SourceScriptNotCBOR,
    /// 0x02: The CBOR value decoded from a source script is not an Array.
    SourceScriptNotArray,
    /// 0x03: The Array value decoded form a source script is not a valid RADON script.
    SourceScriptNotRADON,
    /// Unallocated
    ScriptFormat0x04,
    ScriptFormat0x05,
    ScriptFormat0x06,
    ScriptFormat0x07,
    ScriptFormat0x08,
    ScriptFormat0x09,
    ScriptFormat0x0A,
    ScriptFormat0x0B,
    ScriptFormat0x0C,
    ScriptFormat0x0D,
    ScriptFormat0x0E,
    ScriptFormat0x0F,
    // Complexity errors
    /// 0x10: The request contains too many sources.
    RequestTooManySources,
    /// 0x11: The script contains too many calls.
    ScriptTooManyCalls,
    /// Unallocated
    Complexity0x12,
    Complexity0x13,
    Complexity0x14,
    Complexity0x15,
    Complexity0x16,
    Complexity0x17,
    Complexity0x18,
    Complexity0x19,
    Complexity0x1A,
    Complexity0x1B,
    Complexity0x1C,
    Complexity0x1D,
    Complexity0x1E,
    Complexity0x1F,
    // Operator errors
    /// 0x20: The operator does not exist.
    UnsupportedOperator,
    /// Unallocated
    Operator0x21,
    Operator0x22,
    Operator0x23,
    Operator0x24,
    Operator0x25,
    Operator0x26,
    Operator0x27,
    Operator0x28,
    Operator0x29,
    Operator0x2A,
    Operator0x2B,
    Operator0x2C,
    Operator0x2D,
    Operator0x2E,
    Operator0x2F,
    // Retrieval-specific errors
    /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
    HTTP,
    /// 0x31: Retrieval of at least one of the sources timed out.
    RetrievalTimeout,
    /// Unallocated
    Retrieval0x32,
    Retrieval0x33,
    Retrieval0x34,
    Retrieval0x35,
    Retrieval0x36,
    Retrieval0x37,
    Retrieval0x38,
    Retrieval0x39,
    Retrieval0x3A,
    Retrieval0x3B,
    Retrieval0x3C,
    Retrieval0x3D,
    Retrieval0x3E,
    Retrieval0x3F,
    // Math errors
    /// 0x40: Math operator caused an underflow.
    Underflow,
    /// 0x41: Math operator caused an overflow.
    Overflow,
    /// 0x42: Tried to divide by zero.
    DivisionByZero,
    /// Unallocated
    Math0x43,
    Math0x44,
    Math0x45,
    Math0x46,
    Math0x47,
    Math0x48,
    Math0x49,
    Math0x4A,
    Math0x4B,
    Math0x4C,
    Math0x4D,
    Math0x4E,
    Math0x4F,
    // Other errors
    /// 0x50: Received zero reveals
    NoReveals,
    /// 0x51: Insufficient consensus in tally precondition clause
    InsufficientConsensus,
    /// 0x52: Received zero commits
    InsufficientCommits,
    /// 0x53: Generic error during tally execution
    TallyExecution,
    /// Unallocated
    OtherError0x54,
    OtherError0x55,
    OtherError0x56,
    OtherError0x57,
    OtherError0x58,
    OtherError0x59,
    OtherError0x5A,
    OtherError0x5B,
    OtherError0x5C,
    OtherError0x5D,
    OtherError0x5E,
    OtherError0x5F,
    /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
    MalformedReveal,
    /// Unallocated
    OtherError0x61,
    OtherError0x62,
    OtherError0x63,
    OtherError0x64,
    OtherError0x65,
    OtherError0x66,
    OtherError0x67,
    OtherError0x68,
    OtherError0x69,
    OtherError0x6A,
    OtherError0x6B,
    OtherError0x6C,
    OtherError0x6D,
    OtherError0x6E,
    OtherError0x6F,
    // Access errors
    /// 0x70: Tried to access a value from an index using an index that is out of bounds
    ArrayIndexOutOfBounds,
    /// 0x71: Tried to access a value from a map using a key that does not exist
    MapKeyNotFound,
    /// Unallocated
    OtherError0x72,
    OtherError0x73,
    OtherError0x74,
    OtherError0x75,
    OtherError0x76,
    OtherError0x77,
    OtherError0x78,
    OtherError0x79,
    OtherError0x7A,
    OtherError0x7B,
    OtherError0x7C,
    OtherError0x7D,
    OtherError0x7E,
    OtherError0x7F,
    OtherError0x80,
    OtherError0x81,
    OtherError0x82,
    OtherError0x83,
    OtherError0x84,
    OtherError0x85,
    OtherError0x86,
    OtherError0x87,
    OtherError0x88,
    OtherError0x89,
    OtherError0x8A,
    OtherError0x8B,
    OtherError0x8C,
    OtherError0x8D,
    OtherError0x8E,
    OtherError0x8F,
    OtherError0x90,
    OtherError0x91,
    OtherError0x92,
    OtherError0x93,
    OtherError0x94,
    OtherError0x95,
    OtherError0x96,
    OtherError0x97,
    OtherError0x98,
    OtherError0x99,
    OtherError0x9A,
    OtherError0x9B,
    OtherError0x9C,
    OtherError0x9D,
    OtherError0x9E,
    OtherError0x9F,
    OtherError0xA0,
    OtherError0xA1,
    OtherError0xA2,
    OtherError0xA3,
    OtherError0xA4,
    OtherError0xA5,
    OtherError0xA6,
    OtherError0xA7,
    OtherError0xA8,
    OtherError0xA9,
    OtherError0xAA,
    OtherError0xAB,
    OtherError0xAC,
    OtherError0xAD,
    OtherError0xAE,
    OtherError0xAF,
    OtherError0xB0,
    OtherError0xB1,
    OtherError0xB2,
    OtherError0xB3,
    OtherError0xB4,
    OtherError0xB5,
    OtherError0xB6,
    OtherError0xB7,
    OtherError0xB8,
    OtherError0xB9,
    OtherError0xBA,
    OtherError0xBB,
    OtherError0xBC,
    OtherError0xBD,
    OtherError0xBE,
    OtherError0xBF,
    OtherError0xC0,
    OtherError0xC1,
    OtherError0xC2,
    OtherError0xC3,
    OtherError0xC4,
    OtherError0xC5,
    OtherError0xC6,
    OtherError0xC7,
    OtherError0xC8,
    OtherError0xC9,
    OtherError0xCA,
    OtherError0xCB,
    OtherError0xCC,
    OtherError0xCD,
    OtherError0xCE,
    OtherError0xCF,
    OtherError0xD0,
    OtherError0xD1,
    OtherError0xD2,
    OtherError0xD3,
    OtherError0xD4,
    OtherError0xD5,
    OtherError0xD6,
    OtherError0xD7,
    OtherError0xD8,
    OtherError0xD9,
    OtherError0xDA,
    OtherError0xDB,
    OtherError0xDC,
    OtherError0xDD,
    OtherError0xDE,
    OtherError0xDF,
    // Bridge errors: errors that only belong in inter-client communication
    /// 0xE0: Requests that cannot be parsed must always get this error as their result.
    /// However, this is not a valid result in a Tally transaction, because invalid requests
    /// are never included into blocks and therefore never get a Tally in response.
    BridgeMalformedRequest,
    /// 0xE1: Witnesses exceeds 100
    BridgePoorIncentives,
    /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
    /// amount of value that is unjustifiably high when compared with the reward they will be getting
    BridgeOversizedResult,
    /// Unallocated
    OtherError0xE3,
    OtherError0xE4,
    OtherError0xE5,
    OtherError0xE6,
    OtherError0xE7,
    OtherError0xE8,
    OtherError0xE9,
    OtherError0xEA,
    OtherError0xEB,
    OtherError0xEC,
    OtherError0xED,
    OtherError0xEE,
    OtherError0xEF,
    OtherError0xF0,
    OtherError0xF1,
    OtherError0xF2,
    OtherError0xF3,
    OtherError0xF4,
    OtherError0xF5,
    OtherError0xF6,
    OtherError0xF7,
    OtherError0xF8,
    OtherError0xF9,
    OtherError0xFA,
    OtherError0xFB,
    OtherError0xFC,
    OtherError0xFD,
    OtherError0xFE,
    // This should not exist:
    /// 0xFF: Some tally error is not intercepted but should
    UnhandledIntercept
  }

  /*
   * Result impl's
   */

  /**
   * @notice Decode raw CBOR bytes into a Result instance.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `Result` instance.
   */
  function resultFromCborBytes(bytes calldata _cborBytes) external pure returns(Result memory) {
    CBOR.Value memory cborValue = CBOR.valueFromBytes(_cborBytes);
    return resultFromCborValue(cborValue);
  }

  /**
   * @notice Decode a CBOR value into a Result instance.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return A `Result` instance.
   */
  function resultFromCborValue(CBOR.Value memory _cborValue) public pure returns(Result memory) {
    // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
    // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
    bool success = _cborValue.tag != 39;
    return Result(success, _cborValue);
  }

  /**
   * @notice Tell if a Result is successful.
   * @param _result An instance of Result.
   * @return `true` if successful, `false` if errored.
   */
  function isOk(Result memory _result) external pure returns(bool) {
    return _result.success;
  }

  /**
   * @notice Tell if a Result is errored.
   * @param _result An instance of Result.
   * @return `true` if errored, `false` if successful.
   */
  function isError(Result memory _result) external pure returns(bool) {
    return !_result.success;
  }

  /**
   * @notice Decode a bytes value from a Result as a `bytes` value.
   * @param _result An instance of Result.
   * @return The `bytes` decoded from the Result.
   */
  function asBytes(Result memory _result) external pure returns(bytes memory) {
    require(_result.success, "Tried to read bytes value from errored Result");
    return _result.cborValue.decodeBytes();
  }

  /**
   * @notice Decode an error code from a Result as a member of `ErrorCodes`.
   * @param _result An instance of `Result`.
   * @return The `CBORValue.Error memory` decoded from the Result.
   */
  function asErrorCode(Result memory _result) external pure returns(ErrorCodes) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return ErrorCodes.Unknown;
    }

    return supportedErrorOrElseUnknown(error[0]);
  }

  /**
   * @notice Generate a suitable error message for a member of `ErrorCodes` and its corresponding arguments.
   * @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
   * @param _result An instance of `Result`.
   * @return A tuple containing the `CBORValue.Error memory` decoded from the `Result`, plus a loggable error message.
   */

  function asErrorMessage(Result memory _result) public pure returns (ErrorCodes, string memory) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return (ErrorCodes.Unknown, "Unknown error (no error code)");
    }
    ErrorCodes errorCode = supportedErrorOrElseUnknown(error[0]);
    bytes memory errorMessage;

    if (errorCode == ErrorCodes.SourceScriptNotCBOR && error.length >= 2) {
        errorMessage = abi.encodePacked("Source script #", utoa(error[1]), " was not a valid CBOR value");
    } else if (errorCode == ErrorCodes.SourceScriptNotArray && error.length >= 2) {
        errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not an Array of calls");
    } else if (errorCode == ErrorCodes.SourceScriptNotRADON && error.length >= 2) {
        errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not a valid RADON script");
    } else if (errorCode == ErrorCodes.RequestTooManySources && error.length >= 2) {
        errorMessage = abi.encodePacked("The request contained too many sources (", utoa(error[1]), ")");
    } else if (errorCode == ErrorCodes.ScriptTooManyCalls && error.length >= 4) {
        errorMessage = abi.encodePacked(
          "Script #",
          utoa(error[2]),
          " from the ",
          stageName(error[1]),
          " stage contained too many calls (",
          utoa(error[3]),
          ")"
        );
    } else if (errorCode == ErrorCodes.UnsupportedOperator && error.length >= 5) {
        errorMessage = abi.encodePacked(
        "Operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage is not supported"
        );
    } else if (errorCode == ErrorCodes.HTTP && error.length >= 3) {
        errorMessage = abi.encodePacked(
          "Source #",
          utoa(error[1]),
          " could not be retrieved. Failed with HTTP error code: ",
          utoa(error[2] / 100),
          utoa(error[2] % 100 / 10),
          utoa(error[2] % 10)
        );
    } else if (errorCode == ErrorCodes.RetrievalTimeout && error.length >= 2) {
        errorMessage = abi.encodePacked(
          "Source #",
          utoa(error[1]),
          " could not be retrieved because of a timeout."
        );
    } else if (errorCode == ErrorCodes.Underflow && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Underflow at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == ErrorCodes.Overflow && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Overflow at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == ErrorCodes.DivisionByZero && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Division by zero at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == ErrorCodes.BridgeMalformedRequest) {
        errorMessage = "The structure of the request is invalid and it cannot be parsed";
    } else if (errorCode == ErrorCodes.BridgePoorIncentives) {
        errorMessage = "The request has been rejected by the bridge node due to poor incentives";
    } else if (errorCode == ErrorCodes.BridgeOversizedResult) {
        errorMessage = "The request result length exceeds a bridge contract defined limit";
    } else {
        errorMessage = abi.encodePacked("Unknown error (0x", utohex(error[0]), ")");
    }

    return (errorCode, string(errorMessage));
  }

  /**
   * @notice Decode a raw error from a `Result` as a `uint64[]`.
   * @param _result An instance of `Result`.
   * @return The `uint64[]` raw error as decoded from the `Result`.
   */
  function asRawError(Result memory _result) public pure returns(uint64[] memory) {
    require(!_result.success, "Tried to read error code from successful Result");
    return _result.cborValue.decodeUint64Array();
  }

  /**
   * @notice Decode a boolean value from a Result as an `bool` value.
   * @param _result An instance of Result.
   * @return The `bool` decoded from the Result.
   */
  function asBool(Result memory _result) external pure returns(bool) {
    require(_result.success, "Tried to read `bool` value from errored Result");
    return _result.cborValue.decodeBool();
  }

  /**
   * @notice Decode a fixed16 (half-precision) numeric value from a Result as an `int32` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _result An instance of Result.
   * @return The `int128` decoded from the Result.
   */
  function asFixed16(Result memory _result) external pure returns(int32) {
    require(_result.success, "Tried to read `fixed16` value from errored Result");
    return _result.cborValue.decodeFixed16();
  }

  /**
   * @notice Decode an array of fixed16 values from a Result as an `int128[]` value.
   * @param _result An instance of Result.
   * @return The `int128[]` decoded from the Result.
   */
  function asFixed16Array(Result memory _result) external pure returns(int32[] memory) {
    require(_result.success, "Tried to read `fixed16[]` value from errored Result");
    return _result.cborValue.decodeFixed16Array();
  }

  /**
   * @notice Decode a integer numeric value from a Result as an `int128` value.
   * @param _result An instance of Result.
   * @return The `int128` decoded from the Result.
   */
  function asInt128(Result memory _result) external pure returns(int128) {
    require(_result.success, "Tried to read `int128` value from errored Result");
    return _result.cborValue.decodeInt128();
  }

  /**
   * @notice Decode an array of integer numeric values from a Result as an `int128[]` value.
   * @param _result An instance of Result.
   * @return The `int128[]` decoded from the Result.
   */
  function asInt128Array(Result memory _result) external pure returns(int128[] memory) {
    require(_result.success, "Tried to read `int128[]` value from errored Result");
    return _result.cborValue.decodeInt128Array();
  }

  /**
   * @notice Decode a string value from a Result as a `string` value.
   * @param _result An instance of Result.
   * @return The `string` decoded from the Result.
   */
  function asString(Result memory _result) external pure returns(string memory) {
    require(_result.success, "Tried to read `string` value from errored Result");
    return _result.cborValue.decodeString();
  }

  /**
   * @notice Decode an array of string values from a Result as a `string[]` value.
   * @param _result An instance of Result.
   * @return The `string[]` decoded from the Result.
   */
  function asStringArray(Result memory _result) external pure returns(string[] memory) {
    require(_result.success, "Tried to read `string[]` value from errored Result");
    return _result.cborValue.decodeStringArray();
  }

  /**
   * @notice Decode a natural numeric value from a Result as a `uint64` value.
   * @param _result An instance of Result.
   * @return The `uint64` decoded from the Result.
   */
  function asUint64(Result memory _result) external pure returns(uint64) {
    require(_result.success, "Tried to read `uint64` value from errored Result");
    return _result.cborValue.decodeUint64();
  }

  /**
   * @notice Decode an array of natural numeric values from a Result as a `uint64[]` value.
   * @param _result An instance of Result.
   * @return The `uint64[]` decoded from the Result.
   */
  function asUint64Array(Result memory _result) external pure returns(uint64[] memory) {
    require(_result.success, "Tried to read `uint64[]` value from errored Result");
    return _result.cborValue.decodeUint64Array();
  }

  /**
   * @notice Convert a stage index number into the name of the matching Witnet request stage.
   * @param _stageIndex A `uint64` identifying the index of one of the Witnet request stages.
   * @return The name of the matching stage.
   */
  function stageName(uint64 _stageIndex) public pure returns(string memory) {
    if (_stageIndex == 0) {
      return "retrieval";
    } else if (_stageIndex == 1) {
      return "aggregation";
    } else if (_stageIndex == 2) {
      return "tally";
    } else {
      return "unknown";
    }
  }

  /**
   * @notice Get an `ErrorCodes` item from its `uint64` discriminant.
   * @param _discriminant The numeric identifier of an error.
   * @return A member of `ErrorCodes`.
   */
  function supportedErrorOrElseUnknown(uint64 _discriminant) private pure returns(ErrorCodes) {
      return ErrorCodes(_discriminant);
  }

  /**
   * @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
   * three less significant decimal values.
   * @param _u A `uint64` value.
   * @return The `string` representing its decimal value.
   */
  function utoa(uint64 _u) private pure returns(string memory) {
    if (_u < 10) {
      bytes memory b1 = new bytes(1);
      b1[0] = bytes1(uint8(_u) + 48);
      return string(b1);
    } else if (_u < 100) {
      bytes memory b2 = new bytes(2);
      b2[0] = bytes1(uint8(_u / 10) + 48);
      b2[1] = bytes1(uint8(_u % 10) + 48);
      return string(b2);
    } else {
      bytes memory b3 = new bytes(3);
      b3[0] = bytes1(uint8(_u / 100) + 48);
      b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
      b3[2] = bytes1(uint8(_u % 10) + 48);
      return string(b3);
    }
  }

  /**
   * @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
   * @param _u A `uint64` value.
   * @return The `string` representing its hexadecimal value.
   */
  function utohex(uint64 _u) private pure returns(string memory) {
    bytes memory b2 = new bytes(2);
    uint8 d0 = uint8(_u / 16) + 48;
    uint8 d1 = uint8(_u % 16) + 48;
    if (d0 > 57)
      d0 += 7;
    if (d1 > 57)
      d1 += 7;
    b2[0] = bytes1(d0);
    b2[1] = bytes1(d1);
    return string(b2);
  }
}
// File: contracts/WitnetRequestBoardInterface.sol
/**
 * @title Witnet Requests Board Interface
 * @notice Interface of a Witnet Request Board (WRB)
 * It defines how to interact with the WRB in order to support:
 *  - Post and upgrade a data request
 *  - Read the result of a dr
 * @author Witnet Foundation
 */
interface WitnetRequestBoardInterface {

  // Event emitted when a new DR is posted
  event PostedRequest(uint256 _id);

  // Event emitted when a result is reported
  event PostedResult(uint256 _id);

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns(uint256);

  /// @dev Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable;

  /// @dev Retrieves the DR transaction hash of the id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DR transaction
  function readDrTxHash (uint256 _id) external view returns(uint256);

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult (uint256 _id) external view returns(bytes memory);

  /// @notice Verifies if the Witnet Request Board can be upgraded.
  /// @return true if contract is upgradable.
  function isUpgradable(address _address) external view returns(bool);

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the rewards.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns(uint256);
}
// File: contracts/UsingWitnet.sol
/**
 * @title The UsingWitnet contract
 * @notice Contract writers can inherit this contract in order to create Witnet data requests.
 */
abstract contract UsingWitnet {
  using Witnet for Witnet.Result;

  WitnetRequestBoardInterface internal immutable wrb;

 /**
  * @notice Include an address to specify the WitnetRequestBoard.
  * @param _wrb WitnetRequestBoard address.
  */
  constructor(address _wrb) {
    wrb = WitnetRequestBoardInterface(_wrb);
  }

  // Provides a convenient way for client contracts extending this to block the execution of the main logic of the
  // contract until a particular request has been successfully resolved by Witnet
  modifier witnetRequestResolved(uint256 _id) {
    require(witnetCheckRequestResolved(_id), "Witnet request is not yet resolved by the Witnet network");
    _;
  }

 /**
  * @notice Send a new request to the Witnet network with transaction value as result report reward.
  * @dev Call to `post_dr` function in the WitnetRequestBoard contract.
  * @param _request An instance of the `Request` contract.
  * @return Sequencial identifier for the request included in the WitnetRequestBoard.
  */
  function witnetPostRequest(Request _request) internal returns (uint256) {
    return wrb.postDataRequest{value: msg.value}(address(_request));
  }

 /**
  * @notice Check if a request has been resolved by Witnet.
  * @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
  * parties) before this method returns `true`.
  * @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
  * @return A boolean telling if the request has been already resolved or not.
  */
  function witnetCheckRequestResolved(uint256 _id) internal view returns (bool) {
    // If the result of the data request in Witnet is not the default, then it means that it has been reported as resolved.
    return wrb.readDrTxHash(_id) != 0;
  }

 /**
  * @notice Upgrade the reward for a Data Request previously included.
  * @dev Call to `upgrade_dr` function in the WitnetRequestBoard contract.
  * @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
  */
  function witnetUpgradeRequest(uint256 _id) internal {
    wrb.upgradeDataRequest{value: msg.value}(_id);
  }

 /**
  * @notice Read the result of a resolved request.
  * @dev Call to `read_result` function in the WitnetRequestBoard contract.
  * @param _id The unique identifier of a request that was posted to Witnet.
  * @return The result of the request as an instance of `Result`.
  */
  function witnetReadResult(uint256 _id) internal view returns (Witnet.Result memory) {
    return Witnet.resultFromCborBytes(wrb.readResult(_id));
  }

 /**
  * @notice Estimate the reward amount.
  * @dev Call to `estimate_gas_cost` function in the WitnetRequestBoard contract.
  * @param _gasPrice The gas price for which we want to retrieve the estimation.
  * @return The reward to be included for the given gas price.
  */
  function witnetEstimateGasCost(uint256 _gasPrice) internal view returns (uint256) {
    return wrb.estimateGasCost(_gasPrice);
  }
}
// File: contracts/WitnetRequestBoardProxy.sol
/**
 * @title Witnet Request Board Proxy
 * @notice Contract to act as a proxy between the Witnet Bridge Interface and Contracts inheriting UsingWitnet.
 * @author Witnet Foundation
 */
contract WitnetRequestBoardProxy {

  // Struct if the information of each controller
  struct ControllerInfo {
    // Address of the Controller
    address controllerAddress;
    // The lastId of the previous Controller
    uint256 lastId;
  }

  // Witnet Request Board contract that is currently being used
  WitnetRequestBoardInterface public currentWitnetRequestBoard;

  // Last id of the WRB controller
  uint256 internal currentLastId;

  // Array with the controllers that have been used in the Proxy
  ControllerInfo[] internal controllers;

  modifier notIdentical(address _newAddress) {
    require(_newAddress != address(currentWitnetRequestBoard), "The provided Witnet Requests Board instance address is already in use");
    _;
  }

 /**
  * @notice Include an address to specify the Witnet Request Board.
  * @param _witnetRequestBoardAddress WitnetRequestBoard address.
  */
  constructor(address _witnetRequestBoardAddress) {
    // Initialize the first epoch pointing to the first controller
    controllers.push(ControllerInfo({controllerAddress: _witnetRequestBoardAddress, lastId: 0}));
    currentWitnetRequestBoard = WitnetRequestBoardInterface(_witnetRequestBoardAddress);
  }

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns(uint256) {
    uint256 n = controllers.length;
    uint256 offset = controllers[n - 1].lastId;
    // Update the currentLastId with the id in the controller plus the offSet
    currentLastId = currentWitnetRequestBoard.postDataRequest{value: msg.value}(_requestAddress) + offset;
    return currentLastId;
  }

  /// @dev Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable {
    address wrbAddress;
    uint256 wrbOffset;
    (wrbAddress, wrbOffset) = getController(_id);
    return currentWitnetRequestBoard.upgradeDataRequest{value: msg.value}(_id - wrbOffset);
  }

  /// @dev Retrieves the DR transaction hash of the id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The transaction hash of the DR.
  function readDrTxHash (uint256 _id)
    external
    view
  returns(uint256)
  {
    // Get the address and the offset of the corresponding to id
    (address wrbAddress, uint256 offsetWrb) = getController(_id);
    // Return the result of the DR readed in the corresponding Controller with its own id
    uint256 drTxHash = WitnetRequestBoardInterface(wrbAddress).readDrTxHash(_id - offsetWrb);
    return drTxHash;
  }

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR.
  function readResult(uint256 _id) external view returns(bytes memory) {
    // Get the address and the offset of the corresponding to id
    address wrbAddress;
    uint256 offSetWrb;
    (wrbAddress, offSetWrb) = getController(_id);
    // Return the result of the DR in the corresponding Controller with its own id
    WitnetRequestBoardInterface wrbWithResult;
    wrbWithResult = WitnetRequestBoardInterface(wrbAddress);
    return wrbWithResult.readResult(_id - offSetWrb);
  }

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the reward.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns(uint256) {
    return currentWitnetRequestBoard.estimateGasCost(_gasPrice);
  }

  /// @notice Upgrades the Witnet Requests Board if the current one is upgradeable.
  /// @param _newAddress address of the new block relay to upgrade.
  function upgradeWitnetRequestBoard(address _newAddress) external notIdentical(_newAddress) {
    // Require the WRB is upgradable
    require(currentWitnetRequestBoard.isUpgradable(msg.sender), "The upgrade has been rejected by the current implementation");
    // Map the currentLastId to the corresponding witnetRequestBoardAddress and add it to controllers
    controllers.push(ControllerInfo({controllerAddress: _newAddress, lastId: currentLastId}));
    // Upgrade the WRB
    currentWitnetRequestBoard = WitnetRequestBoardInterface(_newAddress);
  }

  /// @notice Gets the controller from an Id.
  /// @param _id id of a Data Request from which we get the controller.
  function getController(uint256 _id) internal view returns(address _controllerAddress, uint256 _offset) {
    // Check id is bigger than 0
    require(_id > 0, "Non-existent controller for id 0");

    uint256 n = controllers.length;
    // If the id is bigger than the lastId of a Controller, read the result in that Controller
    for (uint i = n; i > 0; i--) {
      if (_id > controllers[i - 1].lastId) {
        return (controllers[i - 1].controllerAddress, controllers[i - 1].lastId);
      }
    }
  }

}
// File: contracts/WitnetRequestBoard.sol
/**
 * @title Witnet Requests Board mocked
 * @notice Contract to bridge requests to Witnet for testing purposes.
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
 * The result of the requests will be posted back to this contract by the bridge nodes too.
 * @author Witnet Foundation
 */
contract WitnetRequestBoard is WitnetRequestBoardInterface {
    // TODO: update max report result gas value
    uint256 public constant ESTIMATED_REPORT_RESULT_GAS = 102496;

    struct DataRequest {
        address requestAddress;
        uint256 drOutputHash;
        uint256 reward;
        uint256 gasPrice;
        bytes result;
        uint256 drTxHash;
    }

    // Owner of the Witnet Request Board
    address public owner;

    // Map of addresses to a bool, true if they are committee members
    mapping(address => bool) public isInCommittee;

    // Witnet Requests within the board
    DataRequest[] public requests;

    // Only the committee defined when deploying the contract should be able to report results
    modifier isAuthorized() {
        require(isInCommittee[msg.sender] == true, "Sender not authorized");
        _;
    }

    // Ensures the result has not been reported yet
    modifier resultNotIncluded(uint256 _id) {
        require(requests[_id].result.length == 0, "Result already included");
        _;
    }

    // Ensures the request has not been manipulated
    modifier validDrOutputHash(uint256 _id) {
        require(
            requests[_id].drOutputHash ==
                computeDrOutputHash(Request(requests[_id].requestAddress).bytecode()),
            "The dr has been manipulated and the bytecode has changed"
        );
        _;
    }

    // Ensures the request id exists
    modifier validId(uint256 _id) {
        require(requests.length > _id, "Id not found");
        _;
    }

    /// @notice Initilizes a centralized Witnet Request Board with an authorized committee.
    /// @param _committee list of authorized addresses.
    constructor(address[] memory _committee) {
        owner = msg.sender;
        for (uint256 i = 0; i < _committee.length; i++) {
            isInCommittee[_committee[i]] = true;
        }
        // Insert an empty request so as to initialize the requests array with length > 0
        DataRequest memory request;
        requests.push(request);
    }

    /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
    /// @param _requestAddress The request contract address which includes the request bytecode.
    /// @return The unique identifier of the data request.
    function postDataRequest(address _requestAddress)
        external
        payable
        override
        returns (uint256)
    {
        // Checks the tally reward is covering gas cost
        uint256 minResultReward = tx.gasprice * ESTIMATED_REPORT_RESULT_GAS;
        require(
            msg.value >= minResultReward,
            "Result reward should cover gas expenses. Check the estimateGasCost method."
        );

        uint256 _id = requests.length;

        DataRequest memory request;
        request.requestAddress = _requestAddress;
        request.reward = msg.value;
        Request requestContract = Request(request.requestAddress);
        request.drOutputHash = computeDrOutputHash(requestContract.bytecode());
        request.gasPrice = tx.gasprice;
        // Push the new request into the contract state
        requests.push(request);

        // Let observers know that a new request has been posted
        emit PostedRequest(_id);

        return _id;
    }

    /// @dev Increments the reward of a data request by adding the transaction value to it.
    /// @param _id The unique identifier of the data request.
    function upgradeDataRequest(uint256 _id)
        external
        payable
        override
        resultNotIncluded(_id)
    {
        uint256 newReward = requests[_id].reward + msg.value;

        // If gas price is increased, then check if new rewards cover gas costs
        if (tx.gasprice > requests[_id].gasPrice) {
            // Checks the reward is covering gas cost
            uint256 minResultReward = tx.gasprice * ESTIMATED_REPORT_RESULT_GAS;
            require(
                newReward >= minResultReward,
                "Result reward should cover gas expenses. Check the estimateGasCost method."
            );
            requests[_id].gasPrice = tx.gasprice;
        }

        // Update data request reward
        requests[_id].reward = newReward;
    }

    /// @dev Reports the result of a data request in Witnet.
    /// @param _id The unique identifier of the data request.
    /// @param _drTxHash The unique hash of the request.
    /// @param _result The result itself as bytes.
    function reportResult(
        uint256 _id,
        uint256 _drTxHash,
        bytes calldata _result
    ) external isAuthorized() validId(_id) resultNotIncluded(_id) {
        require(_drTxHash != 0, "Data request transaction cannot be zero");
        // Ensures the result byes do not have zero length
        // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
        require(_result.length != 0, "Result has zero length");

        requests[_id].drTxHash = _drTxHash;
        requests[_id].result = _result;

        emit PostedResult(_id);
        payable(msg.sender).transfer(requests[_id].reward);
    }

    /// @dev Retrieves the bytes of the serialization of one data request from the WRB.
    /// @param _id The unique identifier of the data request.
    /// @return The result of the data request as bytes.
    function readDataRequest(uint256 _id)
        external
        view
        validId(_id)
        validDrOutputHash(_id)
        returns (bytes memory)
    {
        Request requestContract = Request(requests[_id].requestAddress);
        return requestContract.bytecode();
    }

    /// @dev Retrieves the result (if already available) of one data request from the WRB.
    /// @param _id The unique identifier of the data request.
    /// @return The result of the DR.
    function readResult(uint256 _id)
        external
        view
        override
        validId(_id)
        returns (bytes memory)
    {
        require(requests[_id].drTxHash != 0, "The request has not yet been resolved");
        return requests[_id].result;
    }

    /// @dev Retrieves the gas price set for a specific DR ID.
    /// @param _id The unique identifier of the data request.
    /// @return The gas price set by the request creator.
    function readGasPrice(uint256 _id)
        external
        view
        validId(_id)
        returns (uint256)
    {
        return requests[_id].gasPrice;
    }

    /// @dev Retrieves hash of the data request transaction in Witnet.
    /// @param _id The unique identifier of the data request.
    /// @return The hash of the DataRequest transaction in Witnet.
    function readDrTxHash(uint256 _id)
        external
        view
        override
        validId(_id)
        returns (uint256)
    {
        return requests[_id].drTxHash;
    }

    /// @dev Returns the number of data requests in the WRB.
    /// @return the number of data requests in the WRB.
    function requestsCount() external view returns (uint256) {
        return requests.length;
    }

    /// @dev Verifies if the contract is upgradable.
    /// @return true if the contract upgradable.
    function isUpgradable(address _address)
        external
        view
        override
        returns (bool)
    {
        if (_address == owner) {
            return true;
        }
        return false;
    }

    /// @dev Estimate the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the reward.
    /// @return The reward to be included for the given gas price.
    function estimateGasCost(uint256 _gasPrice)
        external
        pure
        override
        returns (uint256)
    {
        return _gasPrice * ESTIMATED_REPORT_RESULT_GAS;
    }
    
    /// @dev Computes the output hash of a request from its bytecode.
    /// @param _bytecode The bytecode of the request.
    /// @return The output hash of the request.
    function computeDrOutputHash(bytes memory _bytecode)
        public
        pure
        returns (uint256)
    {
        return uint256(sha256(_bytecode));
    }
}