pragma solidity ^0.4.23;

// File: contracts/BytesUtils.sol

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
            ret := sha3(add(add(self, 32), offset), len)
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
                    mask = uint256(- 1); // aka 0xffffff....
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint diff = (a & mask) - (b & mask);
                if (diff != 0)
                return int(diff);
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
    * @dev Compares a range of &#39;self&#39; to all of &#39;other&#39; and returns True iff
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
        require(idx + 1 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 1), idx)), 0xFF)
        }
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
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes20 ret) {
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
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
    * @dev Copies a substring into a new byte string.
    * @param self The byte string to copy from.
    * @param offset The offset to start copying at.
    * @param len The number of bytes to copy.
    */
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes) {
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
    bytes constant base32HexTable = hex&#39;00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F&#39;;

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
        for(uint i = 0; i < len; i++) {
            byte char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            uint8 decoded = uint8(base32HexTable[uint(char) - 0x30]);
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

// File: contracts/DNSSEC.sol

interface DNSSEC {

    event AlgorithmUpdated(uint8 id, address addr);
    event DigestUpdated(uint8 id, address addr);
    event NSEC3DigestUpdated(uint8 id, address addr);
    event RRSetUpdated(bytes name, bytes rrset);

    function submitRRSets(bytes memory data, bytes memory proof) public returns (bytes);
    function submitRRSet(bytes memory input, bytes memory sig, bytes memory proof) public returns(bytes memory rrs);
    function deleteRRSet(uint16 deleteType, bytes deleteName, bytes memory nsec, bytes memory sig, bytes memory proof) public;
    function rrdata(uint16 dnstype, bytes memory name) public view returns (uint32, uint64, bytes20);

}

// File: contracts/Owned.sol

/**
* @dev Contract mixin for &#39;owned&#39; contracts.
*/
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier owner_only() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) public owner_only {
        owner = newOwner;
    }
}

