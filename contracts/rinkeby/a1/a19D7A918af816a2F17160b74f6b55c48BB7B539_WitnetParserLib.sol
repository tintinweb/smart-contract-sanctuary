/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

// File: contracts\interfaces\IWitnetRequest.sol
/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function codehash() external view returns (bytes32);
}
// File: contracts\libs\Witnet.sol
library Witnet {

    /// @notice Witnet lambda function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function computeCodehash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requestor;      // Address from which the request was posted.
        bytes32 codehash;       // Codehash of the Data Request which execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // escrow reward to by paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // EVM-provided timestamp in which the result was reported. 
        bytes32 proof;          // Witnet-provided validation proof of the reported result.
        uint256 epoch;          // Witnet epoch in which the reported result was actually finalized.        
        Result  result;         // Witnet-provided result to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
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
// File: contracts\libs\WitnetBuffer.sol
/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  // Ensures we access an existing index in an array
  modifier notOutOfBounds(uint32 index, uint256 length) {
    require(index < length, "Tried to read from a consumed Buffer (must rewind it first)");
    _;
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _length How many bytes to read and consume from the buffer.
  /// @return A `bytes memory` containing the first `_length` bytes from the buffer, counting from the cursor position.
  function read(Witnet.Buffer memory _buffer, uint32 _length) internal pure returns (bytes memory) {
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

  /// @notice Read and consume the next byte from the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (bytes1) {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return _buffer.data[_buffer.cursor++];
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _offset How many bytes to move the cursor forward.
  /// @param _relative Whether to count `_offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `_offset` if `_relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(Witnet.Buffer memory _buffer, uint32 _offset, bool _relative) internal pure returns (uint32) {
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

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(Witnet.Buffer memory _buffer, uint32 _relativeOffset) internal pure returns (uint32) {
    return seek(_buffer, _relativeOffset, true);
  }

  /// @notice Move the inner cursor back to the first byte in the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  function rewind(Witnet.Buffer memory _buffer) internal pure {
    _buffer.cursor = 0;
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (uint8) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint8 value;
    assembly {
      value := mload(add(add(bytesValue, 1), offset))
    }
    _buffer.cursor++;

    return value;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 1, _buffer.data.length) returns (uint16) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint16 value;
    assembly {
      value := mload(add(add(bytesValue, 2), offset))
    }
    _buffer.cursor += 2;

    return value;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 3, _buffer.data.length) returns (uint32) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint32 value;
    assembly {
      value := mload(add(add(bytesValue, 4), offset))
    }
    _buffer.cursor += 4;

    return value;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 7, _buffer.data.length) returns (uint64) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint64 value;
    assembly {
      value := mload(add(add(bytesValue, 8), offset))
    }
    _buffer.cursor += 8;

    return value;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 15, _buffer.data.length) returns (uint128) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint128 value;
    assembly {
      value := mload(add(add(bytesValue, 16), offset))
    }
    _buffer.cursor += 16;

    return value;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @return The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  /// @param _buffer An instance of `Witnet.Buffer`.
  function readUint256(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 31, _buffer.data.length) returns (uint256) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint256 value;
    assembly {
      value := mload(add(add(bytesValue, 32), offset))
    }
    _buffer.cursor += 32;

    return value;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Witnet.Buffer memory _buffer) internal pure returns (int32) {
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

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param _dest Address of the destination memory.
  /// @param _src Address to the source memory.
  /// @param _len How many bytes to copy.
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
// File: contracts\libs\WitnetDecoderLib.sol
/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.
/// 
/// TODO: add support for Array (majorType = 4)
/// TODO: add support for Map (majorType = 5)
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

library WitnetDecoderLib {

  using WitnetBuffer for Witnet.Buffer;

  uint32 constant internal _UINT32_MAX = type(uint32).max;
  uint64 constant internal _UINT64_MAX = type(uint64).max;

  /// @notice Decode a `Witnet.CBOR` structure into a native `bool` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function decodeBool(Witnet.CBOR memory _cborValue) public pure returns(bool) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(_cborValue.majorType == 7, "Tried to read a `bool` value from a `Witnet.CBOR` with majorType != 7");
    if (_cborValue.len == 20) {
      return false;
    } else if (_cborValue.len == 21) {
      return true;
    } else {
      revert("Tried to read `bool` from a `Witnet.CBOR` with len different than 20 or 21");
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `bytes` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `bytes` value.   
  function decodeBytes(Witnet.CBOR memory _cborValue) public pure returns(bytes memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == _UINT32_MAX) {
      bytes memory bytesData;

      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
      if (itemLength < _UINT32_MAX) {
        bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
        if (itemLength < _UINT32_MAX) {
          bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        }
      }
      return bytesData;
    } else {
      return _cborValue.buffer.read(uint32(_cborValue.len));
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function decodeFixed16(Witnet.CBOR memory _cborValue) public pure returns(int32) {
    require(_cborValue.majorType == 7, "Tried to read a `fixed` value from a `WT.CBOR` with majorType != 7");
    require(_cborValue.additionalInformation == 25, "Tried to read `fixed16` from a `WT.CBOR` with additionalInformation != 25");
    return _cborValue.buffer.readFloat16();
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128[]` value whose inner values follow the same convention.
  /// as explained in `decodeFixed16`.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128[]` value.
  function decodeFixed16Array(Witnet.CBOR memory _cborValue) external pure returns(int32[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int32[] memory array = new int32[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeFixed16(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function decodeInt128(Witnet.CBOR memory _cborValue) public pure returns(int128) {
    if (_cborValue.majorType == 1) {
      uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
      return int128(-1) - int128(uint128(length));
    } else if (_cborValue.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int128(uint128(decodeUint64(_cborValue)));
    }
    revert("Tried to read `int128` from a `Witnet.CBOR` with majorType not 0 or 1");
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128[]` value.
  function decodeInt128Array(Witnet.CBOR memory _cborValue) external pure returns(int128[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int128[] memory array = new int128[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeInt128(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `string` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `string` value.
  function decodeString(Witnet.CBOR memory _cborValue) public pure returns(string memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == _UINT64_MAX) {
      bytes memory textData;
      bool done;
      while (!done) {
        uint64 itemLength = readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType);
        if (itemLength < _UINT64_MAX) {
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

  /// @notice Decode a `Witnet.CBOR` structure into a native `string[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `string[]` value.
  function decodeStringArray(Witnet.CBOR memory _cborValue) external pure returns(string[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `string[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    string[] memory array = new string[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeString(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `uint64` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function decodeUint64(Witnet.CBOR memory _cborValue) public pure returns(uint64) {
    require(_cborValue.majorType == 0, "Tried to read `uint64` from a `Witnet.CBOR` with majorType != 0");
    return readLength(_cborValue.buffer, _cborValue.additionalInformation);
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `uint64[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `uint64[]` value.
  function decodeUint64Array(Witnet.CBOR memory _cborValue) external pure returns(uint64[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `uint64[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    uint64[] memory array = new uint64[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeUint64(item);
    }

    return array;
  }

  /// @notice Decode a Witnet.CBOR structure from raw bytes.
  /// @dev This is the main factory for Witnet.CBOR instances, which can be later decoded into native EVM types.
  /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
  /// @return A `Witnet.CBOR` instance containing a partially decoded value.
  function valueFromBytes(bytes memory _cborBytes) external pure returns(Witnet.CBOR memory) {
    Witnet.Buffer memory buffer = Witnet.Buffer(_cborBytes, 0);

    return valueFromBuffer(buffer);
  }

  /// @notice Decode a Witnet.CBOR structure from raw bytes.
  /// @dev This is an alternate factory for Witnet.CBOR instances, which can be later decoded into native EVM types.
  /// @param _buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `Witnet.CBOR` instance containing a partially decoded value.
  function valueFromBuffer(Witnet.Buffer memory _buffer) public pure returns(Witnet.CBOR memory) {
    require(_buffer.data.length > 0, "Found empty buffer when parsing CBOR value");

    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = _UINT64_MAX;

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

    return Witnet.CBOR(
      _buffer,
      initialByte,
      majorType,
      additionalInformation,
      0,
      tag);
  }

  /// Reads the length of the next CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(Witnet.Buffer memory _buffer, uint8 additionalInformation) private pure returns(uint64) {
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
      return _UINT64_MAX;
    }
    revert("Invalid length encoding (non-existent additionalInformation value)");
  }

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function readIndefiniteStringLength(Witnet.Buffer memory _buffer, uint8 majorType) private pure returns(uint64) {
    uint8 initialByte = _buffer.readUint8();
    if (initialByte == 0xff) {
      return _UINT64_MAX;
    }
    uint64 length = readLength(_buffer, initialByte & 0x1f);
    require(length < _UINT64_MAX && (initialByte >> 5) == majorType, "Invalid indefinite length");
    return length;
  }

  /// Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(Witnet.Buffer memory _buffer, uint64 _length) private pure returns(bytes memory) {
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
// File: contracts\libs\WitnetParserLib.sol
/// @title A library for decoding Witnet request results
/// @notice The library exposes functions to check the Witnet request success.
/// and retrieve Witnet results from CBOR values into solidity types.
/// @author The Witnet Foundation.
library WitnetParserLib {

    using WitnetDecoderLib for bytes;
    using WitnetDecoderLib for Witnet.CBOR;

    /// @notice Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes calldata _cborBytes)
        external pure
        returns (Witnet.Result memory)
    {
        Witnet.CBOR memory cborValue = _cborBytes.valueFromBytes();
        return resultFromCborValue(cborValue);
    }

    /// @notice Decode a CBOR value into a Witnet.Result instance.
    /// @param _cborValue An instance of `Witnet.Value`.
    /// @return A `Witnet.Result` instance.
    function resultFromCborValue(Witnet.CBOR memory _cborValue)
        public pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = _cborValue.tag != 39;
        return Witnet.Result(success, _cborValue);
    }

    /// @notice Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result)
        external pure
        returns (bool)
    {
        return _result.success;
    }

    /// @notice Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result)
      external pure
      returns (bool)
    {
        return !_result.success;
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result)
        external pure
        returns(bytes memory)
    {
        require(_result.success, "WitnetParserLib: tried to read bytes value from errored Witnet.Result");
        return _result.value.decodeBytes();
    }

    /// @notice Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result)
        external pure
        returns (Witnet.ErrorCodes)
    {
        uint64[] memory error = asRawError(_result);
        if (error.length == 0) {
            return Witnet.ErrorCodes.Unknown;
        }
        return _supportedErrorOrElseUnknown(error[0]);
    }

    /// @notice Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result)
      public pure
      returns (Witnet.ErrorCodes, string memory)
    {
        uint64[] memory error = asRawError(_result);
        if (error.length == 0) {
            return (Witnet.ErrorCodes.Unknown, "Unknown error (no error code)");
        }
        Witnet.ErrorCodes errorCode = _supportedErrorOrElseUnknown(error[0]);
        bytes memory errorMessage;

        if (errorCode == Witnet.ErrorCodes.SourceScriptNotCBOR && error.length >= 2) {
            errorMessage = abi.encodePacked("Source script #", _utoa(error[1]), " was not a valid CBOR value");
        } else if (errorCode == Witnet.ErrorCodes.SourceScriptNotArray && error.length >= 2) {
            errorMessage = abi.encodePacked("The CBOR value in script #", _utoa(error[1]), " was not an Array of calls");
        } else if (errorCode == Witnet.ErrorCodes.SourceScriptNotRADON && error.length >= 2) {
            errorMessage = abi.encodePacked("The CBOR value in script #", _utoa(error[1]), " was not a valid Data Request");
        } else if (errorCode == Witnet.ErrorCodes.RequestTooManySources && error.length >= 2) {
            errorMessage = abi.encodePacked("The request contained too many sources (", _utoa(error[1]), ")");
        } else if (errorCode == Witnet.ErrorCodes.ScriptTooManyCalls && error.length >= 4) {
            errorMessage = abi.encodePacked(
                "Script #",
                _utoa(error[2]),
                " from the ",
                stageName(error[1]),
                " stage contained too many calls (",
                _utoa(error[3]),
                ")"
            );
        } else if (errorCode == Witnet.ErrorCodes.UnsupportedOperator && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Operator code 0x",
                utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage is not supported"
            );
        } else if (errorCode == Witnet.ErrorCodes.HTTP && error.length >= 3) {
            errorMessage = abi.encodePacked(
                "Source #",
                _utoa(error[1]),
                " could not be retrieved. Failed with HTTP error code: ",
                _utoa(error[2] / 100),
                _utoa(error[2] % 100 / 10),
                _utoa(error[2] % 10)
            );
        } else if (errorCode == Witnet.ErrorCodes.RetrievalTimeout && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "Source #",
                _utoa(error[1]),
                " could not be retrieved because of a timeout"
            );
        } else if (errorCode == Witnet.ErrorCodes.Underflow && error.length >= 5) {
              errorMessage = abi.encodePacked(
                "Underflow at operator code 0x",
                utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.Overflow && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Overflow at operator code 0x",
                utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.DivisionByZero && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Division by zero at operator code 0x",
                utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.BridgeMalformedRequest) {
            errorMessage = "The structure of the request is invalid and it cannot be parsed";
        } else if (errorCode == Witnet.ErrorCodes.BridgePoorIncentives) {
            errorMessage = "The request has been rejected by the bridge node due to poor incentives";
        } else if (errorCode == Witnet.ErrorCodes.BridgeOversizedResult) {
            errorMessage = "The request result length exceeds a bridge contract defined limit";
        } else {
            errorMessage = abi.encodePacked("Unknown error (0x", utohex(error[0]), ")");
        }
        return (errorCode, string(errorMessage));
    }

    /// @notice Decode a raw error from a `Witnet.Result` as a `uint64[]`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `uint64[]` raw error as decoded from the `Witnet.Result`.
    function asRawError(Witnet.Result memory _result)
        public pure
        returns(uint64[] memory)
    {
        require(!_result.success, "WitnetParserLib: Tried to read error code from successful Witnet.Result");
        return _result.value.decodeUint64Array();
    }

    /// @notice Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result)
        external pure
        returns (bool)
    {
        require(_result.success, "WitnetParserLib: Tried to read `bool` value from errored Witnet.Result");
        return _result.value.decodeBool();
    }

    /// @notice Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result)
        external pure
        returns (int32)
    {
        require(_result.success, "WitnetParserLib: Tried to read `fixed16` value from errored Witnet.Result");
        return _result.value.decodeFixed16();
    }

    /// @notice Decode an array of fixed16 values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result)
        external pure
        returns (int32[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `fixed16[]` value from errored Witnet.Result");
        return _result.value.decodeFixed16Array();
    }

    /// @notice Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result)
      external pure
      returns (int128)
    {
        require(_result.success, "WitnetParserLib: Tried to read `int128` value from errored Witnet.Result");
        return _result.value.decodeInt128();
    }

    /// @notice Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result)
        external pure
        returns (int128[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `int128[]` value from errored Witnet.Result");
        return _result.value.decodeInt128Array();
    }

    /// @notice Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result)
        external pure
        returns(string memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `string` value from errored Witnet.Result");
        return _result.value.decodeString();
    }

    /// @notice Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result)
        external pure
        returns (string[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `string[]` value from errored Witnet.Result");
        return _result.value.decodeStringArray();
    }

    /// @notice Decode a natural numeric value from a Witnet.Result as a `uint64` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result)
        external pure
        returns(uint64)
    {
        require(_result.success, "WitnetParserLib: Tried to read `uint64` value from errored Witnet.Result");
        return _result.value.decodeUint64();
    }

    /// @notice Decode an array of natural numeric values from a Witnet.Result as a `uint64[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result)
        external pure
        returns (uint64[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `uint64[]` value from errored Witnet.Result");
        return _result.value.decodeUint64Array();
    }

    /// @notice Convert a stage index number into the name of the matching Witnet request stage.
    /// @param _stageIndex A `uint64` identifying the index of one of the Witnet request stages.
    /// @return The name of the matching stage.
    function stageName(uint64 _stageIndex)
        public pure
        returns (string memory)
    {
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

    /// @notice Get an `Witnet.ErrorCodes` item from its `uint64` discriminant.
    /// @param _discriminant The numeric identifier of an error.
    /// @return A member of `Witnet.ErrorCodes`.
    function _supportedErrorOrElseUnknown(uint64 _discriminant)
        private pure
        returns (Witnet.ErrorCodes)
    {
        return Witnet.ErrorCodes(_discriminant);
    }

    /// @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its decimal value.
    function _utoa(uint64 _u)
        private pure
        returns (string memory)
    {
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

    /// @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its hexadecimal value.
    function utohex(uint64 _u)
        private pure
        returns (string memory)
    {
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