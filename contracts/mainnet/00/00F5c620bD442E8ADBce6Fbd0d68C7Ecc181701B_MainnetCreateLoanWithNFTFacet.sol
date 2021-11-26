// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.4;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

pragma solidity ^0.8.4;

library BytesUtils {
    /*
    * @dev Returns the keccak-256 hash of a byte range.
    * @param self The byte string to hash.
    * @param offset The position to start hashing at.
    * @param len The number of bytes to hash.
    * @return The hash of the byte range.
    */
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }


    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal.
    * @param self The first bytes to compare.
    * @param other The second bytes to compare.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, bytes memory other) internal pure returns (int) {
        return compare(self, 0, self.length, other, 0, other.length);
    }

    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal. Comparison is done per-rune,
    *      on unicode codepoints.
    * @param self The first bytes to compare.
    * @param offset The offset of self.
    * @param len    The length of self.
    * @param other The second bytes to compare.
    * @param otheroffset The offset of the other string.
    * @param otherlen    The length of the other string.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, uint offset, uint len, bytes memory other, uint otheroffset, uint otherlen) internal pure returns (int) {
        uint shortest = len;
        if (otherlen < len)
        shortest = otherlen;

        uint selfptr;
        uint otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask;
                if (shortest > 32) {
                    mask = type(uint256).max;
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                int diff = int(a & mask) - int(b & mask);
                if (diff != 0)
                return diff;
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int(len) - int(otherlen);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @param len The number of bytes to compare
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset, uint len) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

    /*
    * @dev Returns true if the two byte ranges are equal with offsets.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset) internal pure returns (bool) {
        return keccak(self, offset, self.length - offset) == keccak(other, otherOffset, other.length - otherOffset);
    }

    /*
    * @dev Compares a range of 'self' to all of 'other' and returns True iff
    *      they are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other) internal pure returns (bool) {
        return self.length >= offset + other.length && equals(self, offset, other, 0, other.length);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, bytes memory other) internal pure returns(bool) {
        return self.length == other.length && equals(self, 0, other, 0, self.length);
    }

    /*
    * @dev Returns the 8-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 8 bits of the string, interpreted as an integer.
    */
    function readUint8(bytes memory self, uint idx) internal pure returns (uint8 ret) {
        return uint8(self[idx]);
    }

    /*
    * @dev Returns the 16-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 16 bits of the string, interpreted as an integer.
    */
    function readUint16(bytes memory self, uint idx) internal pure returns (uint16 ret) {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

    /*
    * @dev Returns the 32-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bits of the string, interpreted as an integer.
    */
    function readUint32(bytes memory self, uint idx) internal pure returns (uint32 ret) {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

    /*
    * @dev Returns the n byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes.
    * @param len The number of bytes.
    * @return The specified 32 bytes of the string.
    */
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    /*
    * @dev Copies a substring into a new byte string.
    * @param self The byte string to copy from.
    * @param offset The offset to start copying at.
    * @param len The number of bytes to copy.
    */
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    // Maps characters from 0x30 to 0x7A to their base32 values.
    // 0xFF represents invalid characters in that range.
    bytes constant base32HexTable = hex'00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';

    /**
     * @dev Decodes unpadded base32 data of up to one word in length.
     * @param self The data to decode.
     * @param off Offset into the string to start at.
     * @param len Number of characters to decode.
     * @return The decoded data, left aligned.
     */
    function base32HexDecodeWord(bytes memory self, uint off, uint len) internal pure returns(bytes32) {
        require(len <= 52);

        uint ret = 0;
        uint8 decoded;
        for(uint i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint(uint8(char)) - 0x30]);
            require(decoded <= 0x20);
            if(i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint bitlen = len * 5;
        if(len % 8 == 0) {
            // Multiple of 8 characters, no padding
            ret = (ret << 5) | decoded;
        } else if(len % 8 == 2) {
            // Two extra characters - 1 byte
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if(len % 8 == 4) {
            // Four extra characters - 2 bytes
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if(len % 8 == 5) {
            // Five extra characters - 3 bytes
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if(len % 8 == 7) {
            // Seven extra characters - 4 bytes
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }
}

pragma solidity ^0.8.4;

import "./BytesUtils.sol";
import "@ensdomains/buffer/contracts/Buffer.sol";

/**
* @dev RRUtils is a library that provides utilities for parsing DNS resource records.
*/
library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

    /**
    * @dev Returns the number of bytes in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The length of the DNS name at 'offset', in bytes.
    */
    function nameLength(bytes memory self, uint offset) internal pure returns(uint) {
        uint idx = offset;
        while (true) {
            assert(idx < self.length);
            uint labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
        }
        return idx - offset;
    }

    /**
    * @dev Returns a DNS format name at the specified offset of self.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return ret The name.
    */
    function readName(bytes memory self, uint offset) internal pure returns(bytes memory ret) {
        uint len = nameLength(self, offset);
        return self.substring(offset, len);
    }

    /**
    * @dev Returns the number of labels in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The number of labels in the DNS name at 'offset', in bytes.
    */
    function labelCount(bytes memory self, uint offset) internal pure returns(uint) {
        uint count = 0;
        while (true) {
            assert(offset < self.length);
            uint labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
            count += 1;
        }
        return count;
    }

    uint constant RRSIG_TYPE = 0;
    uint constant RRSIG_ALGORITHM = 2;
    uint constant RRSIG_LABELS = 3;
    uint constant RRSIG_TTL = 4;
    uint constant RRSIG_EXPIRATION = 8;
    uint constant RRSIG_INCEPTION = 12;
    uint constant RRSIG_KEY_TAG = 16;
    uint constant RRSIG_SIGNER_NAME = 18;

    struct SignedSet {
        uint16 typeCovered;
        uint8 algorithm;
        uint8 labels;
        uint32 ttl;
        uint32 expiration;
        uint32 inception;
        uint16 keytag;
        bytes signerName;
        bytes data;
        bytes name;
    }

    function readSignedSet(bytes memory data) internal pure returns(SignedSet memory self) {
        self.typeCovered = data.readUint16(RRSIG_TYPE);
        self.algorithm = data.readUint8(RRSIG_ALGORITHM);
        self.labels = data.readUint8(RRSIG_LABELS);
        self.ttl = data.readUint32(RRSIG_TTL);
        self.expiration = data.readUint32(RRSIG_EXPIRATION);
        self.inception = data.readUint32(RRSIG_INCEPTION);
        self.keytag = data.readUint16(RRSIG_KEY_TAG);
        self.signerName = readName(data, RRSIG_SIGNER_NAME);
        self.data = data.substring(RRSIG_SIGNER_NAME + self.signerName.length, data.length - RRSIG_SIGNER_NAME - self.signerName.length);
    }

    function rrs(SignedSet memory rrset) internal pure returns(RRIterator memory) {
        return iterateRRs(rrset.data, 0);
    }

    /**
    * @dev An iterator over resource records.
    */
    struct RRIterator {
        bytes data;
        uint offset;
        uint16 dnstype;
        uint16 class;
        uint32 ttl;
        uint rdataOffset;
        uint nextOffset;
    }

    /**
    * @dev Begins iterating over resource records.
    * @param self The byte string to read from.
    * @param offset The offset to start reading at.
    * @return ret An iterator object.
    */
    function iterateRRs(bytes memory self, uint offset) internal pure returns (RRIterator memory ret) {
        ret.data = self;
        ret.nextOffset = offset;
        next(ret);
    }

    /**
    * @dev Returns true iff there are more RRs to iterate.
    * @param iter The iterator to check.
    * @return True iff the iterator has finished.
    */
    function done(RRIterator memory iter) internal pure returns(bool) {
        return iter.offset >= iter.data.length;
    }

    /**
    * @dev Moves the iterator to the next resource record.
    * @param iter The iterator to advance.
    */
    function next(RRIterator memory iter) internal pure {
        iter.offset = iter.nextOffset;
        if (iter.offset >= iter.data.length) {
            return;
        }

        // Skip the name
        uint off = iter.offset + nameLength(iter.data, iter.offset);

        // Read type, class, and ttl
        iter.dnstype = iter.data.readUint16(off);
        off += 2;
        iter.class = iter.data.readUint16(off);
        off += 2;
        iter.ttl = iter.data.readUint32(off);
        off += 4;

        // Read the rdata
        uint rdataLength = iter.data.readUint16(off);
        off += 2;
        iter.rdataOffset = off;
        iter.nextOffset = off + rdataLength;
    }

    /**
    * @dev Returns the name of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the owner name from the RR.
    */
    function name(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.offset, nameLength(iter.data, iter.offset));
    }

    /**
    * @dev Returns the rdata portion of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the RR's RDATA.
    */
    function rdata(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

    uint constant DNSKEY_FLAGS = 0;
    uint constant DNSKEY_PROTOCOL = 2;
    uint constant DNSKEY_ALGORITHM = 3;
    uint constant DNSKEY_PUBKEY = 4;

    struct DNSKEY {
        uint16 flags;
        uint8 protocol;
        uint8 algorithm;
        bytes publicKey;
    }

    function readDNSKEY(bytes memory data, uint offset, uint length) internal pure returns(DNSKEY memory self) {
        self.flags = data.readUint16(offset + DNSKEY_FLAGS);
        self.protocol = data.readUint8(offset + DNSKEY_PROTOCOL);
        self.algorithm = data.readUint8(offset + DNSKEY_ALGORITHM);
        self.publicKey = data.substring(offset + DNSKEY_PUBKEY, length - DNSKEY_PUBKEY);
    } 

    uint constant DS_KEY_TAG = 0;
    uint constant DS_ALGORITHM = 2;
    uint constant DS_DIGEST_TYPE = 3;
    uint constant DS_DIGEST = 4;

    struct DS {
        uint16 keytag;
        uint8 algorithm;
        uint8 digestType;
        bytes digest;
    }

    function readDS(bytes memory data, uint offset, uint length) internal pure returns(DS memory self) {
        self.keytag = data.readUint16(offset + DS_KEY_TAG);
        self.algorithm = data.readUint8(offset + DS_ALGORITHM);
        self.digestType = data.readUint8(offset + DS_DIGEST_TYPE);
        self.digest = data.substring(offset + DS_DIGEST, length - DS_DIGEST);
    }

    struct NSEC3 {
        uint8 hashAlgorithm;
        uint8 flags;
        uint16 iterations;
        bytes salt;
        bytes32 nextHashedOwnerName;
        bytes typeBitmap;
    }

    uint constant NSEC3_HASH_ALGORITHM = 0;
    uint constant NSEC3_FLAGS = 1;
    uint constant NSEC3_ITERATIONS = 2;
    uint constant NSEC3_SALT_LENGTH = 4;
    uint constant NSEC3_SALT = 5;

    function readNSEC3(bytes memory data, uint offset, uint length) internal pure returns(NSEC3 memory self) {
        uint end = offset + length;
        self.hashAlgorithm = data.readUint8(offset + NSEC3_HASH_ALGORITHM);
        self.flags = data.readUint8(offset + NSEC3_FLAGS);
        self.iterations = data.readUint16(offset + NSEC3_ITERATIONS);
        uint8 saltLength = data.readUint8(offset + NSEC3_SALT_LENGTH);
        offset = offset + NSEC3_SALT;
        self.salt = data.substring(offset, saltLength);
        offset += saltLength;
        uint8 nextLength = data.readUint8(offset);
        require(nextLength <= 32);
        offset += 1;
        self.nextHashedOwnerName = data.readBytesN(offset, nextLength);
        offset += nextLength;
        self.typeBitmap = data.substring(offset, end - offset);
    }

    function checkTypeBitmap(NSEC3 memory self, uint16 rrtype) internal pure returns(bool) {
        return checkTypeBitmap(self.typeBitmap, 0, rrtype);
    }

    /**
    * @dev Checks if a given RR type exists in a type bitmap.
    * @param bitmap The byte string to read the type bitmap from.
    * @param offset The offset to start reading at.
    * @param rrtype The RR type to check for.
    * @return True if the type is found in the bitmap, false otherwise.
    */
    function checkTypeBitmap(bytes memory bitmap, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(uint8(1) << (uint8(7) - uint8(rrtype & 0x7)));
        for (uint off = offset; off < bitmap.length;) {
            uint8 window = bitmap.readUint8(off);
            uint8 len = bitmap.readUint8(off + 1);
            if (typeWindow < window) {
                // We've gone past our window; it's not here.
                return false;
            } else if (typeWindow == window) {
                // Check this type bitmap
                if (len <= windowByte) {
                    // Our type is past the end of the bitmap
                    return false;
                }
                return (bitmap.readUint8(off + windowByte + 2) & windowBitmask) != 0;
            } else {
                // Skip this type bitmap
                off += len + 2;
            }
        }

        return false;
    }

    function compareNames(bytes memory self, bytes memory other) internal pure returns (int) {
        if (self.equals(other)) {
            return 0;
        }

        uint off;
        uint otheroff;
        uint prevoff;
        uint otherprevoff;
        uint counts = labelCount(self, 0);
        uint othercounts = labelCount(other, 0);

        // Keep removing labels from the front of the name until both names are equal length
        while (counts > othercounts) {
            prevoff = off;
            off = progress(self, off);
            counts--;
        }

        while (othercounts > counts) {
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            othercounts--;
        }

        // Compare the last nonequal labels to each other
        while (counts > 0 && !self.equals(off, other, otheroff)) {
            prevoff = off;
            off = progress(self, off);
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            counts -= 1;
        }

        if (off == 0) {
            return -1;
        }
        if(otheroff == 0) {
            return 1;
        }

        return self.compare(prevoff + 1, self.readUint8(prevoff), other, otherprevoff + 1, other.readUint8(otherprevoff));
    }

    /**
     * @dev Compares two serial numbers using RFC1982 serial number math.
     */
    function serialNumberGte(uint32 i1, uint32 i2) internal pure returns(bool) {
        return int32(i1) - int32(i2) >= 0;
    }

    function progress(bytes memory body, uint off) internal pure returns(uint) {
        return off + 1 + body.readUint8(off);
    }
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity >=0.8.4;

import "./ENS.sol";

/**
 * The ENS registry contract.
 */
contract ENSRegistry is ENS {

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping (bytes32 => Record) records;
    mapping (address => mapping(address => bool)) operators;

    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node) {
        address owner = records[node].owner;
        require(owner == msg.sender || operators[owner][msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new ENS registrar.
     */
    constructor() public {
        records[0x0].owner = msg.sender;
    }

    /**
     * @dev Sets the record for a node.
     * @param node The node to update.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual override {
        setOwner(node, owner);
        _setResolverAndTTL(node, resolver, ttl);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual override {
        bytes32 subnode = setSubnodeOwner(node, label, owner);
        _setResolverAndTTL(subnode, resolver, ttl);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address owner) public virtual override authorised(node) {
        _setOwner(node, owner);
        emit Transfer(node, owner);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public virtual override authorised(node) returns(bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, owner);
        emit NewOwner(node, label, owner);
        return subnode;
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address resolver) public virtual override authorised(node) {
        emit NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /**
     * @dev Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 ttl) public virtual override authorised(node) {
        emit NewTTL(node, ttl);
        records[node].ttl = ttl;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) external virtual override {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node) public virtual override view returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node) public virtual override view returns (address) {
        return records[node].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public virtual override view returns (uint64) {
        return records[node].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) public virtual override view returns (bool) {
        return records[node].owner != address(0x0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param owner The address that owns the records.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) external virtual override view returns (bool) {
        return operators[owner][operator];
    }

    function _setOwner(bytes32 node, address owner) internal virtual {
        records[node].owner = owner;
    }

    function _setResolverAndTTL(bytes32 node, address resolver, uint64 ttl) internal {
        if(resolver != records[node].resolver) {
            records[node].resolver = resolver;
            emit NewResolver(node, resolver);
        }

        if(ttl != records[node].ttl) {
            records[node].ttl = ttl;
            emit NewTTL(node, ttl);
        }
    }
}

pragma solidity >=0.8.4;

import "../registry/ENS.sol";
import "./profiles/ABIResolver.sol";
import "./profiles/AddrResolver.sol";
import "./profiles/ContentHashResolver.sol";
import "./profiles/DNSResolver.sol";
import "./profiles/InterfaceResolver.sol";
import "./profiles/NameResolver.sol";
import "./profiles/PubkeyResolver.sol";
import "./profiles/TextResolver.sol";

interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address);
}

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver is ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    ENS ens;
    INameWrapper nameWrapper;

    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(ENS _ens, INameWrapper wrapperAddress){
        ens = _ens;
        nameWrapper = wrapperAddress;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external{
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isAuthorised(bytes32 node) internal override view returns(bool) {
        address owner = ens.owner(node);
        if(owner == address(nameWrapper) ){
            owner = nameWrapper.ownerOf(uint256(node));
        }
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool){
        return _operatorApprovals[account][operator];
    }

    function multicall(bytes[] calldata data) external returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) virtual override(ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver) public pure returns(bool) {
        return super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract ABIResolver is ResolverBase {
    bytes4 constant private ABI_INTERFACE_ID = 0x2203ab56;

    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

    mapping(bytes32=>mapping(uint256=>bytes)) abis;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == ABI_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract AddrResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract ContentHashResolver is ResolverBase {
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    event ContenthashChanged(bytes32 indexed node, bytes hash);

    mapping(bytes32=>bytes) hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == CONTENT_HASH_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";
import "../../dnssec-oracle/RRUtils.sol";

abstract contract DNSResolver is ResolverBase {
    using RRUtils for *;
    using BytesUtils for bytes;

    bytes4 constant private DNS_RECORD_INTERFACE_ID = 0xa8fa5682;
    bytes4 constant private DNS_ZONE_INTERFACE_ID = 0x5c47637c;

    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    // Zone hashes for the domains.
    // A zone hash is an EIP-1577 content hash in binary format that should point to a
    // resource containing a single zonefile.
    // node => contenthash
    mapping(bytes32=>bytes) private zonehashes;

    // Version the mapping for each zone.  This allows users who have lost
    // track of their entries to effectively delete an entire zone by bumping
    // the version number.
    // node => version
    mapping(bytes32=>uint256) private versions;

    // The records themselves.  Stored as binary RRSETs
    // node => version => name => resource => data
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>mapping(uint16=>bytes)))) private records;

    // Count of number of entries for a given name.  Required for DNS resolvers
    // when resolving wildcards.
    // node => version => name => number of records
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>uint16))) private nameEntriesCount;

    /**
     * Set one or more DNS records.  Records are supplied in wire-format.
     * Records with the same node/name/resource must be supplied one after the
     * other to ensure the data is updated correctly. For example, if the data
     * was supplied:
     *     a.example.com IN A 1.2.3.4
     *     a.example.com IN A 5.6.7.8
     *     www.example.com IN CNAME a.example.com.
     * then this would store the two A records for a.example.com correctly as a
     * single RRSET, however if the data was supplied:
     *     a.example.com IN A 1.2.3.4
     *     www.example.com IN CNAME a.example.com.
     *     a.example.com IN A 5.6.7.8
     * then this would store the first A record, the CNAME, then the second A
     * record which would overwrite the first.
     *
     * @param node the namehash of the node for which to set the records
     * @param data the DNS wire format records to set
     */
    function setDNSRecords(bytes32 node, bytes calldata data) external authorised(node) {
        uint16 resource = 0;
        uint256 offset = 0;
        bytes memory name;
        bytes memory value;
        bytes32 nameHash;
        // Iterate over the data to add the resource records
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            if (resource == 0) {
                resource = iter.dnstype;
                name = iter.name();
                nameHash = keccak256(abi.encodePacked(name));
                value = bytes(iter.rdata());
            } else {
                bytes memory newName = iter.name();
                if (resource != iter.dnstype || !name.equals(newName)) {
                    setDNSRRSet(node, name, resource, data, offset, iter.offset - offset, value.length == 0);
                    resource = iter.dnstype;
                    offset = iter.offset;
                    name = newName;
                    nameHash = keccak256(name);
                    value = bytes(iter.rdata());
                }
            }
        }
        if (name.length > 0) {
            setDNSRRSet(node, name, resource, data, offset, data.length - offset, value.length == 0);
        }
    }

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) public view returns (bytes memory) {
        return records[node][versions[node]][name][resource];
    }

    /**
     * Check if a given node has records.
     * @param node the namehash of the node for which to check the records
     * @param name the namehash of the node for which to check the records
     */
    function hasDNSRecords(bytes32 node, bytes32 name) public view returns (bool) {
        return (nameEntriesCount[node][versions[node]][name] != 0);
    }

    /**
     * Clear all information for a DNS zone.
     * @param node the namehash of the node for which to clear the zone
     */
    function clearDNSZone(bytes32 node) public authorised(node) {
        versions[node]++;
        emit DNSZoneCleared(node);
    }

    /**
     * setZonehash sets the hash for the zone.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The zonehash to set
     */
    function setZonehash(bytes32 node, bytes calldata hash) external authorised(node) {
        bytes memory oldhash = zonehashes[node];
        zonehashes[node] = hash;
        emit DNSZonehashChanged(node, oldhash, hash);
    }

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory) {
        return zonehashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == DNS_RECORD_INTERFACE_ID ||
               interfaceID == DNS_ZONE_INTERFACE_ID ||
               super.supportsInterface(interfaceID);
    }

    function setDNSRRSet(
        bytes32 node,
        bytes memory name,
        uint16 resource,
        bytes memory data,
        uint256 offset,
        uint256 size,
        bool deleteRecord) private
    {
        uint256 version = versions[node];
        bytes32 nameHash = keccak256(name);
        bytes memory rrData = data.substring(offset, size);
        if (deleteRecord) {
            if (records[node][version][nameHash][resource].length != 0) {
                nameEntriesCount[node][version][nameHash]--;
            }
            delete(records[node][version][nameHash][resource]);
            emit DNSRecordDeleted(node, name, resource);
        } else {
            if (records[node][version][nameHash][resource].length == 0) {
                nameEntriesCount[node][version][nameHash]++;
            }
            records[node][version][nameHash][resource] = rrData;
            emit DNSRecordChanged(node, name, resource, rrData);
        }
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";
import "./AddrResolver.sol";

abstract contract InterfaceResolver is ResolverBase, AddrResolver {
    bytes4 constant private INTERFACE_INTERFACE_ID = bytes4(keccak256("interfaceImplementer(bytes32,bytes4)"));
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if(a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", INTERFACE_META_ID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 165 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID) virtual override(AddrResolver, ResolverBase) public pure returns(bool) {
        return interfaceID == INTERFACE_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract NameResolver is ResolverBase {
    bytes4 constant private NAME_INTERFACE_ID = 0x691f3431;

    event NameChanged(bytes32 indexed node, string name);

    mapping(bytes32=>string) names;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string calldata name) external authorised(node) {
        names[node] = name;
        emit NameChanged(node, name);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == NAME_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract PubkeyResolver is ResolverBase {
    bytes4 constant private PUBKEY_INTERFACE_ID = 0xc8690233;

    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == PUBKEY_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity >=0.8.4;
import "../ResolverBase.sol";

abstract contract TextResolver is ResolverBase {
    bytes4 constant private TEXT_INTERFACE_ID = 0x59d1d43c;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    mapping(bytes32=>mapping(string=>string)) texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == TEXT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlStorageLib, AccessControlStorage } from "../storage.sol";

abstract contract ReentryMods {
    modifier nonReentry(bytes32 id) {
        AccessControlStorage storage s = AccessControlStorageLib.store();
        require(!s.entered[id], "AccessControl: reentered");
        s.entered[id] = true;
        _;
        s.entered[id] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RolesMods } from "./RolesMods.sol";
import { RolesLib } from "./RolesLib.sol";
import { ADMIN } from "../../../shared/roles.sol";

contract RolesFacet is RolesMods {
    /**
     * @notice Checks if an account has a specific role.
     * @param role Encoding of the role to check.
     * @param account Address to check the {role} for.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return RolesLib.hasRole(role, account);
    }

    /**
     * @notice Grants an account a new role.
     * @param role Encoding of the role to give.
     * @param account Address to give the {role} to.
     *
     * Requirements:
     *  - Sender must be role admin.
     */
    function grantRole(bytes32 role, address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.grantRole(role, account);
    }

    /**
     * @notice Removes a role from an account.
     * @param role Encoding of the role to remove.
     * @param account Address to remove the {role} from.
     *
     * Requirements:
     *  - Sender must be role admin.
     */
    function revokeRole(bytes32 role, address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.revokeRole(role, account);
    }

    /**
     * @notice Removes a role from the sender.
     * @param role Encoding of the role to remove.
     */
    function renounceRole(bytes32 role) external {
        RolesLib.revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlStorageLib, AccessControlStorage } from "../storage.sol";

library RolesLib {
    function s() private pure returns (AccessControlStorage storage) {
        return AccessControlStorageLib.store();
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Checks if an account has a specific role.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return s().roles[role][account];
    }

    /**
     * @dev Gives an account a new role.
     * @dev Should only use when circumventing admin checking.
     * @dev If account already has the role, no event is emitted.
     * @param role Encoding of the role to give.
     * @param account Address to give the {role} to.
     */
    function grantRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) return;
        s().roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Removes a role from an account.
     * @dev Should only use when circumventing admin checking.
     * @dev If account does not already have the role, no event is emitted.
     * @param role Encoding of the role to remove.
     * @param account Address to remove the {role} from.
     */
    function revokeRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) return;
        s().roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RolesLib } from "./RolesLib.sol";

abstract contract RolesMods {
    /**
     * @notice Requires that the {account} has {role}
     * @param role Encoding of the role to check.
     * @param account Address to check the {role} for.
     */
    modifier authorized(bytes32 role, address account) {
        require(
            RolesLib.hasRole(role, account),
            "AccessControl: not authorized"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AccessControlStorage {
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(address => address) owners;
    mapping(bytes32 => bool) entered;
}

bytes32 constant ACCESS_CONTROL_POS = keccak256(
    "teller.access_control.storage"
);

library AccessControlStorageLib {
    function store() internal pure returns (AccessControlStorage storage s) {
        bytes32 pos = ACCESS_CONTROL_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAToken } from "../../../shared/interfaces/IAToken.sol";
import {
    IAaveLendingPool
} from "../../../shared/interfaces/IAaveLendingPool.sol";
import {
    IAaveLendingPoolAddressesProvider
} from "../../../shared/interfaces/IAaveLendingPoolAddressesProvider.sol";

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../../storage/market.sol";
import { AppStorageLib } from "../../../storage/app.sol";

library LibDapps {
    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    /**
        @notice Grabs the Aave lending pool instance from the Aave lending pool address provider.
        @param aaveLPAddressProvider The immutable address of Aave's Lending Pool Address Provider on the deployed network.
        @return IAaveLendingPool instance address.
     */
    function getAaveLendingPool(address aaveLPAddressProvider)
        internal
        view
        returns (IAaveLendingPool)
    {
        return
            IAaveLendingPool(
                IAaveLendingPoolAddressesProvider(aaveLPAddressProvider)
                    .getLendingPool()
            ); // LP address provider contract is immutable on each deployed network and the address will never change
    }

    /**
        @notice Grabs the aToken instance from the lending pool.
        @param aaveLPAddressProvider The immutable address of Aave's Lending Pool Address Provider on the deployed network.
        @param tokenAddress The underlying asset address to get the aToken for.
        @return IAToken instance.
     */
    function getAToken(address aaveLPAddressProvider, address tokenAddress)
        internal
        view
        returns (IAToken)
    {
        return
            IAToken(
                getAaveLendingPool(aaveLPAddressProvider).getReserveData(
                    tokenAddress
                ).aTokenAddress
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoansEscrow {
    function init() external;

    /**
     * @notice it calls a dapp like YearnFinance at a target contract address with specified calldata
     * @param dappAddress address of the target contract address
     * @param dappData encoded abi of the function in our contract we want to call
     * @return the called data in bytes
     */
    function callDapp(address dappAddress, bytes calldata dappData)
        external
        payable
        returns (bytes memory);

    /**
     * @notice it calls a dapp like YearnFinance at a target contract address with specified calldata
     * @param dappAddress address of the target contract address
     * @param dappData encoded abi of the function in our contract we want to call
     * @param amount amount to call the dapp with as msg.value
     * @return resData_ the called data in
     */

    function callDappWithValue(
        address dappAddress,
        bytes calldata dappData,
        uint256 amount
    ) external payable returns (bytes memory);

    /**
     * @notice it approves the spender to spend a maximum amount of a respective token from a token address
     * @param token address of the respective ERC20 token to approve for the spender
     * @param spender address of the respective spender who is approved by the token contract
     */
    function setTokenAllowance(address token, address spender) external;

    /**
     * @notice it allows user to claim their escrow tokens
     * @dev only the owner (TellerDiamond) can make this call on behalf of the users
     * @param token address of the respective token contract to claim tokens from
     * @param to address where the tokens should be transferred to
     * @param amount uint256 amount of tokens to be claimed
     */
    function claimToken(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { LibDapps } from "../dapps/libraries/LibDapps.sol";
import { LibLoans } from "../../market/libraries/LibLoans.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILoansEscrow } from "../escrow/ILoansEscrow.sol";

// Storage
import { AppStorageLib } from "../../storage/app.sol";
import { MarketStorageLib, MarketStorage } from "../../storage/market.sol";

library LibEscrow {
    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function e(uint256 loanID) internal view returns (ILoansEscrow e_) {
        e_ = s().loanEscrows[loanID];
    }

    function exists(uint256 loanID) internal view returns (bool) {
        return address(e(loanID)) != address(0);
    }

    /**
     * @notice It returns a list of tokens owned by a loan escrow
     * @param loanID uint256 index used to return our token list
     * @return t_ which is a list of tokens
     */
    function getEscrowTokens(uint256 loanID)
        internal
        view
        returns (EnumerableSet.AddressSet storage t_)
    {
        t_ = s().escrowTokens[loanID];
    }

    /**
     * @notice It returns the balance of a respective token in a loan escrow
     * @param loanID uint256 index used to point to our loan escrow
     * @param token address of respective token to give us the balance of in our loan escrow
     * @return uint256 balance of respective token returned in an escrow loan
     */
    function balanceOf(uint256 loanID, address token)
        internal
        view
        returns (uint256)
    {
        return exists(loanID) ? IERC20(token).balanceOf(address(e(loanID))) : 0;
    }

    /**
     * @notice Adds or removes tokens held by the Escrow contract
     * @param loanID The loan ID to update the token list for
     * @param tokenAddress The token address to be added or removed
     */
    function tokenUpdated(uint256 loanID, address tokenAddress) internal {
        // Skip if is lending token
        if (LibLoans.loan(loanID).lendingToken == tokenAddress) return;

        EnumerableSet.AddressSet storage tokens = s().escrowTokens[loanID];
        bool contains = EnumerableSet.contains(tokens, tokenAddress);
        if (balanceOf(loanID, tokenAddress) > 0) {
            if (!contains) {
                EnumerableSet.add(tokens, tokenAddress);
            }
        } else if (contains) {
            EnumerableSet.remove(tokens, tokenAddress);
        }
    }

    /**
     * @notice Calculate the value of the loan by getting the value of all tokens the Escrow owns.
     * @param loanID The loan ID to calculate value for
     * @return value_ Escrow total value denoted in the lending token.
     */
    function calculateTotalValue(uint256 loanID)
        internal
        returns (uint256 value_)
    {
        if (!exists(loanID)) {
            return 0;
        }

        address lendingToken = LibLoans.loan(loanID).lendingToken;
        value_ += balanceOf(loanID, lendingToken);

        EnumerableSet.AddressSet storage tokens = getEscrowTokens(loanID);
        if (EnumerableSet.length(tokens) > 0) {
            for (uint256 i = 0; i < EnumerableSet.length(tokens); i++) {
                value_ += AppStorageLib.store()
                    .priceAggregator
                    .getBalanceOfFor(
                        address(e(loanID)),
                        EnumerableSet.at(tokens, i),
                        lendingToken
                    );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";

// Interfaces
import { ITToken_V3 } from "../ttoken/ITToken_V3.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../storage/market.sol";

library LendingLib {
    bytes32 internal constant ID = keccak256("LENDING");

    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function tToken(address asset) internal view returns (ITToken_V3 tToken_) {
        tToken_ = s().tTokens[asset];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    RolesFacet
} from "../../contexts2/access-control/roles/RolesFacet.sol";

/**
 * @notice This contract acts as an interface for the Teller token (TToken).
 *
 * @author [email protected]
 */
abstract contract ITToken is ERC20Upgradeable, RolesFacet {
    /**
     * @notice This event is emitted when a user deposits tokens into the pool.
     */
    event Mint(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when a user withdraws tokens from the pool.
     */
    event Redeem(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when a loan has been taken out through the Teller Diamond.
     * @param recipient The address receiving the borrowed funds.
     * @param totalBorrowed The total amount being loaned out by the tToken.
     */
    event LoanFunded(address indexed recipient, uint256 totalBorrowed);

    /**
     * @notice This event is emitted when a loan has been repaid through the Teller Diamond.
     * @param sender The address making the payment to the tToken.
     * @param principlePayment The amount paid back towards the principle loaned out by the tToken.
     * @param interestPayment The amount paid back towards the interest owed to the tToken.
     */
    event LoanPaymentMade(
        address indexed sender,
        uint256 principlePayment,
        uint256 interestPayment
    );

    /**
     * @notice This event is emitted when a new investment management strategy has been set for a Teller token.
     * @param strategyAddress The address of the new strategy set for managing the underlying assets held by the tToken.
     * @param sender The address of the sender setting the token strategy.
     */
    event StrategySet(address strategyAddress, address indexed sender);

    /**
     * @notice This event is emitted when the platform restriction is switched
     * @param restriction Boolean representing the state of the restriction
     * @param investmentManager address of the investment manager flipping the switch
     */
    event PlatformRestricted(
        bool restriction,
        address indexed investmentManager
    );

    /**
     * @notice The token that is the underlying asset for this Teller token.
     * @return ERC20 token
     */
    function underlying() external view virtual returns (ERC20);

    /**
     * @notice The balance of an {account} denoted in underlying value.
     * @param account Address to calculate the underlying balance.
     * @return balance_ the balance of the account
     */
    function balanceOfUnderlying(address account)
        external
        virtual
        returns (uint256 balance_);

    /**
     * @notice It calculates the current exchange rate for a whole Teller Token based off the underlying token balance.
     * @return rate_ The current exchange rate.
     */
    function exchangeRate() external virtual returns (uint256 rate_);

    /**
     * @notice It calculates the total supply of the underlying asset.
     * @return totalSupply_ the total supply denoted in the underlying asset.
     */
    function totalUnderlyingSupply()
        external
        virtual
        returns (uint256 totalSupply_);

    /**
     * @notice It calculates the market state values across a given market.
     * @notice Returns values that represent the global state across the market.
     * @return totalSupplied Total amount of the underlying asset supplied.
     * @return totalBorrowed Total amount borrowed through loans.
     * @return totalRepaid The total amount repaid till the current timestamp.
     * @return totalInterestRepaid The total amount interest repaid till the current timestamp.
     * @return totalOnLoan Total amount currently deployed in loans.
     */
    function getMarketState()
        external
        virtual
        returns (
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 totalRepaid,
            uint256 totalInterestRepaid,
            uint256 totalOnLoan
        );

    /**
     * @notice Calculates the current Total Value Locked, denoted in the underlying asset, in the Teller Token pool.
     * @return tvl_ The value locked in the pool.
     *
     * Note: This value includes the amount that is on loan (including ones that were sent to EOAs).
     */
    function currentTVL() external virtual returns (uint256 tvl_);

    /**
     * @notice It validates whether supply to debt (StD) ratio is valid including the loan amount.
     * @param newLoanAmount the new loan amount to consider the StD ratio.
     * @return ratio_ The debt ratio for lending pool.
     */
    function debtRatioFor(uint256 newLoanAmount)
        external
        virtual
        returns (uint16 ratio_);

    /**
     * @notice Called by the Teller Diamond contract when a loan has been taken out and requires funds.
     * @param recipient The account to send the funds to.
     * @param amount Funds requested to fulfill the loan.
     */
    function fundLoan(address recipient, uint256 amount) external virtual;

    /**
     * @notice Called by the Teller Diamond contract when a loan has been repaid.
     * @param amount Funds deposited back into the pool to repay the principal amount of a loan.
     * @param interestAmount Interest value paid into the pool from a loan.
     */
    function repayLoan(uint256 amount, uint256 interestAmount) external virtual;

    /**
     * @notice Increase account supply of specified token amount.
     * @param amount The amount of underlying tokens to use to mint.
     * @return mintAmount_ the amount minted of the specified token
     */
    function mint(uint256 amount)
        external
        virtual
        returns (uint256 mintAmount_);

    /**
     * @notice Redeem supplied Teller tokens for underlying value.
     * @param amount The amount of Teller tokens to redeem.
     */
    function redeem(uint256 amount) external virtual;

    /**
     * @notice Redeem supplied underlying value.
     * @param amount The amount of underlying tokens to redeem.
     */
    function redeemUnderlying(uint256 amount) external virtual;

    /**
     * @notice Rebalances the funds controlled by Teller Token according to the current strategy.
     *
     * See {TTokenStrategy}.
     */
    function rebalance() external virtual;

    /**
     * @notice Sets a new strategy to use for balancing funds.
     * @param strategy Address to the new strategy contract. Must implement the {ITTokenStrategy} interface.
     * @param initData Optional data to initialize the strategy.
     *
     * Requirements:
     *  - Sender must have ADMIN role
     */
    function setStrategy(address strategy, bytes calldata initData)
        external
        virtual;

    /**
     * @notice Gets the strategy used for balancing funds.
     * @return address of the strategy contract
     */
    function getStrategy() external view virtual returns (address);

    /**
     * @notice Sets the restricted state of the platform.
     * @param state boolean value that resembles the platform's state
     */
    function restrict(bool state) external virtual;

    /**
     * @notice it initializes the Teller Token
     * @param admin address of the admin to the respective Teller Token
     * @param underlying address of the ERC20 token
     */
    function initialize(address admin, address underlying) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    RolesFacet
} from "../../contexts2/access-control/roles/RolesFacet.sol";

/**
 * @notice This contract acts as an interface for the Teller token (TToken).
 *
 * @author [email protected]
 */
abstract contract ITToken_V3 is ERC20Upgradeable, RolesFacet {
    /**
     * @notice This event is emitted when a user deposits tokens into the pool.
     */
    event Mint(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when a user withdraws tokens from the pool.
     */
    event Redeem(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when a loan has been taken out through the Teller Diamond.
     * @param recipient The address receiving the borrowed funds.
     * @param totalBorrowed The total amount being loaned out by the tToken.
     */
    event LoanFunded(address indexed recipient, uint256 totalBorrowed);

    /**
     * @notice This event is emitted when a loan has been repaid through the Teller Diamond.
     * @param sender The address making the payment to the tToken.
     * @param principlePayment The amount paid back towards the principle loaned out by the tToken.
     * @param interestPayment The amount paid back towards the interest owed to the tToken.
     */
    event LoanPaymentMade(
        address indexed sender,
        uint256 principlePayment,
        uint256 interestPayment
    );

    /**
     * @notice This event is emitted when a new investment management strategy has been set for a Teller token.
     * @param strategyAddress The address of the new strategy set for managing the underlying assets held by the tToken.
     * @param sender The address of the sender setting the token strategy.
     */
    event StrategySet(address strategyAddress, address indexed sender);

    /**
     * @notice The token that is the underlying asset for this Teller token.
     * @return ERC20 token
     */
    function underlying() external view virtual returns (ERC20);

    /**
     * @notice The balance of an {account} denoted in underlying value.
     * @param account Address to calculate the underlying balance.
     * @return balance_ the balance of the account
     */
    function balanceOfUnderlying(address account)
        external
        virtual
        returns (uint256 balance_);

    /**
     * @notice It calculates the current exchange rate for a whole Teller Token based off the underlying token balance.
     * @return rate_ The current exchange rate.
     */
    function exchangeRate() external virtual returns (uint256 rate_);

    /**
     * @notice It calculates the total supply of the underlying asset.
     * @return totalSupply_ the total supply denoted in the underlying asset.
     */
    function totalUnderlyingSupply()
        external
        virtual
        returns (uint256 totalSupply_);

    /**
     * @notice It calculates the market state values across a given market.
     * @notice Returns values that represent the global state across the market.
     * @return totalSupplied Total amount of the underlying asset supplied.
     * @return totalBorrowed Total amount borrowed through loans.
     * @return totalRepaid The total amount repaid till the current timestamp.
     * @return totalInterestRepaid The total amount interest repaid till the current timestamp.
     * @return totalOnLoan Total amount currently deployed in loans.
     */
    function getMarketState()
        external
        virtual
        returns (
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 totalRepaid,
            uint256 totalInterestRepaid,
            uint256 totalOnLoan
        );

    /**
     * @notice Calculates the current Total Value Locked, denoted in the underlying asset, in the Teller Token pool.
     * @return tvl_ The value locked in the pool.
     *
     * Note: This value includes the amount that is on loan (including ones that were sent to EOAs).
     */
    function currentTVL() external virtual returns (uint256 tvl_);

    /**
     * @notice It validates whether supply to debt (StD) ratio is valid including the loan amount.
     * @param newLoanAmount the new loan amount to consider the StD ratio.
     * @return ratio_ The debt ratio for lending pool.
     */
    function debtRatioFor(uint256 newLoanAmount)
        external
        virtual
        returns (uint16 ratio_);

    /**
     * @notice Called by the Teller Diamond contract when a loan has been taken out and requires funds.
     * @param recipient The account to send the funds to.
     * @param amount Funds requested to fulfill the loan.
     */
    function fundLoan(address recipient, uint256 amount) external virtual;

    /**
     * @notice Called by the Teller Diamond contract when a loan has been repaid.
     * @param amount Funds deposited back into the pool to repay the principal amount of a loan.
     * @param interestAmount Interest value paid into the pool from a loan.
     */
    function repayLoan(uint256 amount, uint256 interestAmount) external virtual;

    /**
     * @notice Increase account supply of specified token amount.
     * @param amount The amount of underlying tokens to use to mint.
     * @return mintAmount_ the amount minted of the specified token
     */
    function mint(uint256 amount)
        external
        payable
        virtual
        returns (uint256 mintAmount_);

    /**
     * @notice Redeem supplied Teller tokens for underlying value.
     * @param amount The amount of Teller tokens to redeem.
     */
    function redeem(uint256 amount) external virtual;

    /**
     * @notice Redeem supplied underlying value.
     * @param amount The amount of underlying tokens to redeem.
     */
    function redeemUnderlying(uint256 amount) external virtual;

    /**
     * @notice Rebalances the funds controlled by Teller Token according to the current strategy.
     *
     * See {TTokenStrategy}.
     */
    function rebalance() external virtual;

    /**
     * @notice Sets a new strategy to use for balancing funds.
     * @param strategy Address to the new strategy contract. Must implement the {ITTokenStrategy} interface.
     * @param initData Optional data to initialize the strategy.
     *
     * Requirements:
     *  - Sender must have ADMIN role
     */
    function setStrategy(address strategy, bytes calldata initData)
        external
        virtual;

    /**
     * @notice Gets the strategy used for balancing funds.
     * @return address of the strategy contract
     */
    function getStrategy() external view virtual returns (address);

    /**
     * @notice it initializes the Teller Token
     * @param admin address of the admin to the respective Teller Token
     * @param underlying address of the ERC20 token
     * @param isWrappedNative boolean indicating the underlying asset is the wrapped native token
     */
    function initialize(
        address admin,
        address underlying,
        bool isWrappedNative
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { PausableMods } from "../settings/pausable/PausableMods.sol";
import {
    ReentryMods
} from "../contexts2/access-control/reentry/ReentryMods.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Libraries
import { LibCreateLoan } from "./libraries/LibCreateLoan.sol";
import { LibLoans } from "./libraries/LibLoans.sol";
import {
    PlatformSettingsLib
} from "../settings/platform/libraries/PlatformSettingsLib.sol";
import { NFTLib } from "../nft/libraries/NFTLib.sol";
import { AppStorageLib } from "../storage/app.sol";

import { TellerNFT_V2 } from "../nft/TellerNFT_V2.sol";

// Interfaces
import { ITToken } from "../lending/ttoken/ITToken.sol";

// Storage
import { LoanUserRequest, LoanStatus, Loan } from "../storage/market.sol";

/**
 * @notice This facet contains the logic for taking out a loan using the Teller NFT.
 * @dev This contract contains the base layer logic for creating and taking out
 *  a loan. It also includes the internal function {_takeOutLoanProcessNFTs} that
 *  handles the decoding of token data. As the same logic is used for Teller NFT
 *  V1 and V2 for creating and funding a loan, the logic for processing the token
 *  IDs and how many are different.
 * @dev See {MainnetCreateLoanWithNFTFacet._takeOutLoanProcessNFTs}
 * @author [email protected]
 */
contract CreateLoanWithNFTFacet is ReentryMods, PausableMods {
    // TELLER NFT V2
    TellerNFT_V2 private immutable TELLER_NFT_V2;
    address private immutable DAI;
    address private immutable USDC;
    address private immutable USDT;

    constructor(
        address tellerNFTV2Address,
        address daiAddress,
        address usdcAddress,
        address usdtAddress
    ) {
        require(daiAddress != address(0), "DAI null");
        require(usdcAddress != address(0), "USDC null");
        require(usdtAddress != address(0), "USDT null");

        TELLER_NFT_V2 = TellerNFT_V2(tellerNFTV2Address);
        DAI = daiAddress;
        USDC = usdcAddress;
        USDT = usdtAddress;
    }

    /**
     * @notice Creates a loan with the loan request and NFTs without any collateral
     * @param assetAddress Asset address to take out a loan
     * @param amount The amount of the {assetAddress} used for the loan
     * @param duration How long the loan should last (in seconds)
     * @param tokenData Encoded token data used to take out the loan. Data is
     *  is decode by the internal functions {_takeOutLoanProcessTokenDataVersion}
     *  and {_takeOutLoanProcessNFTs}
     */
    function takeOutLoanWithNFTs(
        address assetAddress,
        uint256 amount,
        uint32 duration,
        bytes calldata tokenData
    ) external paused(LibLoans.ID, false) {
        Loan storage loan = LibCreateLoan.initNewLoan(
            assetAddress,
            amount,
            duration,
            PlatformSettingsLib.getNFTInterestRate()
        );

        // Calculate the max loan size based on NFT V1 values
        uint8 lendingDecimals = ERC20(assetAddress).decimals();
        uint256 allowedBaseLoanSize = _takeOutLoanProcessTokenDataVersion(
            loan.id,
            tokenData
        ) *
            (10**lendingDecimals) *
            10; // Convert base loan with decimals
        uint256 allowedLoanSize;
        if (
            assetAddress == DAI || assetAddress == USDC || assetAddress == USDT
        ) {
            allowedLoanSize = allowedBaseLoanSize;
        } else {
            allowedLoanSize = AppStorageLib.store().priceAggregator.getValueFor(
                    USDC,
                    assetAddress,
                    allowedBaseLoanSize
                );
        }
        require(
            loan.borrowedAmount <= allowedLoanSize,
            "Teller: insufficient NFT loan size"
        );

        // Fund the loan
        LibCreateLoan.fundLoan(
            loan.lendingToken,
            LibCreateLoan.createEscrow(loan.id),
            loan.borrowedAmount
        );

        // Set the loan to active
        loan.status = LoanStatus.Active;

        emit LibCreateLoan.LoanTakenOut(
            loan.id,
            msg.sender,
            loan.borrowedAmount,
            true
        );
    }

    /**
     * @notice Process the NFT data to determine which token version to use
     * @dev Only knows how to process {tokenData} for NFT V2
     * @param loanID The ID for the loan to apply the NFTs to
     * @param tokenData Encoded token ID array. NFT V2 includes the IDs and amounts
     * @return allowedLoanSize_ The max loan size calculated by the token IDs and amounts
     */
    function _takeOutLoanProcessTokenDataVersion(
        uint256 loanID,
        bytes calldata tokenData
    ) internal returns (uint256) {
        (uint16 version, bytes memory tokenData_) = abi.decode(
            tokenData,
            (uint8, bytes)
        );

        return _takeOutLoanProcessNFTs(loanID, version, tokenData_);
    }

    /**
     * @notice Process the NFT data to calculate max loan size and apply to the loan
     * @dev Only knows how to process {tokenData} for NFT V2
     * @param loanID The ID for the loan to apply the NFTs to
     * @param version The token version used to know how to decode the data
     * @param tokenData Encoded token ID array. NFT V2 includes the IDs and amounts
     * @return allowedLoanSize_ The max loan size calculated by the token IDs and amounts
     */
    function _takeOutLoanProcessNFTs(
        uint256 loanID,
        uint16 version,
        bytes memory tokenData
    ) internal virtual returns (uint256 allowedLoanSize_) {
        bool useV2;
        uint256[] memory nftIDs;
        uint256[] memory amounts;
        if (version == 2) {
            (nftIDs, amounts) = abi.decode(tokenData, (uint256[], uint256[]));
            useV2 = true;
        } else if ((2 & version) == 2) {
            (, nftIDs, amounts) = abi.decode(
                tokenData,
                (uint256[], uint256[], uint256[])
            );
            useV2 = true;
        }
        if (useV2) {
            for (uint256 i; i < nftIDs.length; i++) {
                NFTLib.applyToLoanV2(loanID, nftIDs[i], amounts[i], msg.sender);

                uint256 baseLoanSize = TELLER_NFT_V2.tokenBaseLoanSize(
                    nftIDs[i]
                );
                allowedLoanSize_ += baseLoanSize * amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollateralEscrow {
    /**
     * @notice it initializes an escrow
     * @param tokenAddress the address of the collateral token to be stored
     * @param isWETH check if it's wrapped Ethereum
     */
    function init(address tokenAddress, bool isWETH) external;

    /**
     * @notice it deposits an amount of the respective collateral token into the escrow
     * @param loanID the ID of the loan
     * @param amount the amount of collateral tokens to be deposited
     */
    function deposit(uint256 loanID, uint256 amount) external payable;

    /**
     * @notice it withdraws an amount of tokens in a respective loanID on behalf of the borrower
     * @dev only the TellerDiamond can make this call on behalf of the borrower
     * @param loanID identifier of the loan
     * @param amount number of collateral tokens to send
     * @param receiver payable address to transfer money to
     */
    function withdraw(
        uint256 loanID,
        uint256 amount,
        address payable receiver
    ) external;

    /**
     * @notice it returns the supply of the respective loan
     * @param loanID the respective loan ID
     * @return supply_ the amount in collateral of the respective loan
     */
    function loanSupply(uint256 loanID) external view returns (uint256 supply_);

    /**
     * @notice it returns the total supply of the collateral token held by the contract
     * @return supply_ the total amount of collateral
     */
    function totalSupply() external view returns (uint256 supply_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { LibLoans } from "../libraries/LibLoans.sol";
import { LendingLib } from "../../lending/libraries/LendingLib.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import {
    PlatformSettingsLib
} from "../../settings/platform/libraries/PlatformSettingsLib.sol";
import {
    MaxDebtRatioLib
} from "../../settings/asset/libraries/MaxDebtRatioLib.sol";
import {
    MaxLoanAmountLib
} from "../../settings/asset/libraries/MaxLoanAmountLib.sol";
import { ILoansEscrow } from "../../escrow/escrow/ILoansEscrow.sol";

// Storage
import {
    LoanUserRequest,
    LoanStatus,
    Loan,
    MarketStorageLib
} from "../../storage/market.sol";
import { AppStorageLib } from "../../storage/app.sol";

library LibCreateLoan {
    /**
     * @notice This event is emitted when a loan has been successfully taken out
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     * @param amountBorrowed Total amount taken out in the loan
     * @param withNFT Boolean indicating if the loan was taken out using NFTs
     */
    event LoanTakenOut(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 amountBorrowed,
        bool withNFT
    );

    function initNewLoan(
        address assetAddress,
        uint256 amount,
        uint32 duration,
        uint16 interestRate
    ) internal returns (Loan storage loan_) {
        require(assetAddress != address(0), "Teller: asset loan asset null");
        // Perform loan request checks
        require(
            PlatformSettingsLib.getMaximumLoanDurationValue() >= duration,
            "Teller: max loan duration exceeded"
        );
        require(
            LendingLib.tToken(assetAddress).debtRatioFor(amount) <=
                MaxDebtRatioLib.get(assetAddress),
            "Teller: max supply-to-debt ratio exceeded"
        );

        // Get and increment new loan ID
        uint256 loanID = newID();
        loan_ = LibLoans.loan(loanID);

        // Set loan data based on terms
        loan_.id = uint128(loanID);
        loan_.borrower = payable(msg.sender);
        loan_.lendingToken = assetAddress;
        loan_.borrowedAmount = amount;
        loan_.interestRate = interestRate;
        loan_.loanStartTime = uint32(block.timestamp);
        loan_.duration = duration;

        // Set loan debt
        LibLoans.debt(loanID).principalOwed = loan_.borrowedAmount;
        LibLoans.debt(loanID).interestOwed = LibLoans.getInterestOwedFor(
            uint256(loanID),
            loan_.borrowedAmount
        );

        // Add loanID to borrower list
        MarketStorageLib.store().borrowerLoans[loan_.borrower].push(
            uint128(loanID)
        );
    }

    function fundLoan(
        address lendingToken,
        address destination,
        uint256 amount
    ) internal {
        // Pull funds from Teller Token LP and transfer to the new loan escrow
        LendingLib.tToken(lendingToken).fundLoan(destination, amount);
    }

    /**
     * @notice increments the loanIDCounter
     * @return id_ the new ID requested, which stores it in the loan data
     */
    function newID() internal returns (uint256 id_) {
        Counters.Counter storage counter = MarketStorageLib
            .store()
            .loanIDCounter;
        id_ = Counters.current(counter);
        Counters.increment(counter);
    }

    function currentID() internal view returns (uint256 id_) {
        Counters.Counter storage counter = MarketStorageLib
            .store()
            .loanIDCounter;
        id_ = Counters.current(counter);
    }

    /**
     * @notice it creates a new loan escrow contract
     * @param loanID the ID that identifies the loan
     * @return escrow_ the loanEscrow that gets created
     */
    function createEscrow(uint256 loanID) internal returns (address escrow_) {
        // Create escrow
        escrow_ = AppStorageLib.store().loansEscrowBeacon.cloneProxy("");
        ILoansEscrow(escrow_).init();
        // Save escrow address for loan
        MarketStorageLib.store().loanEscrows[loanID] = ILoansEscrow(escrow_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { LibEscrow } from "../../escrow/libraries/LibEscrow.sol";
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";
import {
    PlatformSettingsLib
} from "../../settings/platform/libraries/PlatformSettingsLib.sol";

// Storage
import { AppStorageLib } from "../../storage/app.sol";
import {
    MarketStorageLib,
    MarketStorage,
    Loan,
    LoanStatus,
    LoanDebt,
    LoanTerms
} from "../../storage/market.sol";

library LibLoans {
    using NumbersLib for int256;
    using NumbersLib for uint256;

    bytes32 internal constant ID = keccak256("LOANS");
    uint32 internal constant SECONDS_PER_YEAR = 31536000;

    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    /**
     * @notice it returns the loan
     * @param loanID the ID of the respective loan
     * @return l_ the loan
     */
    function loan(uint256 loanID) internal view returns (Loan storage l_) {
        l_ = s().loans[loanID];
    }

    /**
     * @notice it returns the loan debt from a respective loan
     * @param loanID the ID of the respective loan
     * @return d_ the loan debt from a respective loan
     */
    function debt(uint256 loanID) internal view returns (LoanDebt storage d_) {
        d_ = s().loanDebt[loanID];
    }

    // DEPRECATED
    function terms(uint256 loanID)
        internal
        view
        returns (LoanTerms storage t_)
    {
        t_ = s()._loanTerms[loanID];
    }

    /**
     * @notice Returns the total amount owed for a specified loan.
     * @param loanID The loan ID to get the total amount owed.
     * @return owed_ uint256 The total owed amount.
     */
    function getTotalOwed(uint256 loanID)
        internal
        view
        returns (uint256 owed_)
    {
        if (loan(loanID).status == LoanStatus.Active) {
            owed_ = debt(loanID).principalOwed + (debt(loanID).interestOwed);
        }
    }

    /**
     * @notice Returns the amount of interest owed for a given loan and loan amount.
     * @param loanID The loan ID to get the owed interest.
     * @param amountBorrow The principal of the loan to take out.
     * @return uint256 The interest owed.
     */
    function getInterestOwedFor(uint256 loanID, uint256 amountBorrow)
        internal
        view
        returns (uint256)
    {
        return amountBorrow.percent(uint16(getInterestRatio(loanID)));
    }

    function getCollateralNeeded(uint256 loanID)
        internal
        returns (uint256 _needed)
    {
        (, _needed, ) = getCollateralNeededInfo(loanID);
    }

    /**
     * @notice it returns the total collateral needed in lending tokens, in collateral tokens and in escrowed loan values
     * @param loanID the loanID to get the total collateral needed
     * @return neededInLendingTokens total collateral needed in lending tokens
     * @return neededInCollateralTokens total collateral needed in collateral tokens
     * @return escrowLoanValue total collateral needed in loan value
     */
    function getCollateralNeededInfo(uint256 loanID)
        internal
        returns (
            uint256 neededInLendingTokens,
            uint256 neededInCollateralTokens,
            uint256 escrowLoanValue
        )
    {
        (neededInLendingTokens, escrowLoanValue) = getCollateralNeededInTokens(
            loanID
        );

        // check if needed lending tokens is zero. if true, then needed collateral tokens is zero. else,
        if (neededInLendingTokens == 0) {
            neededInCollateralTokens = 0;
        } else {
            neededInCollateralTokens = AppStorageLib.store()
                .priceAggregator
                .getValueFor(
                    loan(loanID).lendingToken,
                    loan(loanID).collateralToken,
                    neededInLendingTokens
                );
        }
    }

    /**
     * @notice Returns the minimum collateral value threshold, in the lending token, needed to take out the loan or for it be liquidated.
     * @dev If the loan status is TermsSet, then the value is whats needed to take out the loan.
     * @dev If the loan status is Active, then the value is the threshold at which the loan can be liquidated at.
     * @param loanID The loan ID to get needed collateral info for.
     * @return neededInLendingTokens int256 The minimum collateral value threshold required.
     * @return escrowLoanValue uint256 The value of the loan held in the escrow contract.
     */
    function getCollateralNeededInTokens(uint256 loanID)
        internal
        returns (uint256 neededInLendingTokens, uint256 escrowLoanValue)
    {
        if (loan(loanID).collateralRatio == 0) {
            return (0, 0);
        }

        /*
            The collateral to principal owed ratio is the sum of:
                * collateral buffer percent
                * loan interest rate
                * liquidation reward percent
                * X factor of additional collateral
        */
        // * To take out a loan (if status == TermsSet), the required collateral is (max loan amount * the collateral ratio).
        // * For the loan to not be liquidated (when status == Active), the minimum collateral is (principal owed * (X collateral factor + liquidation reward)).
        // * If the loan has an escrow account, the minimum collateral is ((principal owed - escrow value) * (X collateral factor + liquidation reward)).
        if (loan(loanID).status == LoanStatus.TermsSet) {
            neededInLendingTokens = loan(loanID).borrowedAmount.percent(
                loan(loanID).collateralRatio
            );
        } else if (loan(loanID).status == LoanStatus.Active) {
            uint16 requiredRatio = loan(loanID).collateralRatio -
                getInterestRatio(loanID) -
                uint16(PlatformSettingsLib.getCollateralBufferValue());

            neededInLendingTokens =
                debt(loanID).principalOwed +
                debt(loanID).interestOwed;
            escrowLoanValue = LibEscrow.calculateTotalValue(loanID);
            if (
                escrowLoanValue > 0 && neededInLendingTokens > escrowLoanValue
            ) {
                neededInLendingTokens -= escrowLoanValue;
            }
            neededInLendingTokens = neededInLendingTokens.percent(
                requiredRatio
            );
        }
    }

    /**
     * @notice check if a loan can go to end of auction with a collateral ratio
     * @return bool checking if collateralRatio is >= the over collateralized buffer value
     */
    function canGoToEOAWithCollateralRatio(uint256 collateralRatio)
        internal
        view
        returns (bool)
    {
        return
            collateralRatio >=
            PlatformSettingsLib.getOverCollateralizedBufferValue();
    }

    /**
     * @notice Returns the interest ratio based on the loan interest rate for the loan duration.
     * @notice There is a minimum threshold of 1%.
     * @dev The interest rate is APY (annual percentage yield).
     * @param loanID The loan ID to get the interest rate for.
     */
    function getInterestRatio(uint256 loanID)
        internal
        view
        returns (uint16 ratio_)
    {
        if (loan(loanID).interestRate > 0) {
            ratio_ = uint16(
                (uint64(loan(loanID).duration) * loan(loanID).interestRate) /
                    SECONDS_PER_YEAR
            );

            // If calculation for interest ratio chopped off decimals resulting in 0%, set minimum interest to 1%
            if (ratio_ == 0) {
                ratio_ = 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { CreateLoanWithNFTFacet } from "../CreateLoanWithNFTFacet.sol";
import { TellerNFT_V2 } from "../../nft/TellerNFT_V2.sol";

// Libraries
import { NFTLib } from "../../nft/libraries/NFTLib.sol";

contract MainnetCreateLoanWithNFTFacet is CreateLoanWithNFTFacet {
    constructor(
        address tellerNFTV2Address,
        address daiAddress,
        address usdcAddress,
        address usdtAddress
    )
        CreateLoanWithNFTFacet(
            tellerNFTV2Address,
            daiAddress,
            usdcAddress,
            usdtAddress
        )
    {}

    /**
     * @notice Process the NFT data to calculate max loan size and apply to the loan
     * @dev Only knows how to process {tokenData} for NFT V1, otherwise calls super
     * @param loanID The ID for the loan to apply the NFTs to
     * @param version The token version used to know how to decode the data
     * @param tokenData Encoded token ID array. NFT V1 includes just the IDs
     * @return allowedLoanSize_ The max loan size calculated by the token IDs
     */
    function _takeOutLoanProcessNFTs(
        uint256 loanID,
        uint16 version,
        bytes memory tokenData
    ) internal virtual override returns (uint256 allowedLoanSize_) {
        uint256 v1Amount;
        if ((1 & version) == 1) {
            uint256[] memory nftIDs = abi.decode(tokenData, (uint256[]));
            for (uint256 i; i < nftIDs.length; i++) {
                NFTLib.applyToLoan(loanID, nftIDs[i], msg.sender);

                // add to allowedLoanSize
                allowedLoanSize_ += NFTLib.s().nftDictionary.tokenBaseLoanSize(
                    nftIDs[i]
                );
                v1Amount += allowedLoanSize_;
            }
        }
        allowedLoanSize_ =
            super._takeOutLoanProcessNFTs(loanID, version, tokenData) +
            v1Amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakeableNFT {
    function tokenBaseLoanSize(uint256 tokenId) external view returns (uint256);

    function tokenURIHash(uint256 tokenId)
        external
        view
        returns (string memory);

    function tokenContributionAsset(uint256 tokenId)
        external
        view
        returns (address);

    function tokenContributionSize(uint256 tokenId)
        external
        view
        returns (uint256);

    function tokenContributionMultiplier(uint256 tokenId)
        external
        view
        returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Interfaces
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITellerNFT {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    /**
     * @notice The contract metadata URI.
     * @return the contractURI in string
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice It returns information about a Tier with from a tier index
     * @param index Tier index to get info.
     * @return tier_ the tier which belongs to the respective index
     */
    function getTier(uint256 index) external view returns (Tier memory tier_);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     * @return index_ the index of the tier the tokenID belongs in
     * @return tier_ the tier where the tokenID belongs in
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        returns (uint256 index_, Tier memory tier_);

    /**
     * @notice It returns an array of hashes in a tier
     * @param tierIndex the tier index to get the tier hashes
     * @return hashes_ all the tokenID hashes
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory hashes_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     * @return owned the array of tokenIDs owned by the address
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned);

    /**
     * @notice It mints a new token for a Tier index.
     * @param tierIndex the tier index to mint the token in
     * @param owner the owner of the new token
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner) external;

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external;

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash) external;

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interfaces
import "./ITellerNFT.sol";

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                                  THIS CONTRACT IS UPGRADEABLE!                                  **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions of this    **/
/**  contract as this will cause the the storage slots to be overwritten on the proxy contract!!    **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice This contract is used by borrowers to call Dapp functions (using delegate calls).
 * @notice This contract should only be constructed using it's upgradeable Proxy contract.
 * @notice In order to call a Dapp function, the Dapp must be added in the DappRegistry instance.
 *
 * @author [email protected]
 */
contract TellerNFT is ITellerNFT, ERC721Upgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    /* Constants */

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    /* State Variables */

    // It holds the total number of tiers.
    Counters.Counter internal _tierCounter;

    // It holds the total number of tokens minted.
    Counters.Counter internal _tokenCounter;

    // It holds the information about a tier.
    mapping(uint256 => Tier) internal _tiers;

    // It holds which tier a token ID is in.
    mapping(uint256 => uint256) internal _tokenTier;

    // It holds a set of token IDs for an owner address.
    mapping(address => EnumerableSet.UintSet) internal _ownerTokenIDs;

    // Link to the contract metadata
    string private _metadataBaseURI;

    // Hash to the contract metadata located on the {_metadataBaseURI}
    string private _contractURIHash;

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "TellerNFT: not admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER, _msgSender()), "TellerNFT: not minter");
        _;
    }

    /* External Functions */

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param index Tier index to get info.
     * @return tier_ the tier which belongs to the respective index
     */
    function getTier(uint256 index)
        external
        view
        override
        returns (Tier memory tier_)
    {
        tier_ = _tiers[index];
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     * @return index_ the index of the tier the tokenID belongs in
     * @return tier_ the tier where the tokenID belongs in
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        override
        returns (uint256 index_, Tier memory tier_)
    {
        index_ = _tokenTier[tokenId];
        tier_ = _tiers[index_];
    }

    /**
     * @notice It returns an array of hashes in a tier
     * @param tierIndex the tier index to get the tier hashes
     * @return hashes_ all the tokenID hashes
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        override
        returns (string[] memory hashes_)
    {
        hashes_ = _tiers[tierIndex].hashes;
    }

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     * @return owned_ the array of tokenIDs owned by the address
     */
    function getOwnedTokens(address owner)
        external
        view
        override
        returns (uint256[] memory owned_)
    {
        EnumerableSet.UintSet storage set = _ownerTokenIDs[owner];
        owned_ = new uint256[](set.length());
        for (uint256 i; i < owned_.length; i++) {
            owned_[i] = set.at(i);
        }
    }

    /**
     * @notice The contract metadata URI.
     * @return the contract URI hash
     */
    function contractURI() external view override returns (string memory) {
        return _contractURIHash;
    }

    /**
     * @notice The token URI is based on the token ID.
     * @param tokenId the token identifier that returns the hash of the baseURI and the tokenURI hash
     * @return the tokenURI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TellerNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenURIHash(tokenId)))
                : "";
    }

    /**
     * @notice It mints a new token for a Tier index.
     * @param tierIndex Tier to mint token on.
     * @param owner The owner of the new token.
     *
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner)
        external
        override
        onlyMinter
    {
        // Get the new token ID
        uint256 tokenId = _tokenCounter.current();
        _tokenCounter.increment();

        // Mint and set the token to the tier index
        _safeMint(owner, tokenId);
        _tokenTier[tokenId] = tierIndex;

        // Set owner
        _setOwner(owner, tokenId);
    }

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external override onlyMinter {
        Tier storage tier = _tiers[_tierCounter.current()];

        tier.baseLoanSize = newTier.baseLoanSize;
        tier.hashes = newTier.hashes;
        tier.contributionAsset = newTier.contributionAsset;
        tier.contributionSize = newTier.contributionSize;
        tier.contributionMultiplier = newTier.contributionMultiplier;

        _tierCounter.increment();
    }

    /**
     * @notice it removes the minter by revoking the role of the address assigned to MINTER
     * @param minter the address of the minter
     */
    function removeMinter(address minter) external onlyMinter {
        revokeRole(MINTER, minter);
    }

    /**
     * @notice it adds the minter to the rule
     * @param minter the address of the minter to add to the role of MINTER
     */
    function addMinter(address minter) public onlyMinter {
        _setupRole(MINTER, minter);
    }

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash)
        external
        override
        onlyAdmin
    {
        _contractURIHash = contractURIHash;
    }

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters)
        external
        virtual
        override
        initializer
    {
        __ERC721_init("Teller NFT", "TNFT");
        __AccessControl_init();

        for (uint256 i; i < minters.length; i++) {
            _setupRole(MINTER, minters[i]);
        }

        _metadataBaseURI = "https://gateway.pinata.cloud/ipfs/";
        _contractURIHash = "QmWAfQFFwptzRUCdF2cBFJhcB2gfHJMd7TQt64dZUysk3R";
    }

    /**
     * @notice checks if an interface is supported by ITellerNFT, ERC721Upgradeable or AccessControlUpgradeable
     * @param interfaceId the identifier of the interface
     * @return bool stating whether or not our interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(ITellerNFT).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice It returns the hash to use for the token URI.
     * @param tokenId the tokenId to get the tokenURI hash
     * @return the tokenURIHash of our NFT
     */
    function _tokenURIHash(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string[] storage tierImageHashes = _tiers[_tokenTier[tokenId]].hashes;
        return tierImageHashes[tokenId.mod(tierImageHashes.length)];
    }

    /**
     * @notice The base URI path where the token media is hosted.
     * @dev Base URI for computing {tokenURI}
     * @return our metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    /**
     * @notice Moves token to new owner set and then transfers.
     * @param from address to transfer from
     * @param to address to transfer to
     * @param tokenId tokenID to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        _setOwner(to, tokenId);
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice It removes the token from the current owner set and adds to new owner.
     * @param newOwner the new owner of the tokenID
     * @param tokenId the ID of the NFT
     */
    function _setOwner(address newOwner, uint256 tokenId) internal {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != address(0)) {
            _ownerTokenIDs[currentOwner].remove(tokenId);
        }
        _ownerTokenIDs[newOwner].add(tokenId);
    }

    function _msgData() internal pure override returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @notice TellerNFTDictionary Version 1.02
 *
 * @notice This contract is used to gather data for TellerV1 NFTs more efficiently.
 * @notice This contract has data which must be continuously synchronized with the TellerV1 NFT data
 *
 * @author [email protected]
 */

pragma solidity ^0.8.0;

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Interfaces
import "./IStakeableNFT.sol";

/**
 * @notice This contract is used by borrowers to call Dapp functions (using delegate calls).
 * @notice This contract should only be constructed using it's upgradeable Proxy contract.
 * @notice In order to call a Dapp function, the Dapp must be added in the DappRegistry instance.
 *
 * @author [email protected]
 */
contract TellerNFTDictionary is IStakeableNFT, AccessControlUpgradeable {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    mapping(uint256 => uint256) public baseLoanSizes;
    mapping(uint256 => string[]) public hashes;
    mapping(uint256 => address) public contributionAssets;
    mapping(uint256 => uint256) public contributionSizes;
    mapping(uint256 => uint8) public contributionMultipliers;

    /* Constants */

    bytes32 public constant ADMIN = keccak256("ADMIN");

    /* State Variables */

    mapping(uint256 => uint256) public _tokenTierMappingCompressed;
    bool public _tokenTierMappingCompressedSet;

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "TellerNFTDictionary: not admin");
        _;
    }

    function initialize(address initialAdmin) public {
        _setupRole(ADMIN, initialAdmin);
        _setRoleAdmin(ADMIN, ADMIN);

        __AccessControl_init();
    }

    /* External Functions */

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTierIndex(uint256 tokenId)
        public
        view
        returns (uint8 index_)
    {
        //32 * 8 = 256 - each uint256 holds the data of 32 tokens . 8 bits each.

        uint256 mappingIndex = tokenId / 32;

        uint256 compressedRegister = _tokenTierMappingCompressed[mappingIndex];

        //use 31 instead of 32 to account for the '0x' in the start.
        //the '31 -' reverses our bytes order which is necessary

        uint256 offset = ((31 - (tokenId % 32)) * 8);

        uint8 tierIndex = uint8((compressedRegister >> offset));

        return tierIndex;
    }

    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory)
    {
        return hashes[tierIndex];
    }

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTier(uint256 index, Tier memory newTier)
        external
        onlyAdmin
        returns (bool)
    {
        baseLoanSizes[index] = newTier.baseLoanSize;
        hashes[index] = newTier.hashes;
        contributionAssets[index] = newTier.contributionAsset;
        contributionSizes[index] = newTier.contributionSize;
        contributionMultipliers[index] = newTier.contributionMultiplier;

        return true;
    }

    /**
     * @notice Sets the tiers for each tokenId using compressed data.
     * @param tiersMapping Information about the new tiers to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setAllTokenTierMappings(uint256[] memory tiersMapping)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            !_tokenTierMappingCompressedSet,
            "TellerNFTDictionary: token tier mapping already set"
        );
        for (uint256 i = 0; i < tiersMapping.length; i++) {
            _tokenTierMappingCompressed[i] = tiersMapping[i];
        }

        _tokenTierMappingCompressedSet = true;
        return true;
    }

    /**
     * @notice Sets the tiers for each tokenId using compressed data.
     * @param index the mapping row, each holds data for 32 tokens
     * @param tierMapping Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierMapping(uint256 index, uint256 tierMapping)
        public
        onlyAdmin
        returns (bool)
    {
        _tokenTierMappingCompressed[index] = tierMapping;

        return true;
    }

    /**
     * @notice Sets a specific tier for a specific tokenId using compressed data.
     * @param tokenIds the NFT token Ids for which to add data
     * @param tokenTier the index of the tier that these tokenIds should have
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierForTokenIds(
        uint256[] calldata tokenIds,
        uint256 tokenTier
    ) public onlyAdmin returns (bool) {
        for (uint256 i; i < tokenIds.length; i++) {
            setTokenTierForTokenId(tokenIds[i], tokenTier);
        }

        return true;
    }

    /**
     * @notice Sets a specific tier for a specific tokenId using compressed data.
     * @param tokenId the NFT token Id for which to add data
     * @param tokenTier the index of the tier that these tokenIds should have
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierForTokenId(uint256 tokenId, uint256 tokenTier)
        public
        onlyAdmin
        returns (bool)
    {
        uint256 mappingIndex = tokenId / 32;

        uint256 existingRegister = _tokenTierMappingCompressed[mappingIndex];

        uint256 offset = ((31 - (tokenId % 32)) * 8);


            uint256 updateMaskShifted
         = 0x00000000000000000000000000000000000000000000000000000000000000FF <<
            offset;

        uint256 updateMaskShiftedNegated = ~updateMaskShifted;


            uint256 tokenTierShifted
         = ((0x0000000000000000000000000000000000000000000000000000000000000000 |
            tokenTier) << offset);

        uint256 existingRegisterClearedWithMask = existingRegister &
            updateMaskShiftedNegated;

        uint256 updatedRegister = existingRegisterClearedWithMask |
            tokenTierShifted;

        _tokenTierMappingCompressed[mappingIndex] = updatedRegister;

        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStakeableNFT).interfaceId ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
        New methods for the dictionary
    */

    /**
     * @notice It returns Base Loan Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenBaseLoanSize(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return baseLoanSizes[tokenTier];
    }

    /**
     * @notice It returns Token URI Hash for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenURIHash(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        string[] memory tierImageHashes = hashes[tokenTier];
        return tierImageHashes[tokenId % (tierImageHashes.length)];
    }

    /**
     * @notice It returns Contribution Asset for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionAsset(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionAssets[tokenTier];
    }

    /**
     * @notice It returns Contribution Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionSize(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionSizes[tokenTier];
    }

    /**
     * @notice It returns Contribution Multiplier for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionMultiplier(uint256 tokenId)
        public
        view
        override
        returns (uint8)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionMultipliers[tokenTier];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {
    ERC1155Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Libraries
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                                  THIS CONTRACT IS UPGRADEABLE!                                  **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions of this    **/
/**  contract as this will cause the the storage slots to be overwritten on the proxy contract!!    **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice This is the logic for the Teller NFT Version 2.
 * @notice This contract contains the base logic of an ERC1155 NFT that works for all
 *  networks. Some functionality is required on a specific network, therefore, there may
 *  exist a child contract that inherits from this.
 * @notice The TellerNFT_V2 is meant to be used for taking out loans on the Teller Protocol
 *  without the need for a bank account or collateral. The max loan size using an NFT is
 *  is determined by the `tokenBaseLoanSize`.
 *
 * @author [email protected]
 */
abstract contract TellerNFT_V2 is ERC1155Upgradeable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    /* Constants */
    string public constant name = "Teller NFT";
    string public constant symbol = "TNFT";

    uint256 private constant ID_PADDING = 10000;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    /* State Variables */

    struct Tier {
        uint256 baseLoanSize;
        address contributionAsset;
        uint256 contributionSize;
        uint16 contributionMultiplier;
    }

    // It holds the total number of tokens in existence.
    uint256 public totalSupply;

    // It holds the information about a tier.
    mapping(uint256 => Tier) public tiers;

    // It holds the total number of tiers.
    uint128 public tierCount;

    // It holds how many tokens types exists in a tier.
    mapping(uint128 => uint256) public tierTokenCount;

    // It holds a set of tokenIds for an owner address
    mapping(address => EnumerableSet.UintSet) internal _ownedTokenIds;

    // It holds the URI hash containing the token metadata
    mapping(uint256 => string) internal _idToUriHash;

    // It is a reverse lookup of the token ID given the metadata hash
    mapping(string => uint256) internal _uriHashToId;

    // Hash to the contract metadata
    string private _contractURIHash;

    /* Public Functions */

    /**
     * @notice checks if an interface is supported by ITellerNFT or AccessControlUpgradeable
     * @param interfaceId the identifier of the interface
     * @return bool stating whether or not our interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(super.uri(tokenId), _idToUriHash[tokenId]));
    }

    /* External Functions */

    /**
     * @notice The contract metadata URI.
     * @return the contract URI hash
     */
    function contractURI() external view returns (string memory) {
        // URI returned from parent just returns base URI
        return string(abi.encodePacked(super.uri(0), _contractURIHash));
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     * @return tierId_ the index of the tier the tokenId belongs to
     * @return tierTokenId_ the tokenId in tier
     */
    function getTokenTierId(uint256 tokenId)
        external
        view
        returns (uint128 tierId_, uint128 tierTokenId_)
    {
        (tierId_, tierTokenId_) = _splitTokenId(tokenId);
    }

    /**
     * @notice It returns Base Loan Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenBaseLoanSize(uint256 tokenId) public view returns (uint256) {
        (uint128 tierId, ) = _splitTokenId(tokenId);
        return tiers[tierId].baseLoanSize;
    }

    /**
     * @notice It returns Contribution Asset for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionAsset(uint256 tokenId)
        public
        view
        returns (address)
    {
        (uint128 tierId, ) = _splitTokenId(tokenId);
        return tiers[tierId].contributionAsset;
    }

    /**
     * @notice It returns Contribution Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionSize(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (uint128 tierId, ) = _splitTokenId(tokenId);
        return tiers[tierId].contributionSize;
    }

    /**
     * @notice It returns Contribution Multiplier for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionMultiplier(uint256 tokenId)
        public
        view
        returns (uint16)
    {
        (uint128 tierId, ) = _splitTokenId(tokenId);
        return tiers[tierId].contributionMultiplier;
    }

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     * @return owned_ the array of tokenIDs owned by the address
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned_)
    {
        EnumerableSet.UintSet storage set = _ownedTokenIds[owner];
        owned_ = new uint256[](set.length());
        for (uint256 i; i < owned_.length; i++) {
            owned_[i] = set.at(i);
        }
    }

    /**
     * @notice Creates new Tiers to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTiers Information about the new tiers to add.
     * @param tierHashes Metadata hashes belonging to the tiers.
     *
     * Requirements:
     *  - Caller must have the {ADMIN} role
     */
    function createTiers(
        Tier[] calldata newTiers,
        string[][] calldata tierHashes
    ) external onlyRole(ADMIN) {
        require(
            newTiers.length == tierHashes.length,
            "Teller: array length mismatch"
        );

        for (uint256 i; i < newTiers.length; i++) {
            _createTier(newTiers[i], tierHashes[i]);
        }
    }

    /**
     * @notice creates the tier along with the tier hashes, then saves the tokenId
     * information in id -> hash and hash -> id mappings
     * @param newTier the Tier struct containing all the tier information
     * @param tierHashes the tier hashes to add to the tier
     */
    function _createTier(Tier calldata newTier, string[] calldata tierHashes)
        internal
    {
        // Increment tier counter to use
        tierCount++;
        Tier storage tier = tiers[tierCount];
        tier.baseLoanSize = newTier.baseLoanSize;
        tier.contributionAsset = newTier.contributionAsset;
        tier.contributionSize = newTier.contributionSize;
        tier.contributionMultiplier = newTier.contributionMultiplier;

        // Store how many tokens are on the tier
        tierTokenCount[tierCount] = tierHashes.length;
        // Set the token URI hash
        for (uint128 i; i < tierHashes.length; i++) {
            uint256 tokenId = _mergeTokenId(tierCount, i);
            _idToUriHash[tokenId] = tierHashes[i];
            _uriHashToId[tierHashes[i]] = tokenId;
        }
    }

    /**
     * @dev See {_setURI}.
     *
     * Requirements:
     *
     * - `newURI` must be prepended with a forward slash (/)
     */
    function setURI(string memory newURI) external onlyRole(ADMIN) {
        _setURI(newURI);
    }

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash)
        public
        onlyRole(ADMIN)
    {
        _contractURIHash = contractURIHash;
    }

    /**
     * @notice Initializes the TellerNFT.
     * @param data Bytes to init the token with.
     */
    function initialize(bytes calldata data) public virtual initializer {
        // Set the initial URI
        __ERC1155_init("https://gateway.pinata.cloud/ipfs/");
        __AccessControl_init();

        // Set admin role for admins
        _setRoleAdmin(ADMIN, ADMIN);
        // Set the initial admin
        _setupRole(ADMIN, _msgSender());

        // Set initial contract URI hash
        setContractURIHash("QmWAfQFFwptzRUCdF2cBFJhcB2gfHJMd7TQt64dZUysk3R");

        __TellerNFT_V2_init_unchained(data);
    }

    function __TellerNFT_V2_init_unchained(bytes calldata data)
        internal
        virtual
        initializer
    {}

    /* Internal Functions */

    /**
     * @notice it removes a token ID from the ownedTokenIds mapping if the balance of
     * the user's tokenId is 0
     * @param account the address to add the token id to
     * @param id the token ID
     */
    function _removeOwnedTokenCheck(address account, uint256 id) private {
        if (balanceOf(account, id) == 0) {
            _ownedTokenIds[account].remove(id);
        }
    }

    /**
     * @notice it adds a token id to the ownedTokenIds mapping
     * @param account the address to the add the token ID to
     * @param id the token ID
     */
    function _addOwnedToken(address account, uint256 id) private {
        _ownedTokenIds[account].add(id);
    }

    /**
     * @dev Runs super function and then increases total supply.
     *
     * See {ERC1155Upgradeable._mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);

        // add the id to the owned token ids of the user
        _addOwnedToken(account, id);

        totalSupply += amount;
    }

    /**
     * @dev Runs super function and then increases total supply.
     *
     * See {ERC1155Upgradeable._mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._mintBatch(to, ids, amounts, data);

        for (uint256 i; i < amounts.length; i++) {
            totalSupply += amounts[i];
            _addOwnedToken(to, ids[i]);
        }
    }

    /**
     * @dev Runs super function and then decreases total supply.
     *
     * See {ERC1155Upgradeable._burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _removeOwnedTokenCheck(account, id);
        totalSupply -= amount;
    }

    /**
     * @dev Runs super function and then decreases total supply.
     *
     * See {ERC1155Upgradeable._burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        super._burnBatch(account, ids, amounts);

        for (uint256 i; i < amounts.length; i++) {
            totalSupply -= amounts[i];
            _removeOwnedTokenCheck(account, ids[i]);
        }
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * See {ERC1155Upgradeable._safeTransferFrom}.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._safeTransferFrom(from, to, id, amount, data);
        _removeOwnedTokenCheck(from, id);
        _addOwnedToken(to, id);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *  See {ERC1155Upgradeable._safeBatchTransferFrom}
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i; i < ids.length; i++) {
            _removeOwnedTokenCheck(from, ids[i]);
            _addOwnedToken(to, ids[i]);
        }
    }

    /**
     * @dev Checks if a token ID exists. To exists the ID must have a URI hash associated.
     * @param tokenId ID of the token to check.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return bytes(_idToUriHash[tokenId]).length > 0;
    }

    /**
     * @dev Creates a V2 token ID from a tier ID and tier token ID.
     * @param tierId Index of the tier to use.
     * @param tierTokenId ID of the token within the given tier.
     * @return tokenId_ V2 NFT token ID.
     */
    function _mergeTokenId(uint128 tierId, uint128 tierTokenId)
        internal
        pure
        returns (uint256 tokenId_)
    {
        tokenId_ = tierId * ID_PADDING;
        tokenId_ += tierTokenId;
    }

    /**
     * @dev Creates a V2 token ID from a tier ID and tier token ID.
     * @param tokenId V2 NFT token ID.
     * @return tierId_ Index of the token tier.
     * @return tierTokenId_ ID of the token within the tier.
     */
    function _splitTokenId(uint256 tokenId)
        internal
        pure
        returns (uint128 tierId_, uint128 tierTokenId_)
    {
        tierId_ = SafeCast.toUint128(tokenId / ID_PADDING);
        tierTokenId_ = SafeCast.toUint128(tokenId % ID_PADDING);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../TellerNFT.sol";

// Libraries
import {
    MerkleProof
} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Storage
import { AppStorageLib, AppStorage } from "../../storage/app.sol";
import { NFTStorageLib, NFTStorage } from "../../storage/nft.sol";

library NFTLib {
    function s() internal pure returns (NFTStorage storage s_) {
        s_ = NFTStorageLib.store();
    }

    function nft() internal view returns (TellerNFT nft_) {
        nft_ = AppStorageLib.store().nft;
    }

    /**s
     * @notice Adds the {nftID} to the list of the owner's stakedNFTs
     * @param nftID the ID of the NFT to stake
     * @param owner the owner of the NFT who will stake the NFT
     */
    function stake(uint256 nftID, address owner) internal {
        // Add NFT ID to user set
        EnumerableSet.add(s().stakedNFTs[owner], nftID);
    }

    /**
     * @notice Adds the {nftID} to the list of the owner's stakedNFTs
     * @param nftID the ID of the NFT to stake
     * @param amount the quantity of ERC1155 NFT to stake
     * @param owner the owner of the NFT who will stake the NFT
     */
    function stakeV2(
        uint256 nftID,
        uint256 amount,
        address owner
    ) internal {
        // Add NFT ID and quantity to user set
        s().stakedNFTsV2Amounts[owner][nftID] += amount;
        EnumerableSet.add(s().stakedNFTsV2[owner], nftID);
    }

    /**
     * @notice it unstakes the NFT by removing the NFT ID from the list of the user's staked NFTs
     * @param nftID the ID of the NFT to remove from the list of the user's staked NFTs
     * @param owner the account which originally staked the NFT
     * @return success_ the boolean value telling us if the user has unsuccessfully unstaked the NFT
     */
    function unstake(uint256 nftID, address owner)
        internal
        returns (bool success_)
    {
        success_ = EnumerableSet.remove(s().stakedNFTs[owner], nftID);
    }

    /**
     * @notice it unstakes the NFT by removing the NFT ID from the list of the user's staked NFTs
     * @param nftID the ID of the NFT to remove from the list of the user's staked NFTs
     * @param amount the quantity of ERC1155 NFT to unstake
     * @return success_ the boolean value telling us if the user has unsuccessfully unstaked the NFT
     */
    function unstakeV2(
        uint256 nftID,
        uint256 amount,
        address owner
    ) internal returns (bool success_) {
        // Check if owner has the staked balance
        success_ = s().stakedNFTsV2Amounts[owner][nftID] >= amount;

        // Subtract the amount from owner's staked balance
        if (success_) {
            s().stakedNFTsV2Amounts[owner][nftID] -= amount;

            // If the staked token balance is now 0, remove the ID from mapping
            if (s().stakedNFTsV2Amounts[owner][nftID] == 0) {
                EnumerableSet.remove(s().stakedNFTsV2[owner], nftID);
            }
        }
    }

    /**
     * @notice if the user fails to pay his loan, then we liquidate the all the NFTs associated with the loan
     * @param loanID the identifier of the loan to liquidate the NFTs from
     */
    function liquidateNFT(uint256 loanID) internal {
        // Check if NFTs are linked
        EnumerableSet.UintSet storage nfts = s().loanNFTs[loanID];
        for (uint256 i; i < EnumerableSet.length(nfts); i++) {
            NFTLib.nft().transferFrom(
                address(this),
                AppStorageLib.store().nftLiquidationController,
                EnumerableSet.at(nfts, i)
            );
        }
    }

    /**
     * @notice It unstakes an NFT and verifies the proof in order to apply the proof to a loan
     * @param loanID the identifier of the loan
     * @param nftID the NFT ID to apply to the loan
     * @param owner the account which originally staked the NFT
     */
    function applyToLoan(
        uint256 loanID,
        uint256 nftID,
        address owner
    ) internal {
        // NFT must be currently staked
        // Remove NFT from being staked - returns bool
        require(unstake(nftID, owner), "Teller: borrower nft not staked");

        // Apply NFT to loan
        EnumerableSet.add(s().loanNFTs[loanID], nftID);
    }

    /**
     * @notice it unstakes an NFT and verifies the proof in order to apply the proof to a loan
     * @param loanID the identifier of the loan
     * @param nftID the NFT ID to apply to the loan
     */
    function applyToLoanV2(
        uint256 loanID,
        uint256 nftID,
        uint256 amount,
        address borrower
    ) internal {
        // NFT must be currently staked
        // Remove NFT from being staked - returns bool
        require(
            unstakeV2(nftID, amount, borrower),
            "Teller: borrower nft not staked"
        );

        // Apply NFT to loan
        EnumerableSet.add(s().loanNFTsV2[loanID], nftID);
        s().loanNFTsV2Amounts[loanID][nftID] = amount;
    }

    /**
     * @notice it finds the loan's NFTs and adds them back to the owner's list of staked NFTs
     * @param loanID the identifier of the respective loan to add the NFTs back to the user's staked NFTs
     * @param owner the owner to add the unstaked NFTs back to the staked pile
     */
    function restakeLinked(uint256 loanID, address owner) internal {
        // Get linked NFT
        EnumerableSet.UintSet storage nfts = s().loanNFTs[loanID];
        for (uint256 i; i < EnumerableSet.length(nfts); i++) {
            // Restake the NFT
            EnumerableSet.add(s().stakedNFTs[owner], EnumerableSet.at(nfts, i));
        }
    }

    /**
     * @notice it finds the loan's NFTs and adds them back to the owner's list of staked NFTs
     * @param loanID the identifier of the respective loan to add the NFTs back to the user's staked NFTs
     * @param owner the owner to add the unstaked NFTs back to the staked pile
     */
    function restakeLinkedV2(uint256 loanID, address owner) internal {
        // Get linked NFT
        EnumerableSet.UintSet storage loanNFTs = s().loanNFTsV2[loanID];
        for (uint256 i; i < EnumerableSet.length(loanNFTs); i++) {
            uint256 nftV2ID = EnumerableSet.at(loanNFTs, i);

            // Make sure NFT ID is staked
            EnumerableSet.add(s().stakedNFTsV2[owner], nftV2ID);

            // Increment the staked amount from amount linked to loan
            s().stakedNFTsV2Amounts[owner][nftV2ID] += s().loanNFTsV2Amounts[
                loanID
            ][nftV2ID];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IsaLPPricer {
    /**
     * @notice It returns the exchange rate of the single asset liquidity provider token.
     * @param saLPToken address of the single asset liquidity provider token.
     * @return Exchange rate for 1 saLP token in the underlying asset.
     */
    function getRateFor(address saLPToken) external view returns (uint256);

    /**
     * @notice It calculates the value of the protocol token amount into the underlying asset.
     * @param saLPToken address of the single asset liquidity provider token
     * @param amount Amount of the token to convert into the underlying asset.
     * @return Value of the saLP token in the underlying asset.
     */
    function getValueOf(address saLPToken, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @notice It calculates the balance of the underlying asset for {account}.
     * @param saLPToken Address of the single asset liquidity provider token.
     * @param account Address of the account to get the balance of.
     * @return Balance of the underlying asset.
     */
    function getBalanceOfUnderlying(address saLPToken, address account)
        external
        returns (uint256);

    /**
     * @notice Gets the underlying asset address for the {saLPToken}.
     * @param saLPToken address of the single asset liquidity provider token.
     * @return Address of the underlying asset.
     */
    function getUnderlying(address saLPToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { ChainlinkPricer } from "./pricers/ChainlinkPricer.sol";
import {
    Initializable
} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {
    RolesFacet,
    RolesLib
} from "../contexts2/access-control/roles/RolesFacet.sol";
import { ADMIN } from "../shared/roles.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Interfaces
import { IsaLPPricer } from "./IsaLPPricer.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// Libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract PriceAggregator is RolesFacet, Initializable {
    address private immutable DEPLOYER;
    uint256 internal constant TEN = 10;
    address public immutable wETH;

    mapping(address => IsaLPPricer) public saLPPricer;
    ChainlinkPricer public chainlinkPricer;

    constructor(address wETHAddress) {
        DEPLOYER = msg.sender;
        wETH = wETHAddress;
    }

    function initialize(address chainlinkPricerAddress) external initializer {
        // Checks that the account initializing is the contract deployer
        require(msg.sender == DEPLOYER, "not deployer");
        // The account must first be grated the ADMIN role and then call {setChainlinkPricer}
        RolesLib.grantRole(ADMIN, DEPLOYER);
        setChainlinkPricer(chainlinkPricerAddress);
    }

    function setChainlinkPricer(address pricer)
        public
        authorized(ADMIN, msg.sender)
    {
        require(
            Address.isContract(pricer),
            "Teller: Chainlink pricer not contract"
        );
        chainlinkPricer = ChainlinkPricer(pricer);
    }

    function setAssetPricers(address pricer, address[] calldata assets)
        external
        authorized(ADMIN, msg.sender)
    {
        for (uint256 i; i < assets.length; i++) {
            setAssetPricer(assets[i], pricer);
        }
    }

    function setAssetPricer(address asset, address pricer)
        public
        authorized(ADMIN, msg.sender)
    {
        require(
            Address.isContract(pricer),
            "Teller: Chainlink pricer not contract"
        );
        saLPPricer[asset] = IsaLPPricer(pricer);
    }

    /**
     * @notice It returns the price of the token pair as given from the Chainlink Aggregator.
     * @dev It tries to use ETH as a pass through asset if the direct pair is not supported.
     * @param src Source token address.
     * @param dst Destination token address.
     * @return uint256 The latest answer as given from Chainlink.
     */
    function getPriceFor(address src, address dst)
        external
        view
        returns (uint256)
    {
        return _priceFor(src, dst);
    }

    /**
     * @notice It calculates the value of a token amount into another.
     * @param src Source token address.
     * @param dst Destination token address.
     * @param srcAmount Amount of the source token to convert into the destination token.
     * @return uint256 Value of the source token amount in destination tokens.
     */
    function getValueFor(
        address src,
        address dst,
        uint256 srcAmount
    ) external view returns (uint256) {
        return _valueFor(src, srcAmount, uint256(_priceFor(src, dst)));
    }

    /**
     * @notice It calculates the value of the {src} token balance in {dst} token for the {account}.
     * @param account Address of the account to get the balance value of.
     * @param src Source token address.
     * @param dst Destination token address.
     * @return Value of the {src} token balance denoted in {dst} tokens.
     */
    function getBalanceOfFor(
        address account,
        address src,
        address dst
    ) external returns (uint256) {
        IsaLPPricer srcPricer = saLPPricer[src];
        IsaLPPricer dstPricer = saLPPricer[dst];

        uint256 srcBalance;
        if (address(srcPricer) == address(0)) {
            srcBalance = ERC20(src).balanceOf(account);
        } else {
            srcBalance = srcPricer.getBalanceOfUnderlying(src, account);
            src = srcPricer.getUnderlying(src);
        }

        return _valueFor(src, srcBalance, uint256(_priceFor(src, dst)));
    }

    /**
     * @notice It calculates the value of a token amount into another.
     * @param src Source token address.
     * @param amount Amount of the source token to convert into the destination token.
     * @param exchangeRate The calculated exchange rate between the tokens.
     * @return uint256 Value of the source token amount given an exchange rate peg.
     */
    function _valueFor(
        address src,
        uint256 amount,
        uint256 exchangeRate
    ) internal view returns (uint256) {
        return (amount * exchangeRate) / _oneToken(src);
    }

    /**
     * @notice it returns 10^{numberOfDecimals} for a token
     * @param token the address to calculate the decimals for
     * @return 10^number of decimals used to calculate the price and value of different token pairs
     */
    function _oneToken(address token) internal view returns (uint256) {
        return TEN**_decimalsFor(token);
    }

    /**
     * @notice It gets the number of decimals for a given token.
     * @param addr Token address to get decimals for.
     * @return uint8 Number of decimals the given token.
     */
    function _decimalsFor(address addr) internal view returns (uint8) {
        return ERC20(addr).decimals();
    }

    /**
     * @notice it tries to calculate a price from Compound and Chainlink.
     * @dev if no price is found on compound, then calculate it on chainlink
     * @param src the token address to calculate the price for in dst
     * @param dst the token address to retrieve the price of src
     * @return price_ the price of src in dst
     */
    function _priceFor(address src, address dst)
        private
        view
        returns (uint256 price_)
    {
        IsaLPPricer srcPricer = saLPPricer[src];
        IsaLPPricer dstPricer = saLPPricer[dst];

        // ETH / ASSET
        if (src == wETH && address(dstPricer) == address(0)) {
            // Get destination asset Chainlink price in ETH
            uint256 dstEthPrice = chainlinkPricer.getEthPrice(dst);
            // Since the source asset is ETH and the price is in ETH, we need the inverse
            return _scale(_inverseRate(dstEthPrice, 18), 18, _decimalsFor(dst));
        }

        // ASSET / ETH
        if (dst == wETH && address(srcPricer) == address(0)) {
            // Get source asset Chainlink price in ETH
            uint256 srcEthPrice = chainlinkPricer.getEthPrice(src);
            return srcEthPrice;
        }

        // ASSET / ASSET
        if (
            address(srcPricer) == address(0) && address(dstPricer) == address(0)
        ) {
            // Get source asset Chainlink price in ETH
            uint256 srcEthPrice = chainlinkPricer.getEthPrice(src);
            // Get destination asset Chainlink price in ETH
            uint256 dstEthPrice = chainlinkPricer.getEthPrice(dst);
            // Merge the 2 rates
            return _mergeRates(srcEthPrice, dstEthPrice, dst);
        }

        // saLP / ASSET
        if (
            address(srcPricer) != address(0) && address(dstPricer) == address(0)
        ) {
            // Get the underlying source asset
            address srcUnderlying = srcPricer.getUnderlying(src);
            // Get source asset exchange rate for the underlying asset
            uint256 srcExchangeRate = srcPricer.getRateFor(src);
            if (srcUnderlying == dst) {
                return srcExchangeRate;
            } else {
                return
                    _mergeRates(
                        srcExchangeRate,
                        _priceFor(dst, srcUnderlying),
                        dst
                    );
            }
        }

        // Get the underlying destination asset
        address dstUnderlying = dstPricer.getUnderlying(dst);

        // ASSET / saLP
        if (
            address(srcPricer) == address(0) && address(dstPricer) != address(0)
        ) {
            // Get destination asset exchange rate for the underlying asset
            uint256 dstExchangeRate = dstPricer.getRateFor(dst);
            // If the source asset and underlying destination asset are the same, inverse the saLP asset rate
            if (src == dstUnderlying) {
                return
                    _inverseRate(
                        _scale(
                            dstExchangeRate,
                            _decimalsFor(dst),
                            _decimalsFor(src)
                        ),
                        _decimalsFor(src)
                    );
            } else {
                return
                    _mergeRates(
                        _priceFor(src, dstUnderlying),
                        dstExchangeRate,
                        dst
                    );
            }
        }

        // saLP / saLP

        // Get the underlying destination asset
        return
            _valueFor(
                dstUnderlying,
                _priceFor(src, dstUnderlying),
                _priceFor(dstUnderlying, dst)
            );
    }

    /**
     * @notice Scales the {value} by the difference in decimal values.
     * @param value the the value of the src in dst
     * @param srcDecimals src token decimals
     * @param dstDecimals dst token decimals
     * @return the price of src in dst after scaling the difference in decimal values
     */
    function _scale(
        uint256 value,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        if (dstDecimals > srcDecimals) {
            return value * (TEN**(dstDecimals - srcDecimals));
        } else {
            return value / (TEN**(srcDecimals - dstDecimals));
        }
    }

    function _inverseRate(uint256 rate, uint8 dstDecimals)
        internal
        pure
        returns (uint256)
    {
        return (TEN**(dstDecimals + dstDecimals)) / rate;
    }

    function _mergeRates(
        uint256 rate1,
        uint256 rate2,
        address dst
    ) internal view returns (uint256) {
        return
            rate1 == 0 ? rate2 : ((rate1 * (TEN**_decimalsFor(dst))) / rate2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import {
    AggregatorV2V3Interface as ChainlinkAgg
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Libraries
import { ENS } from "../../shared/libraries/ENSLib.sol";
import { StringsLib } from "../../shared/libraries/StringsLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract ChainlinkPricer {
    using StringsLib for string;

    // Chainlink ENS resolver
    address public immutable ENS_RESOLVER;
    // namehash of `data.eth` domain
    bytes32 public constant ENS_DOMAIN =
        0x4a9dd6923a809a49d009b308182940df46ac3a45ee16c1133f90db66596dae1f;

    constructor(address ensResolver) {
        require(
            Address.isContract(ensResolver),
            "Teller: resolver not contract"
        );
        ENS_RESOLVER = ensResolver;
    }

    function getEthPrice(address token) external view returns (uint256 price_) {
        (
            uint80 roundID,
            int256 rawPrice,
            uint256 startedAt,
            uint256 updateTime,
            uint80 answeredInRound
        ) = ChainlinkAgg(getEthAggregator(token)).latestRoundData();
        require(rawPrice > 0, "Chainlink price <= 0");
        require(updateTime != 0, "Incomplete round");
        require(answeredInRound + 2 >= roundID, "Stale price");
        price_ = SafeCast.toUint256(rawPrice);
    }

    function getEthAggregator(address token) public view returns (address) {
        string memory name = _getTokenSymbol(token).concat("-eth");
        return ENS.resolve(ENS_RESOLVER, ENS.subnode(name, ENS_DOMAIN));
    }

    function _getTokenSymbol(address token)
        internal
        view
        virtual
        returns (string memory)
    {
        string memory symbol_ = ERC20(token).symbol();
        if (symbol_.compareTo("WBTC")) {
            return "btc";
        }
        if (symbol_.compareTo("WMATIC")) {
            return "matic";
        }
        return symbol_.lower();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../../shared/libraries/CacheLib.sol";

// Storage
import { AppStorageLib } from "../../../storage/app.sol";

/**
 * @notice Utility library of inline functions for MaxDebtRatio asset setting.
 *
 * @author [email protected]
 */
library MaxDebtRatioLib {
    bytes32 private constant NAME = keccak256("MaxDebtRatio");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint16) {
        return uint16(s(asset).uints[NAME]);
    }

    function set(address asset, uint16 newValue) internal {
        s(asset).uints[NAME] = uint256(newValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../../shared/libraries/CacheLib.sol";

// Storage
import { AppStorageLib } from "../../../storage/app.sol";

/**
 * @notice Utility library of inline functions for MaxLoanAmount asset setting.
 *
 * @author [email protected]
 */
library MaxLoanAmountLib {
    bytes32 private constant NAME = keccak256("MaxLoanAmount");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint256) {
        return s(asset).uints[NAME];
    }

    function set(address asset, uint256 newValue) internal {
        s(asset).uints[NAME] = newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../storage/app.sol";

abstract contract PausableMods {
    /**
     * @notice Requires that the state of the protocol AND the given facet id equal {state}.
     * @param id id of the facet to check if is paused.
     * @param state Boolean that the protocol AND facet should be in.
     */
    modifier paused(bytes32 id, bool state) {
        require(
            __isPaused("") == state && __isPaused(id) == state,
            __pausedMessage(state)
        );
        _;
    }

    /**
     * @dev Checks if the given id is paused.
     * @param id Encoded id of the facet to check if is paused.
     * @return the bool to tell us if the facet is paused (true) or not (false)
     */
    function __isPaused(bytes32 id) private view returns (bool) {
        return AppStorageLib.store().paused[id];
    }

    /**
     * @dev Gets the message that should be reverted with given a state it should be in.
     * @param state Boolean that an id should be in.
     * @return a message stating whether the facet is paused or not
     */
    function __pausedMessage(bool state) private pure returns (string memory) {
        return state ? "Pausable: not paused" : "Pausable: paused";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../../storage/app.sol";
import "../names.sol" as NAMES;
import {
    RolesMods
} from "../../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN } from "../../../shared/roles.sol";
import { RolesLib } from "../../../contexts2/access-control/roles/RolesLib.sol";

// It defines a platform settings. It includes: value, min, and max values.
struct PlatformSetting {
    uint256 value;
    uint256 min;
    uint256 max;
    bool exists;
}

/**
 * @notice Utility library of inline functions on the PlatformSetting struct.
 *
 * @author [email protected]
 */
library PlatformSettingsLib {
    function s(bytes32 name) internal view returns (PlatformSetting storage) {
        return AppStorageLib.store().platformSettings[name];
    }

    /**
     * @notice It gets the current "NFTInterestRate" setting's value
     * @return value_ the current value.
     */
    function getNFTInterestRate() internal view returns (uint16 value_) {
        value_ = uint16(s(NAMES.NFT_INTEREST_RATE).value);
    }

    /**
     * @notice It gets the current "RequiredSubmissionsPercentage" setting's value
     * @return value_ the current value.
     */
    function getRequiredSubmissionsPercentageValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.REQUIRED_SUBMISSIONS_PERCENTAGE).value;
    }

    /**
     * @notice It gets the current "MaximumTolerance" setting's value
     * @return value_ the current value.
     */
    function getMaximumToleranceValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.MAXIMUM_TOLERANCE).value;
    }

    /**
     * @notice It gets the current "ResponseExpiryLength" setting's value
     * @return value_ the current value.
     */
    function getResponseExpiryLengthValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.RESPONSE_EXPIRY_LENGTH).value;
    }

    /**
     * @notice It gets the current "SafetyInterval" setting's value
     * @return value_ the current value.
     */
    function getSafetyIntervalValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.SAFETY_INTERVAL).value;
    }

    /**
     * @notice It gets the current "TermsExpiryTime" setting's value
     * @return value_ the current value.
     */
    function getTermsExpiryTimeValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.TERMS_EXPIRY_TIME).value;
    }

    /**
     * @notice It gets the current "LiquidateRewardPercent" setting's value
     * @return value_ the current value.
     */
    function getLiquidateRewardPercent()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.LIQUIDATE_REWARD_PERCENT).value;
    }

    /**
     * @notice It gets the current "MaximumLoanDuration" setting's value
     * @return value_ the current value.
     */
    function getMaximumLoanDurationValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.MAXIMUM_LOAN_DURATION).value;
    }

    /**
     * @notice It gets the current "RequestLoanTermsRateLimit" setting's value
     * @return value_ the current value.
     */
    function getRequestLoanTermsRateLimitValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.REQUEST_LOAN_TERMS_RATE_LIMIT).value;
    }

    /**
     * @notice It gets the current "CollateralBuffer" setting's value
     * @return value_ the current value.
     */
    function getCollateralBufferValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.COLLATERAL_BUFFER).value;
    }

    /**
     * @notice It gets the current "OverCollateralizedBuffer" setting's value
     * @return value_ the current value.
     */
    function getOverCollateralizedBufferValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.OVER_COLLATERALIZED_BUFFER).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
        @dev The setting name for loans taken out with an NFT.
        @dev This is the interest rate value that will be applied to loans taken out with an NFT.
     */
bytes32 constant NFT_INTEREST_RATE = keccak256("NFTInterestRate");

/**
        @dev The setting name for the required subsmission settings.
        @dev This is the minimum percentage of node responses that will be required by the platform to either take out a loan, and to claim accrued interest. If the number of node responses are less than the ones specified here, the loan or accrued interest claim request will be rejected by the platform
     */
bytes32 constant REQUIRED_SUBMISSIONS_PERCENTAGE = keccak256(
    "RequiredSubmissionsPercentage"
);

/**
        @dev The setting name for the maximum tolerance settings.
        @dev This is the maximum tolerance for the values submitted (by nodes) when they are aggregated (average). It is used in the consensus mechanisms.
        @dev This is a percentage value with 2 decimal places.
            i.e. maximumTolerance of 325 => tolerance of 3.25% => 0.0325 of value
            i.e. maximumTolerance of 0 => It means all the values submitted must be equals.
        @dev The max value is 100% => 10000
     */
bytes32 constant MAXIMUM_TOLERANCE = keccak256("MaximumTolerance");
/**
        @dev The setting name for the response expiry length settings.
        @dev This is the maximum time (in seconds) a node has to submit a response. After that time, the response is considered expired and will not be accepted by the protocol.
     */

bytes32 constant RESPONSE_EXPIRY_LENGTH = keccak256("ResponseExpiryLength");

/**
        @dev The setting name for the safety interval settings.
        @dev This is the minimum time you need to wait (in seconds) between the last time you deposit collateral and you take out the loan.
        @dev It is used to avoid potential attacks using Flash Loans (AAVE) or Flash Swaps (Uniswap V2).
     */
bytes32 constant SAFETY_INTERVAL = keccak256("SafetyInterval");

/**
        @dev The setting name for the term expiry time settings.
        @dev This represents the time (in seconds) that loan terms will be available after requesting them.
        @dev After this time, the loan terms will expire and the borrower will need to request it again.
     */
bytes32 constant TERMS_EXPIRY_TIME = keccak256("TermsExpiryTime");

/**
        @dev The setting name for the liquidation reward percent setting.
        @dev It represents the percentage value (with 2 decimal places) for the MAX liquidation reward.
            i.e. an ETH liquidation price at 5% is stored as 500
     */
bytes32 constant LIQUIDATE_REWARD_PERCENT = keccak256("LiquidateRewardPercent");

/**
        @dev The setting name for the maximum loan duration settings.
        @dev The maximum loan duration setting is defined in seconds. Loans will not be given for timespans larger than the one specified here.
     */
bytes32 constant MAXIMUM_LOAN_DURATION = keccak256("MaximumLoanDuration");

/**
        @dev The setting name for the request loan terms rate limit settings.
        @dev The request loan terms rate limit setting is defined in seconds.
     */
bytes32 constant REQUEST_LOAN_TERMS_RATE_LIMIT = keccak256(
    "RequestLoanTermsRateLimit"
);

/**
        @dev The setting name for the collateral buffer.
        @dev The collateral buffer is a safety buffer above the required collateral amount to liquidate a loan. It is required to ensure the loan does not get liquidated immediately after the loan is taken out if the value of the collateral asset deposited drops drastically.
        @dev It represents the percentage value (with 2 decimal places) of a collateral buffer.
            e.g.: collateral buffer at 100% is stored as 10000.
     */
bytes32 constant COLLATERAL_BUFFER = keccak256("CollateralBuffer");

/**
        @dev The setting name for the over collateralized buffer.
        @dev The over collateralized buffer is the minimum required collateral ratio in order for a loan to be taken out without an Escrow contract and for the funds to go to the borrower's EOA (external overridely owned account).
        @dev It represents the percentage value (with 2 decimal places) of a over collateralized buffer.
            e.g.: over collateralized buffer at 130% is stored as 13000.
     */
bytes32 constant OVER_COLLATERALIZED_BUFFER = keccak256(
    "OverCollateralizedBuffer"
);

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    // refer to the aave whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAToken {
    /**
     * @dev Returns the underlying token address
     * @return address of the underlying token
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount)
        external
        returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IAaveLendingPoolAddressesProvider.sol";
import "./DataTypes.sol";

interface IAaveLendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (IAaveLendingPoolAddressesProvider);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface IAaveLendingPoolAddressesProvider {
    function getMarketId() external view returns (string memory);

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum CacheType {
    Address,
    Uint,
    Int,
    Byte,
    Bool
}

/**
 * @notice This struct manages the cache of the library instance.
 * @param addresses A mapping of address values mapped to cache keys in bytes.
 * @param uints A mapping of uint values mapped to cache keys names in bytes.
 * @param ints A mapping of int values mapped to cache keys names in bytes.
 * @param bites A mapping of bytes values mapped to cache keys names in bytes.
 * @param bools A mapping of bool values mapped to cache keys names in bytes.
 */
struct Cache {
    // Mapping of cache keys names to address values.
    mapping(bytes32 => address) addresses;
    // Mapping of cache keys names to uint256 values.
    mapping(bytes32 => uint256) uints;
    // Mapping of cache keys names to int256 values.
    mapping(bytes32 => int256) ints;
    // Mapping of cache keys names to bytes32 values.
    mapping(bytes32 => bytes32) bites;
    // Mapping of cache keys names to bool values.
    mapping(bytes32 => bool) bools;
}

library CacheLib {
    // The constant for the initialization check
    bytes32 private constant INITIALIZED = keccak256("Initialized");

    /**
     * @notice Initializes the cache instance.
     * @param cache The current cache
     */
    function initialize(Cache storage cache) internal {
        requireNotExists(cache);
        cache.bools[INITIALIZED] = true;
    }

    /**
     * @notice Checks whether the current cache does not, throwing an error if it does.
     * @param cache The current cache
     */
    function requireNotExists(Cache storage cache) internal view {
        require(!exists(cache), "CACHE_ALREADY_EXISTS");
    }

    /**
     * @notice Checks whether the current cache exists, throwing an error if the cache does not.
     * @param cache The current cache
     */
    function requireExists(Cache storage cache) internal view {
        require(exists(cache), "CACHE_DOES_NOT_EXIST");
    }

    /**
     * @notice Tests whether the current cache exists or not.
     * @param cache The current cache.
     * @return bool True if the cache exists.
     */
    function exists(Cache storage cache) internal view returns (bool) {
        return cache.bools[INITIALIZED];
    }

    /**
     * @notice it updates the cache with a key, value and cache type
     * @param cache cache to update
     * @param key the memory reference to the value in bytes32
     * @param value the value to update at the key
     * @param cacheType the enum type of cache to update
     */
    function update(
        Cache storage cache,
        bytes32 key,
        bytes32 value,
        CacheType cacheType
    ) internal {
        requireExists(cache);

        assembly {
            mstore(0, value)
        }
        if (cacheType == CacheType.Address) {
            address addr;
            assembly {
                addr := mload(0)
            }
            cache.addresses[key] = addr;
        } else if (cacheType == CacheType.Uint) {
            uint256 ui;
            assembly {
                ui := mload(0)
            }
            cache.uints[key] = ui;
        } else if (cacheType == CacheType.Int) {
            int256 i;
            assembly {
                i := mload(0)
            }
            cache.ints[key] = i;
        } else if (cacheType == CacheType.Byte) {
            cache.bites[key] = value;
        } else if (cacheType == CacheType.Bool) {
            bool b;
            assembly {
                b := mload(0)
            }
            cache.bools[key] = b;
        }
    }

    /**
     * @notice it deletes the cache values at the specified key
     * @param cache the cache to delete keys from
     * @param keysToClear the keys to delete
     * @param keyTypes the types of keys to target different parts of the cache
     */
    function clearCache(
        Cache storage cache,
        bytes32[5] memory keysToClear,
        CacheType[5] memory keyTypes
    ) internal {
        requireExists(cache);
        require(
            keysToClear.length == keyTypes.length,
            "ARRAY_LENGTHS_MISMATCH"
        );
        for (uint256 i; i <= keysToClear.length; i++) {
            if (keyTypes[i] == CacheType.Address) {
                delete cache.addresses[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Uint) {
                delete cache.uints[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Int) {
                delete cache.ints[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Byte) {
                delete cache.bites[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Bool) {
                delete cache.bools[keysToClear[i]];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    ENSRegistry
} from "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import {
    PublicResolver
} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";

library ENS {
    bytes32 public constant ETH_NAMEHASH =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    function registryResolve(address registry, bytes32 node)
        internal
        view
        returns (address)
    {
        return resolve(resolver(registry, node), node);
    }

    function resolve(address resolver, bytes32 node)
        internal
        view
        returns (address)
    {
        return PublicResolver(resolver).addr(node);
    }

    function resolver(address registry, bytes32 node)
        internal
        view
        returns (address)
    {
        return ENSRegistry(registry).resolver(node);
    }

    function subnode(string memory name, bytes32 node)
        internal
        pure
        returns (bytes32 namehash_)
    {
        namehash_ = subnode(keccak256(abi.encodePacked(name)), node);
    }

    function subnode(bytes32 label, bytes32 node)
        internal
        pure
        returns (bytes32 namehash_)
    {
        namehash_ = keccak256(abi.encodePacked(node, label));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Utility library for uint256 numbers
 *
 * @author [email protected]
 */
library NumbersLib {
    /**
     * @dev It represents 100% with 2 decimal places.
     */
    uint256 internal constant ONE_HUNDRED_PERCENT = 10000;

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint16 percentage)
        internal
        pure
        returns (uint256)
    {
        return (self * uint256(percentage)) / ONE_HUNDRED_PERCENT;
    }

    function percent(int256 self, uint256 percentage)
        internal
        pure
        returns (int256)
    {
        return (self * int256(percentage)) / int256(ONE_HUNDRED_PERCENT);
    }

    /**
     * @notice it returns the absolute number of a specified parameter
     * @param self the number to be returned in it's absolute
     * @return the absolute number
     */
    function abs(int256 self) internal pure returns (uint256) {
        return self >= 0 ? uint256(self) : uint256(-1 * self);
    }

    /**
     * @notice Returns a ratio percentage of {num1} to {num2}.
     * @param num1 The number used to get the ratio for.
     * @param num2 The number used to get the ratio from.
     * @return Ratio percentage with 2 decimal places (10000 = 100%).
     */
    function ratioOf(uint256 num1, uint256 num2)
        internal
        pure
        returns (uint16)
    {
        return
            num2 == 0
                ? 0
                : SafeCast.toUint16((num1 * ONE_HUNDRED_PERCENT) / num2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./NumbersLib.sol";

/**
 * @dev Utility library of inline functions on NumbersList.Values
 *
 * @author [email protected]
 */
library NumbersList {
    using NumbersLib for uint256;

    // Holds values to calculate the threshold of a list of numbers
    struct Values {
        uint256 count; // The total number of numbers added
        uint256 max; // The maximum number that was added
        uint256 min; // The minimum number that was added
        uint256 sum; // The total sum of the numbers that were added
    }

    /**
     * @dev Add to the sum while keeping track of min and max values
     * @param self The Value this function was called on
     * @param newValue Number to increment sum by
     */
    function addValue(Values memory self, uint256 newValue) internal pure {
        if (self.max < newValue) {
            self.max = newValue;
        }
        if (self.min > newValue || self.count == 0) {
            self.min = newValue;
        }
        self.sum = self.sum + (newValue);
        self.count = self.count + 1;
    }

    /**
     * @param self The Value this function was called on
     * @return the number of times the sum has updated
     */
    function valuesCount(Values memory self) internal pure returns (uint256) {
        return self.count;
    }

    /**
     * @dev Checks if the sum has been changed
     * @param self The Value this function was called on
     * @return boolean
     */
    function isEmpty(Values memory self) internal pure returns (bool) {
        return valuesCount(self) == 0;
    }

    /**
     * @param self The Value this function was called on
     * @return the average number that was used to calculate the sum
     */
    function getAverage(Values memory self) internal pure returns (uint256) {
        return isEmpty(self) ? 0 : self.sum / (valuesCount(self));
    }

    /**
     * @dev Checks if the min and max numbers are within the acceptable tolerance
     * @param self The Value this function was called on
     * @param tolerancePercentage Acceptable tolerance percentage as a whole number
     * The percentage should be entered with 2 decimal places. e.g. 2.5% should be entered as 250.
     * @return boolean
     */
    function isWithinTolerance(Values memory self, uint16 tolerancePercentage)
        internal
        pure
        returns (bool)
    {
        if (isEmpty(self)) {
            return false;
        }
        uint256 average = getAverage(self);
        uint256 toleranceAmount = average.percent(tolerancePercentage);

        uint256 minTolerance = average - toleranceAmount;
        if (self.min < minTolerance) {
            return false;
        }

        uint256 maxTolerance = average + toleranceAmount;
        if (self.max > maxTolerance) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library StringsLib {
    /**
     * Concat
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combining the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_base, _value));
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int256 _length)
        internal
        pure
        returns (string memory)
    {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(
        string memory _base,
        int256 _length,
        int256 _offset
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return splitArr An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (
                _baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract InitializeableBeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @notice This proxy is an implementation of a BeaconProxy and is meant to be cloned using EIP 1167. Therefore,
     *  once this proxy is deployed, we immediately initialize it so that it cannot be initialized by an external party.
     *  The UpgradeableBeaconFactory should clone this proxy and then initialize the clone in the same call.
     */
    constructor() {
        _setBeacon(address(1), "");
    }

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    function initialize(address beacon, bytes memory data) external payable {
        assert(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
        );
        require(_beacon() == address(0), "Beacon: already initialized");

        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(
                _implementation(),
                data,
                "BeaconProxy: function call failed"
            );
        }
    }

    receive() external payable override {
        // Needed to receive ETH without data
        // OZ Proxy contract calls the _fallback() on receive and tries to delegatecall which fails
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./InitializeableBeaconProxy.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeaconFactory is IBeacon, Ownable {
    address private _implementation;
    InitializeableBeaconProxy public proxyAddress;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address payable proxyAddress_, address implementation_) {
        require(proxyAddress_ != address(0) && implementation_ != address(0));
        proxyAddress = InitializeableBeaconProxy(proxyAddress_);
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @notice it clones the proxy contract at an address
     * @param initData the data to initialize after the proxy is cloned
     * @return proxy_ the cloned proxy
     */
    function cloneProxy(bytes memory initData)
        external
        returns (address payable proxy_)
    {
        proxy_ = payable(Clones.clone(address(proxyAddress)));
        InitializeableBeaconProxy(proxy_).initialize(address(this), initData);
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev the roles for the user to assign, revoke and check in functions
 */
bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant PAUSER = keccak256("PAUSER");

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../nft/TellerNFT.sol";
import { PriceAggregator } from "../price-aggregator/PriceAggregator.sol";

// Libraries
import {
    PlatformSetting
} from "../settings/platform/libraries/PlatformSettingsLib.sol";
import { Cache } from "../shared/libraries/CacheLib.sol";
import {
    UpgradeableBeaconFactory
} from "../shared/proxy/beacon/UpgradeableBeaconFactory.sol";

struct AppStorage {
    // is it initialized
    bool initialized;
    // is it platform restricted
    bool platformRestricted; // DEPRECATED
    // mapping between contract IDs and if they're paused
    mapping(bytes32 => bool) paused;
    //p
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) _assetAddresses; // DEPRECATED
    mapping(address => bool) _cTokenRegistry; // DEPRECATED
    TellerNFT nft;
    UpgradeableBeaconFactory loansEscrowBeacon;
    UpgradeableBeaconFactory collateralEscrowBeacon;
    address nftLiquidationController;
    UpgradeableBeaconFactory tTokenBeacon;
    address wrappedNativeToken;
    PriceAggregator priceAggregator;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../shared/libraries/NumbersList.sol";

// Interfaces
import { ILoansEscrow } from "../escrow/escrow/ILoansEscrow.sol";
import { ICollateralEscrow } from "../market/collateral/ICollateralEscrow.sol";
import { ITToken_V3 } from "../lending/ttoken/ITToken_V3.sol";

// DEPRECATED
struct LoanTerms {
    // Max size the loan max be taken out with
    uint256 maxLoanAmount;
    // The timestamp at which the loan terms expire, after which if the loan is not yet active, cannot be taken out
    uint32 termsExpiry;
}

enum LoanStatus {
    NonExistent,
    TermsSet,
    Active,
    Closed,
    Liquidated
}

struct Loan {
    // Account that owns the loan
    address payable borrower;
    // The asset lent out for the loan
    address lendingToken;
    // The token used as collateral for the loan
    address collateralToken;
    // The total amount of the loan size taken out
    uint256 borrowedAmount;
    // The id of the loan for internal tracking
    uint128 id;
    // How long in seconds until the loan must be repaid
    uint32 duration;
    // The timestamp at which the loan became active
    uint32 loanStartTime;
    // The interest rate given for repaying the loan
    uint16 interestRate;
    // Ratio used to determine amount of collateral required based on the collateral asset price
    uint16 collateralRatio;
    // The status of the loan
    LoanStatus status;
}

struct LoanDebt {
    // The total amount of the loan taken out by the borrower, reduces on loan repayments
    uint256 principalOwed;
    // The total interest owed by the borrower for the loan, reduces on loan repayments
    uint256 interestOwed;
}

struct LoanRequest {
    LoanUserRequest request;
    LoanConsensusResponse[] responses;
}

/**
 * @notice Borrower request object to take out a loan
 * @param borrower The wallet address of the borrower
 * @param assetAddress The address of the asset for the requested loan
 * @param amount The amount of tokens requested by the borrower for the loan
 * @param requestNonce The nonce of the borrower wallet address required for authentication
 * @param duration The length of time in seconds that the loan has been requested for
 * @param requestTime The timestamp at which the loan was requested
 */
struct LoanUserRequest {
    address payable borrower;
    address assetAddress;
    uint256 amount;
    uint32 requestNonce;
    uint32 duration;
    uint32 requestTime;
}

/**
 * @notice Borrower response object to take out a loan
 * @param signer The wallet address of the signer validating the interest request of the lender
 * @param assetAddress The address of the asset for the requested loan
 * @param maxLoanAmount The largest amount of tokens that can be taken out in the loan by the borrower
 * @param responseTime The timestamp at which the response was sent
 * @param interestRate The signed interest rate generated by the signer's Credit Risk Algorithm (CRA)
 * @param collateralRatio The ratio of collateral to loan amount that is generated by the signer's Credit Risk Algorithm (CRA)
 * @param signature The signature generated by the signer in the format of the above Signature struct
 */
struct LoanConsensusResponse {
    address signer;
    address assetAddress;
    uint256 maxLoanAmount;
    uint32 responseTime;
    uint16 interestRate;
    uint16 collateralRatio;
    Signature signature;
}

/**
 * @notice Represents a user signature
 * @param v The recovery identifier represented by the last byte of a ECDSA signature as an int
 * @param r The random point x-coordinate of the signature respresented by the first 32 bytes of the generated ECDSA signature
 * @param s The signature proof represented by the second 32 bytes of the generated ECDSA signature
 */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct MarketStorage {
    // Holds the index for the next loan ID
    Counters.Counter loanIDCounter;
    // Maps loanIDs to loan data
    mapping(uint256 => Loan) loans;
    // Maps loanID to loan debt (total owed left)
    mapping(uint256 => LoanDebt) loanDebt;
    // Maps loanID to loan terms
    mapping(uint256 => LoanTerms) _loanTerms; // DEPRECATED: DO NOT REMOVE
    // Maps loanIDs to escrow address to list of held tokens
    mapping(uint256 => ILoansEscrow) loanEscrows;
    // Maps loanIDs to list of tokens owned by a loan escrow
    mapping(uint256 => EnumerableSet.AddressSet) escrowTokens;
    // Maps collateral token address to a LoanCollateralEscrow that hold collateral funds
    mapping(address => ICollateralEscrow) collateralEscrows;
    // Maps accounts to owned loan IDs
    mapping(address => uint128[]) borrowerLoans;
    // Maps lending token to overall amount of interest collected from loans
    mapping(address => ITToken_V3) tTokens;
    // Maps lending token to list of signer addresses who are only ones allowed to verify loan requests
    mapping(address => EnumerableSet.AddressSet) signers;
    // Maps lending token to list of allowed collateral tokens
    mapping(address => EnumerableSet.AddressSet) collateralTokens;
}

bytes32 constant MARKET_STORAGE_POS = keccak256("teller.market.storage");

library MarketStorageLib {
    function store() internal pure returns (MarketStorage storage s) {
        bytes32 pos = MARKET_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../nft/TellerNFTDictionary.sol";

// Utils
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct NFTStorage {
    // Maps NFT owner to set of token IDs owned
    mapping(address => EnumerableSet.UintSet) stakedNFTs;
    // Maps loanID to NFT IDs indicating NFT being used for the loan
    mapping(uint256 => EnumerableSet.UintSet) loanNFTs;
    // Merkle root used for verifying nft IDs to base loan size
    TellerNFTDictionary nftDictionary;
    // Maps NFT owner to set of token IDs owned (V2)
    mapping(address => EnumerableSet.UintSet) stakedNFTsV2;
    // Map NFT ids to amounts
    mapping(address => mapping(uint256 => uint256)) stakedNFTsV2Amounts;
    // Maps loanID to NFT IDs indicating NFT being used for the loan (V2)
    mapping(uint256 => EnumerableSet.UintSet) loanNFTsV2;
    // Map NFT ids to amounts, linked to loans
    mapping(uint256 => mapping(uint256 => uint256)) loanNFTsV2Amounts;
}

bytes32 constant NFT_STORAGE_POS = keccak256("teller.staking.storage");

library NFTStorageLib {
    function store() internal pure returns (NFTStorage storage s) {
        bytes32 pos = NFT_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}