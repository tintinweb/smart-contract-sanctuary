/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

// File: contracts\libs\WitnetData.sol
/**
 * @title Contract containing the serialized bytecode of a Witnet Radon script.
 */
contract WitnetRequest {
    bytes public bytecode;

  /**
    * @dev A `WitnetRequest` is constructed around a `bytes memory` value containing a well-formed Witnet data request serialized
    * using Protocol Buffers. However, we cannot verify its validity at this point. This implies that contracts using
    * the WRB should not be considered trustless before a valid Proof-of-Inclusion has been posted for the requests.
    * The hash of the request is computed in the constructor to guarantee consistency. Otherwise there could be a
    * mismatch and a data request could be resolved with the result of another.
    * @param _bytecode Actual Radon script in bytes.
    */
    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
    }
}

library WitnetData {

    /// Witnet lambda function that computes the hash of a CBOR-encoded RADON script.
    /// @param _bytecode CBOR-encoded RADON.
    function computeScriptCodehash(bytes memory _bytecode) internal pure returns (uint256) {
        return uint256(sha256(_bytecode));
    }

    /// @notice Data kept in EVM-storage for every Data Request (DR) posted to Witnet.
    struct Query {
        address requestor;  // Address from which the DR was posted.
        address script;     // WitnetRequest contract address.        
        uint256 codehash;   // Codehash of the DR.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // escrow reward to by paid to the DR resolver.
        uint256 txhash;     // Hash of the Witnet tx that actually solved the DR.
    }

    /// @notice DR result data provided by Witnet.
    struct Result {
        bool success;       // Resolution was successful.
        CBOR value;         // Resulting value encoded as a Concise Binary Object Representation (CBOR).
    }

    /// @notice Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// @notice Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// @notice Witnet error codes table.
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
}
// File: contracts\libs\BufferLib.sol
/**
 * @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
 * @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
 * start with the byte that goes right after the last one in the previous read.
 * @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
 * theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
 */
