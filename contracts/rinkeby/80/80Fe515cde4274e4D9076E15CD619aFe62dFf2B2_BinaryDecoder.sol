// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
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

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
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

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
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

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}