/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;


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

/**
* @dev Contract mixin for 'owned' contracts.
*/
contract Owned {
    address public owner;
    
    modifier owner_only() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public owner_only {
        owner = newOwner;
    }
}


pragma solidity 0.8.4;

//import "../utils/BytesUtils.sol";
//import "../utils/Buffer.sol";

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

    /**
     * @dev Computes the keytag for a chunk of data.
     * @param data The data to compute a keytag for.
     * @return The computed key tag.
     */
    function computeKeytag(bytes memory data) internal pure returns (uint16) {
        /* This function probably deserves some explanation.
         * The DNSSEC keytag function is a checksum that relies on summing up individual bytes
         * from the input string, with some mild bitshifting. Here's a Naive solidity implementation:
         *
         *     function computeKeytag(bytes memory data) internal pure returns (uint16) {
         *         uint ac;
         *         for (uint i = 0; i < data.length; i++) {
         *             ac += i & 1 == 0 ? uint16(data.readUint8(i)) << 8 : data.readUint8(i);
         *         }
         *         return uint16(ac + (ac >> 16));
         *     }
         *
         * The EVM, with its 256 bit words, is exceedingly inefficient at doing byte-by-byte operations;
         * the code above, on reasonable length inputs, consumes over 100k gas. But we can make the EVM's
         * large words work in our favour.
         *
         * The code below works by treating the input as a series of 256 bit words. It first masks out
         * even and odd bytes from each input word, adding them to two separate accumulators `ac1` and `ac2`.
         * The bytes are separated by empty bytes, so as long as no individual sum exceeds 2^16-1, we're
         * effectively summing 16 different numbers with each EVM ADD opcode.
         *
         * Once it's added up all the inputs, it has to add all the 16 bit values in `ac1` and `ac2` together.
         * It does this using the same trick - mask out every other value, shift to align them, add them together.
         * After the first addition on both accumulators, there's enough room to add the two accumulators together,
         * and the remaining sums can be done just on ac1.
         */
        unchecked {
            require(data.length <= 8192, "Long keys not permitted");
            uint ac1;
            uint ac2;
            for(uint i = 0; i < data.length + 31; i += 32) {
                uint word;
                assembly {
                    word := mload(add(add(data, 32), i))
                }
                if(i + 32 > data.length) {
                    uint unused = 256 - (data.length - i) * 8;
                    word = (word >> unused) << unused;
                }
                ac1 += (word & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8;
                ac2 += (word & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF);
            }
            ac1 = (ac1 & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF)
                + ((ac1 & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16);
            ac2 = (ac2 & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF)
                + ((ac2 & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16);
            ac1 = (ac1 << 8) + ac2;
            ac1 = (ac1 & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF)
                + ((ac1 & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32);
            ac1 = (ac1 & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF)
                + ((ac1 & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64);
            ac1 = (ac1 & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                + (ac1 >> 128);
            ac1 += (ac1 >> 16) & 0xFFFF;
            return uint16(ac1);
        }
    }
}

pragma solidity ^0.8.4;

abstract contract DNSSEC {

    bytes public anchors;

    struct RRSetWithSignature {
        bytes rrset;
        bytes sig;
    }

    event AlgorithmUpdated(uint8 id, address addr);
    event DigestUpdated(uint8 id, address addr);
    event NSEC3DigestUpdated(uint8 id, address addr);
    event RRSetUpdated(bytes name, bytes rrset);

    function submitRRSets(RRSetWithSignature[] memory input, bytes calldata proof) public virtual returns (bytes memory);
    function submitRRSet(RRSetWithSignature calldata input, bytes calldata proof) public virtual returns (bytes memory);
    function deleteRRSet(uint16 deleteType, bytes calldata deleteName, RRSetWithSignature calldata nsec, bytes calldata proof) public virtual;
    function deleteRRSetNSEC3(uint16 deleteType, bytes memory deleteName, RRSetWithSignature memory closestEncloser, RRSetWithSignature memory nextClosest, bytes memory dnskey) public virtual;
    function rrdata(uint16 dnstype, bytes calldata name) external virtual view returns (uint32, uint32, bytes20);
}

pragma solidity ^0.8.4;

/**
* @dev An interface for contracts implementing a DNSSEC (signing) algorithm.
*/
interface Algorithm {
    /**
    * @dev Verifies a signature.
    * @param key The public key to verify with.
    * @param data The signed data to verify.
    * @param signature The signature to verify.
    * @return True iff the signature is valid.
    */
    function verify(bytes calldata key, bytes calldata data, bytes calldata signature) external virtual view returns (bool);
}

pragma solidity ^0.8.4;

/**
* @dev An interface for contracts implementing a DNSSEC digest.
*/
interface Digest {
    /**
    * @dev Verifies a cryptographic hash.
    * @param data The data to hash.
    * @param hash The hash to compare to.
    * @return True iff the hashed data matches the provided hash value.
    */
    function verify(bytes calldata data, bytes calldata hash) external virtual pure returns (bool);
}

pragma solidity ^0.8.4;

/**
 * @dev Interface for contracts that implement NSEC3 digest algorithms.
 */
interface NSEC3Digest {
    /**
     * @dev Performs an NSEC3 iterated hash.
     * @param salt The salt value to use on each iteration.
     * @param data The data to hash.
     * @param iterations The number of iterations to perform.
     * @return The result of the iterated hash operation.
     */
     function hash(bytes calldata salt, bytes calldata data, uint iterations) external virtual pure returns (bytes32);
}

/*
 * @dev An oracle contract that verifies and stores DNSSEC-validated DNS records.
 *
 * TODO: Support for NSEC3 records
 */
contract DNSSECImpl is DNSSEC, Owned {
    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using RRUtils for *;

    uint16 constant DNSCLASS_IN = 1;

    uint16 constant DNSTYPE_NS = 2;
    uint16 constant DNSTYPE_SOA = 6;
    uint16 constant DNSTYPE_DNAME = 39;
    uint16 constant DNSTYPE_DS = 43;
    uint16 constant DNSTYPE_RRSIG = 46;
    uint16 constant DNSTYPE_NSEC = 47;
    uint16 constant DNSTYPE_DNSKEY = 48;
    uint16 constant DNSTYPE_NSEC3 = 50;

    uint constant DNSKEY_FLAG_ZONEKEY = 0x100;

    uint8 constant ALGORITHM_RSASHA256 = 8;

    uint8 constant DIGEST_ALGORITHM_SHA256 = 2;

    struct RRSet {
        uint32 inception;
        uint32 expiration;
        bytes20 hash;
    }

    // (name, type) => RRSet
    mapping (bytes32 => mapping(uint16 => RRSet)) rrsets;

    mapping (uint8 => Algorithm) public algorithms;
    mapping (uint8 => Digest) public digests;
    mapping (uint8 => NSEC3Digest) public nsec3Digests;

    event Test(uint t);
    event Marker();

    /**
     * @dev Constructor.
     * @param _anchors The binary format RR entries for the root DS records.
     */
    constructor(bytes memory _anchors) {
        // Insert the 'trust anchors' - the key hashes that start the chain
        // of trust for all other records.
        anchors = _anchors;
        rrsets[keccak256(hex"00")][DNSTYPE_DS] = RRSet({
            inception: uint32(0),
            expiration: uint32(3767581600), // May 22 2089 - the latest date we can encode as of writing this
            hash: bytes20(keccak256(anchors))
        });
        emit RRSetUpdated(hex"00", anchors);
    }

    /**
     * @dev Sets the contract address for a signature verification algorithm.
     *      Callable only by the owner.
     * @param id The algorithm ID
     * @param algo The address of the algorithm contract.
     */
    function setAlgorithm(uint8 id, Algorithm algo) public owner_only {
        algorithms[id] = algo;
        emit AlgorithmUpdated(id, address(algo));
    }

    /**
     * @dev Sets the contract address for a digest verification algorithm.
     *      Callable only by the owner.
     * @param id The digest ID
     * @param digest The address of the digest contract.
     */
    function setDigest(uint8 id, Digest digest) public owner_only {
        digests[id] = digest;
        emit DigestUpdated(id, address(digest));
    }

    /**
     * @dev Sets the contract address for an NSEC3 digest algorithm.
     *      Callable only by the owner.
     * @param id The digest ID
     * @param digest The address of the digest contract.
     */
    function setNSEC3Digest(uint8 id, NSEC3Digest digest) public owner_only {
        nsec3Digests[id] = digest;
        emit NSEC3DigestUpdated(id, address(digest));
    }

    /**
     * @dev Submits multiple RRSets
     * @param input A list of RRSets and signatures forming a chain of trust from an existing known-good record.
     * @param _proof The DNSKEY or DS to validate the first signature against.
     * @return The last RRSET submitted.
     */
    function submitRRSets(RRSetWithSignature[] memory input, bytes calldata _proof) public override returns (bytes memory) {
        bytes memory proof = _proof;
        for(uint i = 0; i < input.length; i++) {
            proof = _submitRRSet(input[i], proof);
        }
        return proof;
    }

    /**
     * @dev Submits a signed set of RRs to the oracle.
     *
     * RRSETs are only accepted if they are signed with a key that is already
     * trusted, or if they are self-signed, and the signing key is identified by
     * a DS record that is already trusted.
     *
     * @param input The signed RR set. This is in the format described in section
     *        5.3.2 of RFC4035: The RRDATA section from the RRSIG without the signature
     *        data, followed by a series of canonicalised RR records that the signature
     *        applies to.
     * @param proof The DNSKEY or DS to validate the signature against. Must Already
     *        have been submitted and proved previously.
     */
    function submitRRSet(RRSetWithSignature memory input, bytes memory proof)
        public override
        returns (bytes memory)
    {
        return _submitRRSet(input, proof);
    }

    /**
     * @dev Deletes an RR from the oracle.
     *
     * @param deleteType The DNS record type to delete.
     * @param deleteName which you want to delete
     * @param nsec The signed NSEC RRset. This is in the format described in section
     *        5.3.2 of RFC4035: The RRDATA section from the RRSIG without the signature
     *        data, followed by a series of canonicalised RR records that the signature
     *        applies to.
     */
    function deleteRRSet(uint16 deleteType, bytes memory deleteName, RRSetWithSignature memory nsec, bytes memory proof)
        public override
    {
        RRUtils.SignedSet memory rrset;
        rrset = validateSignedSet(nsec, proof);
        require(rrset.typeCovered == DNSTYPE_NSEC);

        // Don't let someone use an old proof to delete a new name
        require(RRUtils.serialNumberGte(rrset.inception, rrsets[keccak256(deleteName)][deleteType].inception));

        for (RRUtils.RRIterator memory iter = rrset.rrs(); !iter.done(); iter.next()) {
            // We're dealing with three names here:
            //   - deleteName is the name the user wants us to delete
            //   - nsecName is the owner name of the NSEC record
            //   - nextName is the next name specified in the NSEC record
            //
            // And three cases:
            //   - deleteName equals nsecName, in which case we can delete the
            //     record if it's not in the type bitmap.
            //   - nextName comes after nsecName, in which case we can delete
            //     the record if deleteName comes between nextName and nsecName.
            //   - nextName comes before nsecName, in which case nextName is the
            //     zone apex, and deleteName must come after nsecName.
            checkNsecName(iter, rrset.name, deleteName, deleteType);
            delete rrsets[keccak256(deleteName)][deleteType];
            return;
        }
        // We should never reach this point
        revert();
    }

    function checkNsecName(RRUtils.RRIterator memory iter, bytes memory nsecName, bytes memory deleteName, uint16 deleteType) private pure {
        uint rdataOffset = iter.rdataOffset;
        uint nextNameLength = iter.data.nameLength(rdataOffset);
        uint rDataLength = iter.nextOffset - iter.rdataOffset;

        // We assume that there is always typed bitmap after the next domain name
        require(rDataLength > nextNameLength);

        int compareResult = deleteName.compareNames(nsecName);
        if(compareResult == 0) {
            // Name to delete is on the same label as the NSEC record
            require(!iter.data.checkTypeBitmap(rdataOffset + nextNameLength, deleteType));
        } else {
            // First check if the NSEC next name comes after the NSEC name.
            bytes memory nextName = iter.data.substring(rdataOffset,nextNameLength);
            // deleteName must come after nsecName
            require(compareResult > 0);
            if(nsecName.compareNames(nextName) < 0) {
                // deleteName must also come before nextName
                require(deleteName.compareNames(nextName) < 0);
            }
        }
    }

    /**
     * @dev Deletes an RR from the oracle using an NSEC3 proof.
     *      Deleting a record using NSEC3 requires using up to two NSEC3 records. There are two cases:
     *       1. The name exists, but the record type doesn't. Eg, example.com has A records but no TXT records.
     *       2. The name does not exist, but a parent name does.
     *      In the first case, we submit one NSEC3 proof in `closestEncloser` that matches the target name
     *      but does not have the bit for `deleteType` set in its type bitmap. In the second case, we submit
     *      two proofs: closestEncloser and nextClosest, that together prove that the name does not exist.
     *      NSEC3 records are in the format described in section 5.3.2 of RFC4035: The RRDATA section
     *      from the RRSIG without the signature data, followed by a series of canonicalised RR records
     *      that the signature applies to.
     *
     * @param deleteType The DNS record type to delete.
     * @param deleteName The name to delete.
     * @param closestEncloser An NSEC3 proof matching the closest enclosing name - that is,
     *        the nearest ancestor of the target name that *does* exist.
     * @param nextClosest An NSEC3 proof covering the next closest name. This proves that the immediate
     *        subdomain of the closestEncloser does not exist.
     * @param dnskey An encoded DNSKEY record that has already been submitted to the oracle and can be used
     *        to verify the signatures closestEncloserSig and nextClosestSig
     */
    function deleteRRSetNSEC3(uint16 deleteType, bytes memory deleteName, RRSetWithSignature memory closestEncloser, RRSetWithSignature memory nextClosest, bytes memory dnskey)
        public override
    {
        uint32 originalInception = rrsets[keccak256(deleteName)][deleteType].inception;

        RRUtils.SignedSet memory ce = validateSignedSet(closestEncloser, dnskey);
        checkNSEC3Validity(ce, deleteName, originalInception);

        RRUtils.SignedSet memory nc;
        if(nextClosest.rrset.length > 0) {
            nc = validateSignedSet(nextClosest, dnskey);
            checkNSEC3Validity(nc, deleteName, originalInception);
        }

        RRUtils.NSEC3 memory ceNSEC3 = readNSEC3(ce);
        // The flags field must be 0 or 1 (RFC5155 section 8.2).
        require(ceNSEC3.flags & 0xfe == 0);
        // Check that the closest encloser is from the correct zone (RFC5155 section 8.3)
        // "The DNAME type bit must not be set and the NS type bit may only be set if the SOA type bit is set."
        require(!ceNSEC3.checkTypeBitmap(DNSTYPE_DNAME) && (!ceNSEC3.checkTypeBitmap(DNSTYPE_NS) || ceNSEC3.checkTypeBitmap(DNSTYPE_SOA)));

        // Case 1: deleteName does exist, but no records of RRTYPE deleteType do.
        if(isMatchingNSEC3Record(deleteType, deleteName, ce.name, ceNSEC3)) {
            delete rrsets[keccak256(deleteName)][deleteType];
        // Case 2: deleteName does not exist.
        } else if(isCoveringNSEC3Record(deleteName, ce.name, ceNSEC3, nc.name, readNSEC3(nc))) {
            delete rrsets[keccak256(deleteName)][deleteType];
        } else {
            revert();
        }
    }

    function checkNSEC3Validity(RRUtils.SignedSet memory nsec, bytes memory deleteName, uint32 originalInception) private pure {
        // The records must have been signed after the record we're trying to delete
        require(RRUtils.serialNumberGte(nsec.inception, originalInception));

        // The record must be an NSEC3
        require(nsec.typeCovered == DNSTYPE_NSEC3);

        // nsecName is of the form <hash>.zone.xyz. <hash> is the NSEC3 hash of the entire name the NSEC3 record matches, while
        // zone.xyz can be any ancestor of that name. We'll check that, so someone can't use a record on foo.com
        // as proof of the nonexistence of bar.org.
        require(checkNSEC3OwnerName(nsec.name, deleteName));
    }

    function isMatchingNSEC3Record(uint16 deleteType, bytes memory deleteName, bytes memory closestEncloserName, RRUtils.NSEC3 memory closestEncloser) private view returns(bool) {
        // Check the record matches the hashed name, but the type bitmap does not include the type
        if(checkNSEC3Name(closestEncloser, closestEncloserName, deleteName)) {
            return !closestEncloser.checkTypeBitmap(deleteType);
        }

        return false;
    }

    function isCoveringNSEC3Record(bytes memory deleteName, bytes memory ceName, RRUtils.NSEC3 memory ce, bytes memory ncName, RRUtils.NSEC3 memory nc) private view returns(bool) {
        // The flags field must be 0 or 1 (RFC5155 section 8.2).
        require(nc.flags & 0xfe == 0);

        bytes32 ceNameHash = decodeOwnerNameHash(ceName);
        bytes32 ncNameHash = decodeOwnerNameHash(ncName);

        uint lastOffset = 0;
        // Iterate over suffixes of the name to delete until one matches the closest encloser
        for(uint offset = deleteName.readUint8(0) + 1; offset < deleteName.length; offset += deleteName.readUint8(offset) + 1) {
            if(hashName(ce, deleteName.substring(offset, deleteName.length - offset)) == ceNameHash) {
                // Check that the next closest record encloses the name one label longer
                bytes32 checkHash = hashName(nc, deleteName.substring(lastOffset, deleteName.length - lastOffset));
                if(ncNameHash < nc.nextHashedOwnerName) {
                    return checkHash > ncNameHash && checkHash < nc.nextHashedOwnerName;
                } else {
                    return checkHash > ncNameHash || checkHash < nc.nextHashedOwnerName;
                }
            }
            lastOffset = offset;
        }
        // If we reached the root without finding a match, return false.
        return false;
    }

    function readNSEC3(RRUtils.SignedSet memory ss) private pure returns(RRUtils.NSEC3 memory) {
        RRUtils.RRIterator memory iter = ss.rrs();
        return iter.data.readNSEC3(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

    function checkNSEC3Name(RRUtils.NSEC3 memory nsec, bytes memory ownerName, bytes memory deleteName) private view returns(bool) {
        // Compute the NSEC3 name hash of the name to delete.
        bytes32 deleteNameHash = hashName(nsec, deleteName);

        // Decode the NSEC3 name hash from the first label of the NSEC3 owner name.
        bytes32 nsecNameHash = decodeOwnerNameHash(ownerName);

        return deleteNameHash == nsecNameHash;
    }

    function hashName(RRUtils.NSEC3 memory nsec, bytes memory name) private view returns(bytes32) {
        return nsec3Digests[nsec.hashAlgorithm].hash(nsec.salt, name, nsec.iterations);
    }

    function decodeOwnerNameHash(bytes memory name) private pure returns(bytes32) {
        return name.base32HexDecodeWord(1, uint(name.readUint8(0)));
    }

    function checkNSEC3OwnerName(bytes memory nsecName, bytes memory deleteName) private pure returns(bool) {
        uint nsecNameOffset = nsecName.readUint8(0) + 1;
        uint deleteNameOffset = 0;
        while(deleteNameOffset < deleteName.length) {
            if(deleteName.equals(deleteNameOffset, nsecName, nsecNameOffset)) {
                return true;
            }
            deleteNameOffset += deleteName.readUint8(deleteNameOffset) + 1;
        }
        return false;
    }

    /**
     * @dev Returns data about the RRs (if any) known to this oracle with the provided type and name.
     * @param dnstype The DNS record type to query.
     * @param name The name to query, in DNS label-sequence format.
     * @return inception The unix timestamp (wrapped) at which the signature for this RRSET was created.
     * @return expiration The unix timestamp (wrapped) at which the signature for this RRSET expires.
     * @return hash The hash of the RRset.
     */
    function rrdata(uint16 dnstype, bytes calldata name) external override view returns (uint32, uint32, bytes20) {
        RRSet storage result = rrsets[keccak256(name)][dnstype];
        return (result.inception, result.expiration, result.hash);
    }

    function _submitRRSet(RRSetWithSignature memory input, bytes memory proof) internal returns (bytes memory) {
        RRUtils.SignedSet memory rrset;
        rrset = validateSignedSet(input, proof);

        RRSet storage storedSet = rrsets[keccak256(rrset.name)][rrset.typeCovered];
        if (storedSet.hash != bytes20(0)) {
            // To replace an existing rrset, the signature must be at least as new
            require(RRUtils.serialNumberGte(rrset.inception, storedSet.inception));
        }
        rrsets[keccak256(rrset.name)][rrset.typeCovered] = RRSet({
            inception: rrset.inception,
            expiration: rrset.expiration,
            hash: bytes20(keccak256(rrset.data))
        });

        emit RRSetUpdated(rrset.name, rrset.data);

        return rrset.data;
    }

    /**
     * @dev Submits a signed set of RRs to the oracle.
     *
     * RRSETs are only accepted if they are signed with a key that is already
     * trusted, or if they are self-signed, and the signing key is identified by
     * a DS record that is already trusted.
     *
     * @param input The signed RR set. This is in the format described in section
     *        5.3.2 of RFC4035: The RRDATA section from the RRSIG without the signature
     *        data, followed by a series of canonicalised RR records that the signature
     *        applies to.
     * @param proof The DNSKEY or DS to validate the signature against. Must Already
     *        have been submitted and proved previously.
     */
    function validateSignedSet(RRSetWithSignature memory input, bytes memory proof) internal view returns(RRUtils.SignedSet memory rrset) {
        rrset = input.rrset.readSignedSet();
        require(validProof(rrset.signerName, proof));

        // Do some basic checks on the RRs and extract the name
        bytes memory name = validateRRs(rrset, rrset.typeCovered);
        require(name.labelCount(0) == rrset.labels);
        rrset.name = name;

        // All comparisons involving the Signature Expiration and
        // Inception fields MUST use "serial number arithmetic", as
        // defined in RFC 1982

        // o  The validator's notion of the current time MUST be less than or
        //    equal to the time listed in the RRSIG RR's Expiration field.
        require(RRUtils.serialNumberGte(rrset.expiration, uint32(block.timestamp)));

        // o  The validator's notion of the current time MUST be greater than or
        //    equal to the time listed in the RRSIG RR's Inception field.
        require(RRUtils.serialNumberGte(uint32(block.timestamp), rrset.inception));

        // Validate the signature
        verifySignature(name, rrset, input, proof);

        return rrset;
    }

    function validProof(bytes memory name, bytes memory proof) internal view returns(bool) {
        uint16 dnstype = proof.readUint16(proof.nameLength(0));
        return rrsets[keccak256(name)][dnstype].hash == bytes20(keccak256(proof));
    }

    /**
     * @dev Validates a set of RRs.
     * @param rrset The RR set.
     * @param typecovered The type covered by the RRSIG record.
     */
    function validateRRs(RRUtils.SignedSet memory rrset, uint16 typecovered) internal pure returns (bytes memory name) {
        // Iterate over all the RRs
        for (RRUtils.RRIterator memory iter = rrset.rrs(); !iter.done(); iter.next()) {
            // We only support class IN (Internet)
            require(iter.class == DNSCLASS_IN);

            if(name.length == 0) {
                name = iter.name();
            } else {
                // Name must be the same on all RRs. We do things this way to avoid copying the name
                // repeatedly.
                require(name.length == iter.data.nameLength(iter.offset));
                require(name.equals(0, iter.data, iter.offset, name.length));
            }

            // o  The RRSIG RR's Type Covered field MUST equal the RRset's type.
            require(iter.dnstype == typecovered);
        }
    }

    /**
     * @dev Performs signature verification.
     *
     * Throws or reverts if unable to verify the record.
     *
     * @param name The name of the RRSIG record, in DNS label-sequence format.
     * @param data The original data to verify.
     * @param proof A DS or DNSKEY record that's already verified by the oracle.
     */
    function verifySignature(bytes memory name, RRUtils.SignedSet memory rrset, RRSetWithSignature memory data, bytes memory proof) internal view {
        // o  The RRSIG RR's Signer's Name field MUST be the name of the zone
        //    that contains the RRset.
        require(rrset.signerName.length <= name.length);
        require(rrset.signerName.equals(0, name, name.length - rrset.signerName.length));

        RRUtils.RRIterator memory proofRR = proof.iterateRRs(0);
        // Check the proof
        if (proofRR.dnstype == DNSTYPE_DS) {
            require(verifyWithDS(rrset, data, proofRR));
        } else if (proofRR.dnstype == DNSTYPE_DNSKEY) {
            require(verifyWithKnownKey(rrset, data, proofRR));
        } else {
            revert("No valid proof found");
        }
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known public key.
     * @param rrset The signed set to verify.
     * @param data The original data the signed set was read from.
     * @param proof The serialized DS or DNSKEY record to use as proof.
     * @return True if the RRSET could be verified, false otherwise.
     */
    function verifyWithKnownKey(RRUtils.SignedSet memory rrset, RRSetWithSignature memory data, RRUtils.RRIterator memory proof) internal view returns(bool) {
        // Check the DNSKEY's owner name matches the signer name on the RRSIG
        require(proof.name().equals(rrset.signerName));
        for(; !proof.done(); proof.next()) {
            require(proof.name().equals(rrset.signerName));
            bytes memory keyrdata = proof.rdata();
            RRUtils.DNSKEY memory dnskey = keyrdata.readDNSKEY(0, keyrdata.length);
            if(verifySignatureWithKey(dnskey, keyrdata, rrset, data)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Attempts to verify some data using a provided key and a signature.
     * @param dnskey The dns key record to verify the signature with.
     * @param rrset The signed RRSET being verified.
     * @param data The original data `rrset` was decoded from.
     * @return True iff the key verifies the signature.
     */
    function verifySignatureWithKey(RRUtils.DNSKEY memory dnskey, bytes memory keyrdata, RRUtils.SignedSet memory rrset, RRSetWithSignature memory data)
        internal
        view
        returns (bool)
    {
        // TODO: Check key isn't expired, unless updating key itself

        // The Protocol Field MUST have value 3 (RFC4034 2.1.2)
        if(dnskey.protocol != 3) {
            return false;
        }

        // o The RRSIG RR's Signer's Name, Algorithm, and Key Tag fields MUST
        //   match the owner name, algorithm, and key tag for some DNSKEY RR in
        //   the zone's apex DNSKEY RRset.
        if(dnskey.algorithm != rrset.algorithm) {
            return false;
        }
        uint16 computedkeytag = keyrdata.computeKeytag();
        if (computedkeytag != rrset.keytag) {
            return false;
        }

        // o The matching DNSKEY RR MUST be present in the zone's apex DNSKEY
        //   RRset, and MUST have the Zone Flag bit (DNSKEY RDATA Flag bit 7)
        //   set.
        if (dnskey.flags & DNSKEY_FLAG_ZONEKEY == 0) {
            return false;
        }

        return algorithms[dnskey.algorithm].verify(keyrdata, data.rrset, data.sig);
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known hash. This function assumes
     *      that the record 
     * @param rrset The signed set to verify.
     * @param data The original data the signed set was read from.
     * @param proof The serialized DS or DNSKEY record to use as proof.
     * @return True if the RRSET could be verified, false otherwise.
     */
    function verifyWithDS(RRUtils.SignedSet memory rrset, RRSetWithSignature memory data, RRUtils.RRIterator memory proof) internal view returns(bool) {
        for(RRUtils.RRIterator memory iter = rrset.rrs(); !iter.done(); iter.next()) {
            require(iter.dnstype == DNSTYPE_DNSKEY);
            bytes memory keyrdata = iter.rdata();
            RRUtils.DNSKEY memory dnskey = keyrdata.readDNSKEY(0, keyrdata.length);
            if (verifySignatureWithKey(dnskey, keyrdata, rrset, data)) {
                // It's self-signed - look for a DS record to verify it.
                return verifyKeyWithDS(iter.name(), proof, dnskey, keyrdata);
            }
        }
        return false;
    }

    /**
     * @dev Attempts to verify a key using DS records.
     * @param keyname The DNS name of the key, in DNS label-sequence format.
     * @param dsrrs The DS records to use in verification.
     * @param dnskey The dnskey to verify.
     * @param keyrdata The RDATA section of the key.
     * @return True if a DS record verifies this key.
     */
    function verifyKeyWithDS(bytes memory keyname, RRUtils.RRIterator memory dsrrs, RRUtils.DNSKEY memory dnskey, bytes memory keyrdata)
        internal view returns (bool)
    {
        uint16 keytag = keyrdata.computeKeytag();
        for (; !dsrrs.done(); dsrrs.next()) {
            RRUtils.DS memory ds = dsrrs.data.readDS(dsrrs.rdataOffset, dsrrs.nextOffset - dsrrs.rdataOffset);
            if(ds.keytag != keytag) {
                continue;
            }
            if (ds.algorithm != dnskey.algorithm) {
                continue;
            }

            Buffer.buffer memory buf;
            buf.init(keyname.length + keyrdata.length);
            buf.append(keyname);
            buf.append(keyrdata);
            if (verifyDSHash(ds.digestType, buf.buf, ds.digest)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Attempts to verify a DS record's hash value against some data.
     * @param digesttype The digest ID from the DS record.
     * @param data The data to digest.
     * @param digest The digest data to check against.
     * @return True iff the digest matches.
     */
    function verifyDSHash(uint8 digesttype, bytes memory data, bytes memory digest) internal view returns (bool) {
        if (address(digests[digesttype]) == address(0)) {
            return false;
        }
        return digests[digesttype].verify(data, digest);
    }
}