library BufferLib {
  // Ensures we access an existing index in an array
  modifier notOutOfBounds(uint32 index, uint256 length) {
    require(index < length, "Tried to read from a consumed Buffer (must rewind it first)");
    _;
  }

  /**
  * @notice Read and consume a certain amount of bytes from the buffer.
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @param _length How many bytes to read and consume from the buffer.
  * @return A `bytes memory` containing the first `_length` bytes from the buffer, counting from the cursor position.
  */
  function read(WitnetData.Buffer memory _buffer, uint32 _length) internal pure returns (bytes memory) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The next byte in the buffer counting from the cursor position.
  */
  function next(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (bytes1) {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return _buffer.data[_buffer.cursor++];
  }

  /**
  * @notice Move the inner cursor of the buffer to a relative or absolute position.
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @param _offset How many bytes to move the cursor forward.
  * @param _relative Whether to count `_offset` from the last position of the cursor (`true`) or the beginning of the
  * buffer (`true`).
  * @return The final position of the cursor (will equal `_offset` if `_relative` is `false`).
  */
  // solium-disable-next-line security/no-assign-params
  function seek(WitnetData.Buffer memory _buffer, uint32 _offset, bool _relative) internal pure returns (uint32) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @param _relativeOffset How many bytes to move the cursor forward.
  * @return The final position of the cursor.
  */
  function seek(WitnetData.Buffer memory _buffer, uint32 _relativeOffset) internal pure returns (uint32) {
    return seek(_buffer, _relativeOffset, true);
  }

  /**
  * @notice Move the inner cursor back to the first byte in the buffer.
  * @param _buffer An instance of `WitnetData.Buffer`.
  */
  function rewind(WitnetData.Buffer memory _buffer) internal pure {
    _buffer.cursor = 0;
  }

  /**
  * @notice Read and consume the next byte from the buffer as an `uint8`.
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint8` value of the next byte in the buffer counting from the cursor position.
  */
  function readUint8(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (uint8) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  */
  function readUint16(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 1, _buffer.data.length) returns (uint16) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  */
  function readUint32(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 3, _buffer.data.length) returns (uint32) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  */
  function readUint64(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 7, _buffer.data.length) returns (uint64) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  */
  function readUint128(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 15, _buffer.data.length) returns (uint128) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  */
  function readUint256(WitnetData.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 31, _buffer.data.length) returns (uint256) {
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
  * @param _buffer An instance of `WitnetData.Buffer`.
  * @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  */
  function readFloat16(WitnetData.Buffer memory _buffer) internal pure returns (int32) {
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
// File: contracts\libs\CBOR.sol
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
  using BufferLib for WitnetData.Buffer;

  uint32 constant internal UINT32_MAX = type(uint32).max;
  uint64 constant internal UINT64_MAX = type(uint64).max;

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `bool` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as a `bool` value.
   */
  function decodeBool(WitnetData.CBOR memory _cborValue) public pure returns(bool) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(_cborValue.majorType == 7, "Tried to read a `bool` value from a `WitnetData.CBOR` with majorType != 7");
    if (_cborValue.len == 20) {
      return false;
    } else if (_cborValue.len == 21) {
      return true;
    } else {
      revert("Tried to read `bool` from a `WitnetData.CBOR` with len different than 20 or 21");
    }
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `bytes` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as a `bytes` value.
   */
  function decodeBytes(WitnetData.CBOR memory _cborValue) public pure returns(bytes memory) {
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
   * @notice Decode a `WitnetData.CBOR` structure into a `fixed16` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeFixed16(WitnetData.CBOR memory _cborValue) public pure returns(int32) {
    require(_cborValue.majorType == 7, "Tried to read a `fixed` value from a `WT.CBOR` with majorType != 7");
    require(_cborValue.additionalInformation == 25, "Tried to read `fixed16` from a `WT.CBOR` with additionalInformation != 25");
    return _cborValue.buffer.readFloat16();
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `int128[]` value whose inner values follow the same convention.
   * as explained in `decodeFixed16`.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeFixed16Array(WitnetData.CBOR memory _cborValue) external pure returns(int32[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `WitnetData.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int32[] memory array = new int32[](length);
    for (uint64 i = 0; i < length; i++) {
      WitnetData.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeFixed16(item);
    }

    return array;
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `int128` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeInt128(WitnetData.CBOR memory _cborValue) public pure returns(int128) {
    if (_cborValue.majorType == 1) {
      uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
      return int128(-1) - int128(uint128(length));
    } else if (_cborValue.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int128(uint128(decodeUint64(_cborValue)));
    }
    revert("Tried to read `int128` from a `WitnetData.CBOR` with majorType not 0 or 1");
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `int128[]` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeInt128Array(WitnetData.CBOR memory _cborValue) external pure returns(int128[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `WitnetData.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int128[] memory array = new int128[](length);
    for (uint64 i = 0; i < length; i++) {
      WitnetData.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeInt128(item);
    }

    return array;
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `string` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as a `string` value.
   */
  function decodeString(WitnetData.CBOR memory _cborValue) public pure returns(string memory) {
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
   * @notice Decode a `WitnetData.CBOR` structure into a native `string[]` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `string[]` value.
   */
  function decodeStringArray(WitnetData.CBOR memory _cborValue) external pure returns(string[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `string[]` from a `WitnetData.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    string[] memory array = new string[](length);
    for (uint64 i = 0; i < length; i++) {
      WitnetData.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeString(item);
    }

    return array;
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `uint64` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `uint64` value.
   */
  function decodeUint64(WitnetData.CBOR memory _cborValue) public pure returns(uint64) {
    require(_cborValue.majorType == 0, "Tried to read `uint64` from a `WitnetData.CBOR` with majorType != 0");
    return readLength(_cborValue.buffer, _cborValue.additionalInformation);
  }

  /**
   * @notice Decode a `WitnetData.CBOR` structure into a native `uint64[]` value.
   * @param _cborValue An instance of `WitnetData.CBOR`.
   * @return The value represented by the input, as an `uint64[]` value.
   */
  function decodeUint64Array(WitnetData.CBOR memory _cborValue) external pure returns(uint64[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `uint64[]` from a `WitnetData.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    uint64[] memory array = new uint64[](length);
    for (uint64 i = 0; i < length; i++) {
      WitnetData.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeUint64(item);
    }

    return array;
  }

  /**
   * @notice Decode a WitnetData.CBOR structure from raw bytes.
   * @dev This is the main factory for WitnetData.CBOR instances, which can be later decoded into native EVM types.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `WitnetData.CBOR` instance containing a partially decoded value.
   */
  function valueFromBytes(bytes memory _cborBytes) external pure returns(WitnetData.CBOR memory) {
    WitnetData.Buffer memory buffer = WitnetData.Buffer(_cborBytes, 0);

    return valueFromBuffer(buffer);
  }

  /**
   * @notice Decode a WitnetData.CBOR structure from raw bytes.
   * @dev This is an alternate factory for WitnetData.CBOR instances, which can be later decoded into native EVM types.
   * @param _buffer A Buffer structure representing a CBOR-encoded value.
   * @return A `WitnetData.CBOR` instance containing a partially decoded value.
   */
  function valueFromBuffer(WitnetData.Buffer memory _buffer) public pure returns(WitnetData.CBOR memory) {
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

    return WitnetData.CBOR(
      _buffer,
      initialByte,
      majorType,
      additionalInformation,
      0,
      tag);
  }

  // Reads the length of the next CBOR item from a buffer, consuming a different number of bytes depending on the
  // value of the `additionalInformation` argument.
  function readLength(WitnetData.Buffer memory _buffer, uint8 additionalInformation) private pure returns(uint64) {
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
  function readIndefiniteStringLength(WitnetData.Buffer memory _buffer, uint8 majorType) private pure returns(uint64) {
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
  function readText(WitnetData.Buffer memory _buffer, uint64 _length) private pure returns(bytes memory) {
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