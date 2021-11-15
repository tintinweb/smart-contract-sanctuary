// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INamelessTemplateLibrary {
  function getTemplate(uint256 templateIndex) external view returns (bytes32[] memory dataSection, bytes32[] memory codeSection);
  function getContentApis() external view returns (string memory arweaveContentApi, string memory ipfsContentApi);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessToken {
  function initialize(string memory name, string memory symbol, address tokenDataContract, address initialAdmin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessTokenData {
  function initialize (  address templateLibrary, address clonableTokenAddress, address initialAdmin ) external;
  function getTokenURI(uint256 tokenId, address owner) external view returns (string memory);
  function beforeTokenTransfer(address from, address, uint256 tokenId) external returns (bool);
  function getFeeRecipients(uint256) external view returns (address payable[] memory);
  function getFeeBps(uint256) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/BinaryDecoder.sol';
import '../utils/PackedVarArray.sol';


library NamelessDataV1 {
  /*
   * Special Column Types
   */

  uint256 private constant MAX_COLUMN_WORDS = 65535;
  uint256 private constant MAX_CONTENT_LIBRARIES_PER_COLUMN = 256;
  uint256 private constant CONTENT_LIBRARY_SECTION_SIZE = 32 * MAX_CONTENT_LIBRARIES_PER_COLUMN;

  uint256 public constant COLUMN_TYPE_STRING = 1;
  uint256 public constant COLUMN_TYPE_UINT256 = 2;

  /**
    * @dev Returns an `uint256[MAX_COLUMN_WORDS]` located at `slot`.
    */
  function getColumn(bytes32 slot) internal pure returns (bytes32[MAX_COLUMN_WORDS] storage r) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
          r.slot := slot
      }
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function getBufferIndexAndOffset(uint index, uint stride, uint baseOffset) internal pure returns (uint, uint) {
    uint offset = (index * stride) + baseOffset;
    return (offset / 32, offset % 32);
  }

  /*
   * Content Library Column
   *
   * @dev a content library column references content from a secondary data source like arweave of IPFS
   *      this content has been batched into libraries to save space.  Each library is a JSON-encoded
   *      array stored on the secondary data source that provides an indirection to the "real" content.
   *      each content library can hold up to 256 content references and each column can reference 256
   *      libraries. This results in a total of 65536 addressable content hashes while only consuming
   *      2 bytes per distinct token.
   */
  function readContentLibraryColumn(bytes32 columnSlot, uint ordinal) public view returns (
    uint contentLibraryHash,
    uint contentIndex
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(ordinal, 2, CONTENT_LIBRARY_SECTION_SIZE);
    uint row = 0;
    (row, , ) = BinaryDecoder.decodeUint16Aligned(column, bufferIndex, offset);

    uint contentLibraryIndex = row >> 8;
    contentIndex = row & 0xFF;
    contentLibraryHash = uint256(column[contentLibraryIndex]);
  }

  function readDictionaryString(bytes32 dictionarySlot, uint ordinal) public view returns ( string memory ) {
    return PackedVarArray.getString(getColumn(dictionarySlot), ordinal);
  }

  function getDictionaryStringInfo(bytes32 dictionarySlot, uint ordinal) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    return PackedVarArray.getStringInfo(getColumn(dictionarySlot), ordinal);
  }

  function readDictionaryStringLength(bytes32 dictionarySlot, uint ordinal) public view returns ( uint ) {
    return PackedVarArray.getStringLength(getColumn(dictionarySlot), ordinal);
  }

  /*
   * Uint256 Column
   *
   */
  function readUint256Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    return uint256(column[ordinal]);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/StorageSlot.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './NamelessDataV1.sol';
import '../utils/Base64.sol';

library NamelessMetadataURIV1 {
  bytes constant private BASE_64_URL_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  function base64EncodeBuffer(bytes memory buffer, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint outLen = (buffer.length + 2) / 3 * 4 - ((3 - ( buffer.length % 3 )) % 3);

    uint256 i = 0;
    uint256 j = outOffset;

    for (; i + 3 <= buffer.length; i += 3) {
        (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            uint8(buffer[i+2])
        );

        j += 4;
    }

    if ((i + 2) == buffer.length) {
      (output[j], output[j+1], output[j+2], ) = base64Encode3(
          uint8(buffer[i]),
          uint8(buffer[i+1]),
          0
      );
    } else if ((i + 1) == buffer.length) {
      (output[j], output[j+1], , ) = base64Encode3(
          uint8(buffer[i]),
          0,
          0
      );
    }

    return outOffset + outLen;
  }

  function base64Encode(uint256 bigint, bytes memory output, uint outOffset) internal pure returns (uint) {
      bytes32 buffer = bytes32(bigint);

      uint256 i = 0;
      uint256 j = outOffset;

      for (; i + 3 <= 32; i += 3) {
          (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }
      (output[j], output[j+1], output[j+2], ) = base64Encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
      return outOffset + 43;
  }

  function base64Encode3(uint256 a0, uint256 a1, uint256 a2)
      internal
      pure
      returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
  {

      uint256 n = (a0 << 16) | (a1 << 8) | a2;

      uint256 c0 = (n >> 18) & 63;
      uint256 c1 = (n >> 12) & 63;
      uint256 c2 = (n >>  6) & 63;
      uint256 c3 = (n      ) & 63;

      b0 = BASE_64_URL_CHARS[c0];
      b1 = BASE_64_URL_CHARS[c1];
      b2 = BASE_64_URL_CHARS[c2];
      b3 = BASE_64_URL_CHARS[c3];
  }

  bytes constant private BASE_58_CHARS = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function ipfsCidEncode(bytes32 value, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint encodedLen = 0;
    for (uint idx = 0; idx < 34; idx++)
    {
      uint carry = 0;
      if (idx >= 2) {
        carry = uint8(value[idx - 2]);
      } else if (idx == 1) {
        carry = 0x20;
      } else if (idx == 0) {
        carry = 0x12;
      }

      for (uint jdx = 0; jdx < encodedLen; jdx++)
      {
        carry = carry + (uint(uint8(output[outOffset + 45 - jdx])) << 8);
        output[outOffset + 45 - jdx] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
      while (carry > 0) {
        output[outOffset + 45 - encodedLen++] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
    }

    for (uint idx = 0; idx < 46; idx++) {
      output[outOffset + idx] = BASE_58_CHARS[uint8(output[outOffset + idx])];
    }

    return outOffset + 46;
  }


  function writeAddressToString(address addr, bytes memory output, uint outOffset) internal pure returns(uint) {
    bytes32 value = bytes32(uint256(uint160(addr)));
    bytes memory alphabet = '0123456789abcdef';

    output[outOffset++] = '0';
    output[outOffset++] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      output[outOffset + (i*2) ]    = alphabet[uint8(value[i + 12] >> 4)];
      output[outOffset + (i*2) + 1] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    outOffset += 40;
    return outOffset;
  }

  function copyDictionaryString(Context memory context, bytes32 columnSlot, uint256 ordinal) internal view returns (uint) {
    bytes32 curSlot;
    uint offset;
    uint length;
    (curSlot, offset, length) = NamelessDataV1.getDictionaryStringInfo(columnSlot, ordinal);

    bytes32 curBuffer;
    uint remaining = length;
    uint bufferCap = 32 - offset;
    uint outIdx = 0;

    while (outIdx < length) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = offset + copyCount;
      curBuffer = StorageSlot.getBytes32Slot(curSlot).value;

      while( offset < lastOffset) {
        context.output[context.outOffset + outIdx++] = curBuffer[offset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      offset = 0;
      curSlot = bytes32(uint(curSlot) + 1);
    }

    return context.outOffset + outIdx;
  }

  function copyString(Context memory context, string memory value) internal pure returns (uint) {
    for (uint idx = 0; idx < bytes(value).length; idx++) {
      context.output[context.outOffset + idx] = bytes(value)[idx];
    }

    return context.outOffset + bytes(value).length;
  }


  struct Context {
    uint codeBufferIndex;
    uint codeBufferOffset;
    uint256 tokenId;
    address owner;
    string arweaveContentApi;
    string ipfsContentApi;

    uint opsRetired;

    uint outOffset;
    bytes output;
    bool done;
    uint8  stackLength;
    bytes32[0xFF] stack;
  }

  // 4byte opcode to write the bytes32 at the top of the stack to the output raw and consume it
  // byte 1 is the write codepoint,
  // byte 2 is the write format (0 = raw, 1 = hex, 2 = base64),
  // byte 3 is the offset big-endian to start at and
  // byte 4 is the big-endian byte to stop at (non-inclusive)
  function execWrite(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    require(context.stackLength > 0, 'stack underflow');
    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint start = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint end = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (format == 0) {
      bytes32 stackTop = bytes32(context.stack[context.stackLength - 1]);
      for (uint idx = start; idx < end; idx++) {
        context.output[ context.outOffset ++ ] = stackTop[idx];
      }
    } else if (format == 1) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      bytes memory alphabet = '0123456789abcdef';
      uint startNibble = start * 2;
      uint endNibble = end * 2;

      stackTop >>= (64 - endNibble) * 4;

      context.output[context.outOffset++] = '0';
      context.output[context.outOffset++] = 'x';
      for (uint256 i = endNibble-1; i >= startNibble; i--) {
        uint nibble = stackTop & 0xf;
        stackTop >>= 4;
        context.output[context.outOffset + i - startNibble ] = alphabet[nibble];
      }
      context.outOffset += endNibble - startNibble;
    } else if (format == 2) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      if (start == 0 && end == 32) {
        context.outOffset = base64Encode(stackTop, context.output, context.outOffset);
      } else {
        uint length = end - start;
        bytes memory temp = new bytes(length);
        for (uint idx = 0; idx < length; idx++) {
          temp[idx] = bytes32(stackTop)[start + idx];
        }
        context.outOffset = base64EncodeBuffer(temp, context.output, context.outOffset);
      } if (format == 3) {
        require(start == 0 && end == 32, 'invalid cid length');
        context.outOffset = ipfsCidEncode(context.stack[context.stackLength - 1], context.output, context.outOffset);
      }
    }


    context.stackLength--;
  }
  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteContext(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 0, 'stack underflow');
    uint contextId = uint(context.stack[context.stackLength - 1]);
    context.stackLength--;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (contextId == CONTEXT_TOKEN_ID || contextId == CONTEXT_TOKEN_OWNER || contextId == CONTEXT_BLOCK_TIMESTAMP) {
      require(format != 0, 'invalid format for uint256');
      uint value = 0;
      if (contextId == CONTEXT_TOKEN_ID) {
        value = context.tokenId;
      } else if (contextId == CONTEXT_TOKEN_OWNER ) {
        value = uint256(uint160(context.owner));
      } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
        // solhint-disable-next-line not-rely-on-time
        value = uint256(block.timestamp);
      }

      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 63; i >= 0; i--) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      }

    } else if (contextId == CONTEXT_ARWEAVE_CONTENT_API || contextId == CONTEXT_IPFS_CONTENT_API ) {
      require(format == 0, 'invalid format for string');
      string memory value;
      if (contextId == CONTEXT_ARWEAVE_CONTENT_API) {
        value = context.arweaveContentApi;
      } else if ( contextId == CONTEXT_IPFS_CONTENT_API) {
        value = context.ipfsContentApi;
      }

      context.outOffset = copyString(context, value);
    } else {
      revert('Unknown/unsupported context ID');
    }
  }

  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteColumnar(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 columnSlot = context.stack[context.stackLength - 2];
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 2;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_STRING) {
      require(format == 0, 'invalid format for string');
      context.outOffset = copyDictionaryString(context, bytes32(uint256(columnSlot) + 1), columnIndex);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
      require(format != 0, 'invalid format for uint256');
      uint value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 63; i >= 0; i--) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      } else if (format == 3) {
        context.outOffset = ipfsCidEncode(bytes32(value), context.output, context.outOffset);
      }
    } else {
      revert('unknown column type');
    }
  }

  // 1byte opcode to push the bytes32 at a given index in the data section onto the stack
  // byte 1 is the push codepoint,
  function execPushData(Context memory context, bytes32[] memory dataSegment, bytes32[] memory) internal pure {
    context.stack[context.stackLength-1] = dataSegment[uint256(context.stack[context.stackLength-1])];
  }

  // Nbyte opcode to push the immediate bytes in the codeSegment onto the stack
  // byte 1 is the pushImmediate codepoint,
  // byte 2 big-endian offset to write the first loaded byte from
  // byte 3 number of immediate bytes
  // bytes 4-N big-endian immediate bytes
  function execPushImmediate(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    uint startShiftByte = 31 - uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint length = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 value = 0;
    for (uint idx = 0; idx < length; idx++) {
      uint byteVal = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
      incrementCodeOffset(context);
      value |= byteVal << ((startShiftByte - idx) * 8);
    }

    context.stack[context.stackLength++] = bytes32(value);
  }

  uint private constant CONTEXT_TOKEN_ID = 0;
  uint private constant CONTEXT_TOKEN_OWNER = 1;
  uint private constant CONTEXT_BLOCK_TIMESTAMP = 2;
  uint private constant CONTEXT_ARWEAVE_CONTENT_API = 3;
  uint private constant CONTEXT_IPFS_CONTENT_API = 4;

  // 2byte opcode to push well-known context data to the stack
  // byte 1 is the push codepoint,
  // byte 2 well-known context id
  function execPushContext(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    uint contextId = uint256(context.stack[context.stackLength-1]);

    if (contextId == CONTEXT_TOKEN_ID) {
      context.stack[context.stackLength-1] = bytes32(context.tokenId);
    } else if (contextId == CONTEXT_TOKEN_OWNER ) {
      context.stack[context.stackLength-1] = bytes32(uint256(uint160(context.owner)));
    } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
      // solhint-disable-next-line not-rely-on-time
      context.stack[context.stackLength-1] = bytes32(uint256(block.timestamp));
    } else {
      revert('Unknown/unsupported context ID');
    }
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushStorage(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    bytes32 stackTop = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = StorageSlot.getBytes32Slot(stackTop).value;
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushColumnar(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 columnSlot = context.stack[context.stackLength - 2];
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 1;

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
      uint value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else {
      revert('unknown or bad column type');
    }
  }

  function execPop(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stackLength--;
  }

  function execDup(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stack[context.stackLength] = context.stack[context.stackLength - 1];
    context.stackLength++;
  }

  function execSwap(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    (context.stack[context.stackLength - 1], context.stack[context.stackLength - 2]) = (context.stack[context.stackLength - 2], context.stack[context.stackLength - 1]);
  }

  function execAdd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a + b);
    context.stackLength--;
  }

  function execSub(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a - b);
    context.stackLength--;
  }

  function execMul(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a * b);
    context.stackLength--;
  }

  function execDiv(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a / b);
    context.stackLength--;
  }

  function execMod(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a % b);
    context.stackLength--;
  }

  function execJumpPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    addCodeOffset(context, offset);
  }

  function execJumpNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    subCodeOffset(context, offset);
  }

  function execBrEZPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      addCodeOffset(context, offset);
    }
  }

  function execBrEZNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      subCodeOffset(context, offset);
    }
  }

  function execSha3(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = keccak256(abi.encodePacked(a));
  }

  function execXor(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a ^ b;
    context.stackLength--;
  }

  function execOr(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a | b;
    context.stackLength--;
  }

  function execAnd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a & b;
    context.stackLength--;
  }

  function execGt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a > b ? 1 : 0));
    context.stackLength--;
  }

  function execGte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a >= b ? 1 : 0));
    context.stackLength--;
  }

  function execLt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a < b ? 1 : 0));
    context.stackLength--;
  }

  function execLte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a <= b ? 1 : 0));
    context.stackLength--;
  }

  function execEq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a == b ? 1 : 0));
    context.stackLength--;
  }

  function execNeq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a != b ? 1 : 0));
    context.stackLength--;
  }

  uint private constant OP_NOOP                = 0x00;
  uint private constant OP_WRITE               = 0x01;
  uint private constant OP_WRITE_CONTEXT       = 0x02;
  uint private constant OP_WRITE_COLUMNAR      = 0x04;
  uint private constant OP_PUSH_DATA           = 0x05;
  uint private constant OP_PUSH_STORAGE        = 0x06;
  uint private constant OP_PUSH_IMMEDIATE      = 0x07;
  uint private constant OP_PUSH_CONTEXT        = 0x08;
  uint private constant OP_PUSH_COLUMNAR       = 0x09;
  uint private constant OP_POP                 = 0x0a;
  uint private constant OP_DUP                 = 0x0b;
  uint private constant OP_SWAP                = 0x0c;
  uint private constant OP_ADD                 = 0x0d;
  uint private constant OP_SUB                 = 0x0e;
  uint private constant OP_MUL                 = 0x0f;
  uint private constant OP_DIV                 = 0x10;
  uint private constant OP_MOD                 = 0x11;
  uint private constant OP_JUMP_POS            = 0x12;
  uint private constant OP_JUMP_NEG            = 0x13;
  uint private constant OP_BRANCH_POS_EQ_ZERO  = 0x14;
  uint private constant OP_BRANCH_NEG_EQ_ZERO  = 0x15;
  uint private constant OP_SHA3                = 0x16;
  uint private constant OP_XOR                 = 0x17;
  uint private constant OP_OR                  = 0x18;
  uint private constant OP_AND                 = 0x19;
  uint private constant OP_GT                  = 0x1a;
  uint private constant OP_GTE                 = 0x1b;
  uint private constant OP_LT                  = 0x1c;
  uint private constant OP_LTE                 = 0x1d;
  uint private constant OP_EQ                  = 0x1e;
  uint private constant OP_NEQ                 = 0x1f;

  function incrementCodeOffset(Context memory context) internal pure {
    context.codeBufferOffset++;
    if (context.codeBufferOffset == 32) {
      context.codeBufferOffset = 0;
      context.codeBufferIndex++;
    }
  }

  function addCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc += offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function subCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc -= offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function execOne(Context memory context, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view {
    uint nextOp = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);

    incrementCodeOffset(context);

    if (nextOp == OP_NOOP) {
      //solhint-disable-previous-line no-empty-blocks
    } else if (nextOp == OP_WRITE) {
      execWrite(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_CONTEXT) {
      execWriteContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_COLUMNAR) {
      execWriteColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_DATA) {
      execPushData(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_STORAGE) {
      execPushStorage(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_IMMEDIATE) {
      execPushImmediate(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_CONTEXT) {
      execPushContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_COLUMNAR) {
      execPushColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_POP) {
      execPop(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DUP) {
      execDup(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SWAP) {
      execSwap(context, dataSegment, codeSegment);
    } else if (nextOp == OP_ADD) {
      execAdd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SUB) {
      execSub(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MUL) {
      execMul(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DIV) {
      execDiv(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MOD) {
      execMod(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_POS) {
      execJumpPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_NEG) {
      execJumpNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_POS_EQ_ZERO) {
      execBrEZPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_NEG_EQ_ZERO) {
      execBrEZNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SHA3) {
      execSha3(context, dataSegment, codeSegment);
    } else if (nextOp == OP_XOR) {
      execXor(context, dataSegment, codeSegment);
    } else if (nextOp == OP_OR) {
      execOr(context, dataSegment, codeSegment);
    } else if (nextOp == OP_AND) {
      execAnd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GT) {
      execGt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GTE) {
      execGte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LT) {
      execLt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LTE) {
      execLte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_EQ) {
      execEq(context, dataSegment, codeSegment);
    } else if (nextOp == OP_NEQ) {
      execNeq(context, dataSegment, codeSegment);
    } else {
      revert(string(abi.encodePacked('bad op code: ', Strings.toString(nextOp), ' next_pc: ', Strings.toString(context.codeBufferIndex), ',',  Strings.toString(context.codeBufferOffset))));
    }

    context.opsRetired++;

    if (/*context.opsRetired > 7 || */context.codeBufferIndex >= codeSegment.length) {
      context.done = true;
    }
  }

  function interpolateTemplate(uint256 tokenId, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view returns (bytes memory) {
    Context memory context;
    context.output = new bytes(0xFFFF);
    context.tokenId = tokenId;
    context.owner = owner;
    context.arweaveContentApi = arweaveContentApi;
    context.ipfsContentApi = ipfsContentApi;
    context.outOffset = 0;

    while (!context.done) {
      execOne(context, dataSegment, codeSegment);
    }

    bytes memory result = context.output;
    uint resultLen = context.outOffset;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(result, resultLen)
    }

    return result;
  }

  function makeJson( uint256 tokenId, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(metadata);
  }

  function makeDataURI( string memory uriBase, uint256 tokenId, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(abi.encodePacked(uriBase,Base64.encode(metadata)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

import './NamelessMetadataURIV1.sol';
import './INamelessTemplateLibrary.sol';
import './INamelessToken.sol';
import './INamelessTokenData.sol';

contract NamelessTokenData is INamelessTokenData, AccessControl, Initializable {
  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  address private _templateLibrary;
  string private _uriBase;
  address public clonableTokenAddress;
  address public frontendAddress;
  address payable public royaltyAddress;
  uint256 public royaltyBps;

  function initialize (
    address templateLibrary_,
    address clonableTokenAddress_,
    address initialAdmin
  ) public override initializer {
    _templateLibrary = templateLibrary_;
    _uriBase = 'data:application/json;base64,';
    clonableTokenAddress = clonableTokenAddress_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(
    address templateLibrary_,
    address clonableTokenAddress_
  ) {
    initialize(templateLibrary_, clonableTokenAddress_, msg.sender);
  }

  bool public isSealed;

  modifier onlyUnsealed() {
    require(!isSealed, 'tokens are sealed');
    _;
  }

  modifier onlyFrontend() {
    require(msg.sender == frontendAddress, 'caller not frontend');
    _;
  }

  function sealData() public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSealed, 'tokens are sealed');
    isSealed = true;
  }

  function _setColumnData(uint256 columnHash, bytes32[] memory data, uint offset ) internal  {
    bytes32[0xFFFF] storage storageData;
    uint256 columnDataHash = columnHash + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    for( uint idx = 0; idx < data.length; idx++) {
      storageData[idx + offset] = data[idx];
    }
  }

  function _setColumnMetadata(uint256 columnHash, uint columnType ) internal {
    uint256[1] storage columnMetadata;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      columnMetadata.slot := columnHash
    }

    columnMetadata[0] = columnMetadata[0] | ((columnType & 0xFF) << 248);
  }

  struct ColumnConfiguration {
    uint256 columnHash;
    uint256 columnType;
    uint256 dataOffset;
    bytes32[] data;
  }

  function configureData( ColumnConfiguration[] calldata configs) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    for(uint idx = 0; idx < configs.length; idx++) {
      _setColumnMetadata(configs[idx].columnHash, configs[idx].columnType);
      _setColumnData(configs[idx].columnHash, configs[idx].data, configs[idx].dataOffset);
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION = 0x1;
  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION  = 0x2;

  uint256 public extensions;
  function enableExtensions(uint256 newExtensions) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    extensions = extensions | newExtensions;

    if (newExtensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      initializeTokenTransferCountExtension();
    }

    if (newExtensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      initializeTokenTransferTimeExtension();
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_COUNT_EXTENSION_SLOT'));
  function initializeTokenTransferCountExtension() internal {
    uint256[1] storage storageMetadata;
    uint256 metadataSlot = TOKEN_TRANSFER_COUNT_EXTENSION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := metadataSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferCountExtension(uint256 tokenId) public onlyFrontend {
    uint256[0xFFFF] storage storageData;
    uint256 columnDataHash = TOKEN_TRANSFER_COUNT_EXTENSION_SLOT + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    storageData[tokenId] = storageData[tokenId] + 1;
  }

  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_TIME_EXTENSION_SLOT'));
  function initializeTokenTransferTimeExtension() internal {
    uint256[1] storage storageMetadata;
    uint256 metadataSlot = TOKEN_TRANSFER_TIME_EXTENSION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := metadataSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferTimeExtension(uint256 tokenId) public onlyFrontend {
    uint256[0xFFFF] storage storageData;
    uint256 columnDataHash = TOKEN_TRANSFER_TIME_EXTENSION_SLOT + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    // solhint-disable-next-line not-rely-on-time
    storageData[tokenId] = block.timestamp;
  }

  function beforeTokenTransfer(address from, address, uint256 tokenId) public onlyFrontend override returns (bool) {
    if (extensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      // don't count minting as a transfer
      if (from != address(0)) {
        processTokenTransferCountExtension(tokenId);
      }
    }

    if (extensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      processTokenTransferTimeExtension(tokenId);
    }

    return extensions != 0;
  }

  function setRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
  }

  function getFeeRecipients(uint256) public view override returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view override returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }

  function setURIBase(string calldata uriBase_) public onlyRole(INFRA_ROLE) {
    _uriBase = uriBase_;
  }

  uint256 public templateIndex;
  bytes32[] public templateData;
  bytes32[] public templateCode;

  function setLibraryTemplate(uint256 which) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex = which;
    delete(templateData);
    delete(templateCode);
  }

  function setCustomTemplate(bytes32[] calldata _data, bytes32[] calldata _code) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex = type(uint256).max;
    templateData = _data;
    templateCode = _code;
  }

  function getTokenURI(uint256 tokenId, address owner) public view override returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();

    if (templateIndex == type(uint256).max) {
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, owner, arweaveContentApi, ipfsContentApi, templateData, templateCode);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex);
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function getTokenMetadata(uint256 tokenId, address owner) public view returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();

    if (templateIndex == type(uint256).max) {
      return NamelessMetadataURIV1.makeJson(tokenId, owner, arweaveContentApi, ipfsContentApi, templateData, templateCode);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex);
      return NamelessMetadataURIV1.makeJson(tokenId, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function createFrontend(string calldata name, string calldata symbol) public onlyRole(MINTER_ROLE) returns (address) {
    require(frontendAddress == address(0), 'frontend already created');
    frontendAddress = Clones.clone(clonableTokenAddress);

    INamelessToken frontend = INamelessToken(frontendAddress);
    frontend.initialize(name, symbol, address(this), msg.sender);

    return frontendAddress;
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override( AccessControl) returns (bool) {
    return AccessControl.supportsInterface(interfaceId);
  }

}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin public expiriment
// @dev see https://github.com/OpenZeppelin/solidity-jwt/blob/2a787f1c12c50da649eed1670b3a6d9c0221dd8e/contracts/Base64.sol for original
pragma solidity ^0.8.0;

library Base64 {

    bytes constant private BASE_64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory buffer, bytes memory output, uint outOffset) public pure returns (uint) {
      uint outLen = (buffer.length + 2) / 3 * 4;

      uint256 i = 0;
      uint256 j = outOffset;

      for (; i + 3 <= buffer.length; i += 3) {
          (output[j], output[j+1], output[j+2], output[j+3]) = encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }

      if (i + 2 == buffer.length) {
        (output[j], output[j+1], output[j+2], ) = encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            0
        );
        output[j+3] = '=';
      } else if (i + 1 == buffer.length) {
        (output[j], output[j+1], , ) = encode3(
            uint8(buffer[i]),
            0,
            0
        );
        output[j+2] = '=';
        output[j+3] = '=';
      }

      return outOffset + outLen;
    }

    function encode(bytes memory buffer) public pure returns (bytes memory) {
      uint outLen = (buffer.length + 2) / 3 * 4;
      bytes memory result = new bytes(outLen);

      uint256 i = 0;
      uint256 j = 0;

      for (; i + 3 <= buffer.length; i += 3) {
          (result[j], result[j+1], result[j+2], result[j+3]) = encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }

      if (i + 2 == buffer.length) {
        (result[j], result[j+1], result[j+2], ) = encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            0
        );
        result[j+3] = '=';
      } else if (i + 1 == buffer.length) {
        (result[j], result[j+1], , ) = encode3(
            uint8(buffer[i]),
            0,
            0
        );
        result[j+2] = '=';
        result[j+3] = '=';
      }

      return result;
    }

    function encode(uint256 bigint, bytes memory output, uint outOffset) external pure returns (uint) {
        bytes32 buffer = bytes32(bigint);

        uint256 i = 0;
        uint256 j = outOffset;

        for (; i + 3 <= 32; i += 3) {
            (output[j], output[j+1], output[j+2], output[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (output[j], output[j+1], output[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return outOffset + 43;
    }

    function encode(uint256 bigint) external pure returns (string memory) {
        bytes32 buffer = bytes32(bigint);
        bytes memory res = new bytes(43);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= 32; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (res[j], res[j+1], res[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = BASE_64_CHARS[c0];
        b1 = BASE_64_CHARS[c1];
        b2 = BASE_64_CHARS[c2];
        b3 = BASE_64_CHARS[c3];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BinaryDecoder.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library PackedVarArray {
  function getString(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (string memory) {
    bytes memory result = new bytes(len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while( bufferOffset < lastOffset) {
        result[outIdx++] = buffer[bufferOffset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return string(result);
  }

  function getString(bytes32[0xFFFF] storage buffers, uint index) internal view returns (string memory) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;

    return getString(buffers, stringOffset, stringLen);
  }

  function getStringInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;
    uint bufferIdx = stringOffset / 32;
    uint bufferOffset = stringOffset % 32;
    bytes32 bufferSlot;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      bufferSlot := buffers.slot
    }

    bufferSlot = bytes32(uint(bufferSlot) +  bufferIdx);


    return (bufferSlot, bufferOffset, stringLen);
  }

  function getStringLength(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    return stringOffsetLen >> 24;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (uint16[] memory) {
    uint16[] memory result = new uint16[](len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len * 2;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while (bufferOffset < lastOffset) {
        result[outIdx]  = uint16(uint8(buffer[bufferOffset++])) << 8;
        result[outIdx] |= uint16(uint8(buffer[bufferOffset++]));
        outIdx++;
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return result;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint16[] memory) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;

    return getUint16Array(buffers, arrOffset, arrLen);
  }

  function getUint16ArrayInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( uint, uint, uint ) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;
    uint bufferIdx = arrOffset / 32;
    uint bufferOffset = arrOffset % 32;

    return (bufferIdx, bufferOffset, arrLen);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