// File: @ensdomains/buffer/contracts/Buffer.sol

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
            mstore(0x40, add(ptr, capacity))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes b) internal pure returns(buffer memory) {
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
    function write(buffer memory buf, uint off, bytes data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len + buf.buf.length > buf.capacity) {
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
            // Update buffer length if we&#39;re extending it
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
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
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
    function append(buffer memory buf, bytes data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes data) internal pure returns (buffer memory) {
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
        if (off > buf.capacity) {
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
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
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
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint mask = 256 ** len - 1;
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
}

// File: contracts/RRUtils.sol

/**
* @dev RRUtils is a library that provides utilities for parsing DNS resource records.
*/
library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

    /**
    * @dev Returns the number of bytes in the DNS name at &#39;offset&#39; in &#39;self&#39;.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The length of the DNS name at &#39;offset&#39;, in bytes.
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
    * @return The name.
    */
    function readName(bytes memory self, uint offset) internal pure returns(bytes memory ret) {
        uint len = nameLength(self, offset);
        return self.substring(offset, len);
    }

    /**
    * @dev Returns the number of labels in the DNS name at &#39;offset&#39; in &#39;self&#39;.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The number of labels in the DNS name at &#39;offset&#39;, in bytes.
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
    * @return An iterator object.
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
    * @return A new bytes object containing the RR&#39;s RDATA.
    */
    function rdata(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

    /**
    * @dev Checks if a given RR type exists in a type bitmap.
    * @param self The byte string to read the type bitmap from.
    * @param offset The offset to start reading at.
    * @param rrtype The RR type to check for.
    * @return True if the type is found in the bitmap, false otherwise.
    */
    function checkTypeBitmap(bytes memory self, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(uint8(1) << (uint8(7) - uint8(rrtype & 0x7)));
        for (uint off = offset; off < self.length;) {
            uint8 window = self.readUint8(off);
            uint8 len = self.readUint8(off + 1);
            if (typeWindow < window) {
                // We&#39;ve gone past our window; it&#39;s not here.
                return false;
            } else if (typeWindow == window) {
                // Check this type bitmap
                if (len * 8 <= windowByte) {
                    // Our type is past the end of the bitmap
                    return false;
                }
                return (self.readUint8(off + windowByte + 2) & windowBitmask) != 0;
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

    function progress(bytes memory body, uint off) internal pure returns(uint) {
        return off + 1 + body.readUint8(off);
    }
}

// File: contracts/algorithms/Algorithm.sol

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
    function verify(bytes key, bytes data, bytes signature) external view returns (bool);
}

// File: contracts/digests/Digest.sol

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
    function verify(bytes data, bytes hash) external pure returns (bool);
}

// File: contracts/nsec3digests/NSEC3Digest.sol

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
     function hash(bytes salt, bytes data, uint iterations) external pure returns (bytes32);
}

// File: contracts/DNSSECImpl.sol

/*
 * @dev An oracle contract that verifies and stores DNSSEC-validated DNS records.
 *
 * TODO: Support for NSEC3 records
 * TODO: Use &#39;serial number math&#39; for inception/expiration
 */
contract DNSSECImpl is DNSSEC, Owned {
    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using RRUtils for *;

    uint16 constant DNSCLASS_IN = 1;

    uint16 constant DNSTYPE_DS = 43;
    uint16 constant DNSTYPE_RRSIG = 46;
    uint16 constant DNSTYPE_NSEC = 47;
    uint16 constant DNSTYPE_DNSKEY = 48;
    uint16 constant DNSTYPE_NSEC3 = 50;

    uint constant DS_KEY_TAG = 0;
    uint constant DS_ALGORITHM = 2;
    uint constant DS_DIGEST_TYPE = 3;
    uint constant DS_DIGEST = 4;

    uint constant RRSIG_TYPE = 0;
    uint constant RRSIG_ALGORITHM = 2;
    uint constant RRSIG_LABELS = 3;
    uint constant RRSIG_TTL = 4;
    uint constant RRSIG_EXPIRATION = 8;
    uint constant RRSIG_INCEPTION = 12;
    uint constant RRSIG_KEY_TAG = 16;
    uint constant RRSIG_SIGNER_NAME = 18;

    uint constant DNSKEY_FLAGS = 0;
    uint constant DNSKEY_PROTOCOL = 2;
    uint constant DNSKEY_ALGORITHM = 3;
    uint constant DNSKEY_PUBKEY = 4;

    uint constant DNSKEY_FLAG_ZONEKEY = 0x100;

    uint constant NSEC3_HASH_ALGORITHM = 0;
    uint constant NSEC3_FLAGS = 1;
    uint constant NSEC3_ITERATIONS = 2;
    uint constant NSEC3_SALT_LENGTH = 4;
    uint constant NSEC3_SALT = 5;

    uint8 constant ALGORITHM_RSASHA256 = 8;

    uint8 constant DIGEST_ALGORITHM_SHA256 = 2;

    struct RRSet {
        uint32 inception;
        uint64 inserted;
        bytes20 hash;
    }

    // (name, type) => RRSet
    mapping (bytes32 => mapping(uint16 => RRSet)) rrsets;

    bytes public anchors;

    mapping (uint8 => Algorithm) public algorithms;
    mapping (uint8 => Digest) public digests;
    mapping (uint8 => NSEC3Digest) public nsec3Digests;

    /**
     * @dev Constructor.
     * @param _anchors The binary format RR entries for the root DS records.
     */
    constructor(bytes _anchors) public {
        // Insert the &#39;trust anchors&#39; - the key hashes that start the chain
        // of trust for all other records.
        anchors = _anchors;
        rrsets[keccak256(hex"00")][DNSTYPE_DS] = RRSet({
            inception: uint32(0),
            inserted: uint64(now),
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
        emit AlgorithmUpdated(id, algo);
    }

    /**
     * @dev Sets the contract address for a digest verification algorithm.
     *      Callable only by the owner.
     * @param id The digest ID
     * @param digest The address of the digest contract.
     */
    function setDigest(uint8 id, Digest digest) public owner_only {
        digests[id] = digest;
        emit DigestUpdated(id, digest);
    }

    /**
     * @dev Sets the contract address for an NSEC3 digest algorithm.
     *      Callable only by the owner.
     * @param id The digest ID
     * @param digest The address of the digest contract.
     */
    function setNSEC3Digest(uint8 id, NSEC3Digest digest) public owner_only {
        nsec3Digests[id] = digest;
        emit NSEC3DigestUpdated(id, digest);
    }

    /**
     * @dev Submits multiple RRSets
     * @param data The data to submit, as a series of chunks. Each chunk is
     *        in the format <uint16 length><bytes input><uint16 length><bytes sig>
     * @param proof The DNSKEY or DS to validate the first signature against.
     * @return The last RRSET submitted.
     */
    function submitRRSets(bytes memory data, bytes memory proof) public returns (bytes) {
        uint offset = 0;
        while(offset < data.length) {
            bytes memory input = data.substring(offset + 2, data.readUint16(offset));
            offset += input.length + 2;
            bytes memory sig = data.substring(offset + 2, data.readUint16(offset));
            offset += sig.length + 2;
            proof = submitRRSet(input, sig, proof);
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
     * @param sig The signature data from the RRSIG record.
     * @param proof The DNSKEY or DS to validate the signature against. Must Already
     *        have been submitted and proved previously.
     */
    function submitRRSet(bytes memory input, bytes memory sig, bytes memory proof)
        public returns(bytes memory rrs)
    {
        bytes memory name;
        (name, rrs) = validateSignedSet(input, sig, proof);

        uint32 inception = input.readUint32(RRSIG_INCEPTION);
        uint16 typecovered = input.readUint16(RRSIG_TYPE);

        RRSet storage set = rrsets[keccak256(name)][typecovered];
        if (set.inserted > 0) {
            // To replace an existing rrset, the signature must be at least as new
            require(inception >= set.inception);
        }
        if (set.hash == keccak256(rrs)) {
            // Already inserted!
            return;
        }

        rrsets[keccak256(name)][typecovered] = RRSet({
            inception: inception,
            inserted: uint64(now),
            hash: bytes20(keccak256(rrs))
        });
        emit RRSetUpdated(name, rrs);
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
    function deleteRRSet(uint16 deleteType, bytes deleteName, bytes memory nsec, bytes memory sig, bytes memory proof) public {
        bytes memory nsecName;
        bytes memory rrs;
        (nsecName, rrs) = validateSignedSet(nsec, sig, proof);

        // Don&#39;t let someone use an old proof to delete a new name
        require(rrsets[keccak256(deleteName)][deleteType].inception <= nsec.readUint32(RRSIG_INCEPTION));

        for (RRUtils.RRIterator memory iter = rrs.iterateRRs(0); !iter.done(); iter.next()) {
            // We&#39;re dealing with three names here:
            //   - deleteName is the name the user wants us to delete
            //   - nsecName is the owner name of the NSEC record
            //   - nextName is the next name specified in the NSEC record
            //
            // And three cases:
            //   - deleteName equals nsecName, in which case we can delete the
            //     record if it&#39;s not in the type bitmap.
            //   - nextName comes after nsecName, in which case we can delete
            //     the record if deleteName comes between nextName and nsecName.
            //   - nextName comes before nsecName, in which case nextName is the
            //     zone apez, and deleteName must come after nsecName.

            if(iter.dnstype == DNSTYPE_NSEC) {
                checkNsecName(iter, nsecName, deleteName, deleteType);
            } else if(iter.dnstype == DNSTYPE_NSEC3) {
                checkNsec3Name(iter, nsecName, deleteName, deleteType);
            } else {
                revert("Unrecognised record type");
            }

            delete rrsets[keccak256(deleteName)][deleteType];
            return;
        }
        // This should never reach.
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

    function checkNsec3Name(RRUtils.RRIterator memory iter, bytes memory nsecName, bytes memory deleteName, uint16 deleteType) private view {
        uint16 iterations = iter.data.readUint16(iter.rdataOffset + NSEC3_ITERATIONS);
        uint8 saltLength = iter.data.readUint8(iter.rdataOffset + NSEC3_SALT_LENGTH);
        bytes memory salt = iter.data.substring(iter.rdataOffset + NSEC3_SALT, saltLength);
        bytes32 deleteNameHash = nsec3Digests[iter.data.readUint8(iter.rdataOffset)].hash(salt, deleteName, iterations);

        uint8 nextLength = iter.data.readUint8(iter.rdataOffset + NSEC3_SALT + saltLength);
        require(nextLength <= 32);
        bytes32 nextNameHash = iter.data.readBytesN(iter.rdataOffset + NSEC3_SALT + saltLength + 1, nextLength);

        bytes32 nsecNameHash = nsecName.base32HexDecodeWord(1, uint(nsecName.readUint8(0)));

        if(deleteNameHash == nsecNameHash) {
            // Name to delete is on the same label as the NSEC record
            require(!iter.data.checkTypeBitmap(iter.rdataOffset + NSEC3_SALT + saltLength + 1 + nextLength, deleteType));
        } else {
            // deleteName must come after nsecName
            require(deleteNameHash > nsecNameHash);
            // Check if the NSEC next name comes after the NSEC name.
            if(nextNameHash > nsecNameHash) {
                // deleteName must come also come before nextName
                require(deleteNameHash < nextNameHash);
            }
        }
    }

    /**
     * @dev Returns data about the RRs (if any) known to this oracle with the provided type and name.
     * @param dnstype The DNS record type to query.
     * @param name The name to query, in DNS label-sequence format.
     * @return inception The unix timestamp at which the signature for this RRSET was created.
     * @return inserted The unix timestamp at which this RRSET was inserted into the oracle.
     * @return hash The hash of the RRset that was inserted.
     */
    function rrdata(uint16 dnstype, bytes memory name) public view returns (uint32, uint64, bytes20) {
        RRSet storage result = rrsets[keccak256(name)][dnstype];
        return (result.inception, result.inserted, result.hash);
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
     * @param sig The signature data from the RRSIG record.
     * @param proof The DNSKEY or DS to validate the signature against. Must Already
     *        have been submitted and proved previously.
     */
    function validateSignedSet(bytes memory input, bytes memory sig, bytes memory proof) internal view returns(bytes memory name, bytes memory rrs) {
        require(validProof(input.readName(RRSIG_SIGNER_NAME), proof));

        uint32 inception = input.readUint32(RRSIG_INCEPTION);
        uint32 expiration = input.readUint32(RRSIG_EXPIRATION);
        uint16 typecovered = input.readUint16(RRSIG_TYPE);
        uint8 labels = input.readUint8(RRSIG_LABELS);

        // Extract the RR data
        uint rrdataOffset = input.nameLength(RRSIG_SIGNER_NAME) + 18;
        rrs = input.substring(rrdataOffset, input.length - rrdataOffset);

        // Do some basic checks on the RRs and extract the name
        name = validateRRs(rrs, typecovered);
        require(name.labelCount(0) == labels);

        // TODO: Check inception and expiration using mod2^32 math

        // o  The validator&#39;s notion of the current time MUST be less than or
        //    equal to the time listed in the RRSIG RR&#39;s Expiration field.
        require(expiration > now);

        // o  The validator&#39;s notion of the current time MUST be greater than or
        //    equal to the time listed in the RRSIG RR&#39;s Inception field.
        require(inception < now);

        // Validate the signature
        verifySignature(name, input, sig, proof);

        return (name, rrs);
    }

    function validProof(bytes name, bytes memory proof) internal view returns(bool) {
        uint16 dnstype = proof.readUint16(proof.nameLength(0));
        return rrsets[keccak256(name)][dnstype].hash == bytes20(keccak256(proof));
    }

    /**
     * @dev Validates a set of RRs.
     * @param data The RR data.
     * @param typecovered The type covered by the RRSIG record.
     */
    function validateRRs(bytes memory data, uint16 typecovered) internal pure returns (bytes memory name) {
        // Iterate over all the RRs
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            // We only support class IN (Internet)
            require(iter.class == DNSCLASS_IN);

            if(name.length == 0) {
                name = iter.name();
            } else {
                // Name must be the same on all RRs
                require(name.length == data.nameLength(iter.offset));
                require(name.equals(0, data, iter.offset, name.length));
            }

            // o  The RRSIG RR&#39;s Type Covered field MUST equal the RRset&#39;s type.
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
     * @param sig The signature data.
     */
    function verifySignature(bytes name, bytes memory data, bytes memory sig, bytes memory proof) internal view {
        uint signerNameLength = data.nameLength(RRSIG_SIGNER_NAME);

        // o  The RRSIG RR&#39;s Signer&#39;s Name field MUST be the name of the zone
        //    that contains the RRset.
        require(signerNameLength <= name.length);
        require(data.equals(RRSIG_SIGNER_NAME, name, name.length - signerNameLength, signerNameLength));

        // Set the return offset to point at the first RR
        uint offset = 18 + signerNameLength;

        // Check the proof
        uint16 dnstype = proof.readUint16(proof.nameLength(0));
        if (dnstype == DNSTYPE_DS) {
            require(verifyWithDS(data, sig, offset, proof));
        } else if (dnstype == DNSTYPE_DNSKEY) {
            require(verifyWithKnownKey(data, sig, proof));
        } else {
            revert("Unsupported proof record type");
        }
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known public key.
     * @param data The original data to verify.
     * @param sig The signature data.
     * @return True if the RRSET could be verified, false otherwise.
     */
    function verifyWithKnownKey(bytes memory data, bytes memory sig, bytes memory proof) internal view returns(bool) {
        uint signerNameLength = data.nameLength(RRSIG_SIGNER_NAME);

        // Extract algorithm and keytag
        uint8 algorithm = data.readUint8(RRSIG_ALGORITHM);
        uint16 keytag = data.readUint16(RRSIG_KEY_TAG);

        for (RRUtils.RRIterator memory iter = proof.iterateRRs(0); !iter.done(); iter.next()) {
            // Check the DNSKEY&#39;s owner name matches the signer name on the RRSIG
            require(proof.nameLength(0) == signerNameLength);
            require(proof.equals(0, data, RRSIG_SIGNER_NAME, signerNameLength));
            if (verifySignatureWithKey(iter.rdata(), algorithm, keytag, data, sig)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known public key.
     * @param data The original data to verify.
     * @param sig The signature data.
     * @param offset The offset from the start of the data to the first RR.
     * @return True if the RRSET could be verified, false otherwise.
     */
    function verifyWithDS(bytes memory data, bytes memory sig, uint offset, bytes memory proof) internal view returns(bool) {
        // Extract algorithm and keytag
        uint8 algorithm = data.readUint8(RRSIG_ALGORITHM);
        uint16 keytag = data.readUint16(RRSIG_KEY_TAG);

        // Perhaps it&#39;s self-signed and verified by a DS record?
        for (RRUtils.RRIterator memory iter = data.iterateRRs(offset); !iter.done(); iter.next()) {
            if (iter.dnstype != DNSTYPE_DNSKEY) {
                return false;
            }

            bytes memory keyrdata = iter.rdata();
            if (verifySignatureWithKey(keyrdata, algorithm, keytag, data, sig)) {
                // It&#39;s self-signed - look for a DS record to verify it.
                return verifyKeyWithDS(iter.name(), keyrdata, keytag, algorithm, proof);
            }
        }

        return false;
    }

    /**
     * @dev Attempts to verify some data using a provided key and a signature.
     * @param keyrdata The RDATA section of the key to use.
     * @param algorithm The algorithm ID of the key and signature.
     * @param keytag The keytag from the signature.
     * @param data The data to verify.
     * @param sig The signature to use.
     * @return True iff the key verifies the signature.
     */
    function verifySignatureWithKey(bytes memory keyrdata, uint8 algorithm, uint16 keytag, bytes data, bytes sig) internal view returns (bool) {
        if (algorithms[algorithm] == address(0)) {
            return false;
        }
        // TODO: Check key isn&#39;t expired, unless updating key itself

        // o The RRSIG RR&#39;s Signer&#39;s Name, Algorithm, and Key Tag fields MUST
        //   match the owner name, algorithm, and key tag for some DNSKEY RR in
        //   the zone&#39;s apex DNSKEY RRset.
        if (keyrdata.readUint8(DNSKEY_PROTOCOL) != 3) {
            return false;
        }
        if (keyrdata.readUint8(DNSKEY_ALGORITHM) != algorithm) {
            return false;
        }
        uint16 computedkeytag = computeKeytag(keyrdata);
        if (computedkeytag != keytag) {
            return false;
        }

        // o The matching DNSKEY RR MUST be present in the zone&#39;s apex DNSKEY
        //   RRset, and MUST have the Zone Flag bit (DNSKEY RDATA Flag bit 7)
        //   set.
        if (keyrdata.readUint16(DNSKEY_FLAGS) & DNSKEY_FLAG_ZONEKEY == 0) {
            return false;
        }

        return algorithms[algorithm].verify(keyrdata, data, sig);
    }

    /**
     * @dev Attempts to verify a key using DS records.
     * @param keyname The DNS name of the key, in DNS label-sequence format.
     * @param keyrdata The RDATA section of the key.
     * @param keytag The keytag of the key.
     * @param algorithm The algorithm ID of the key.
     * @return True if a DS record verifies this key.
     */
    function verifyKeyWithDS(bytes memory keyname, bytes memory keyrdata, uint16 keytag, uint8 algorithm, bytes memory data)
        internal view returns (bool)
    {
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            if (data.readUint16(iter.rdataOffset + DS_KEY_TAG) != keytag) {
                continue;
            }
            if (data.readUint8(iter.rdataOffset + DS_ALGORITHM) != algorithm) {
                continue;
            }

            uint8 digesttype = data.readUint8(iter.rdataOffset + DS_DIGEST_TYPE);
            Buffer.buffer memory buf;
            buf.init(keyname.length + keyrdata.length);
            buf.append(keyname);
            buf.append(keyrdata);
            if (verifyDSHash(digesttype, buf.buf, data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Attempts to verify a DS record&#39;s hash value against some data.
     * @param digesttype The digest ID from the DS record.
     * @param data The data to digest.
     * @param digest The digest data to check against.
     * @return True iff the digest matches.
     */
    function verifyDSHash(uint8 digesttype, bytes data, bytes digest) internal view returns (bool) {
        if (digests[digesttype] == address(0)) {
            return false;
        }
        return digests[digesttype].verify(data, digest.substring(4, digest.length - 4));
    }

    /**
     * @dev Computes the keytag for a chunk of data.
     * @param data The data to compute a keytag for.
     * @return The computed key tag.
     */
    function computeKeytag(bytes memory data) internal pure returns (uint16) {
        uint ac;
        for (uint i = 0; i < data.length; i += 2) {
            ac += data.readUint16(i);
        }
        ac += (ac >> 16) & 0xFFFF;
        return uint16(ac & 0xFFFF);
    }
}