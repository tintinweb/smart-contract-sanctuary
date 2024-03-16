/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-25
*/

// File: contracts/algorithms/Algorithm.sol

pragma solidity >0.4.23;

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
    function verify(bytes calldata key, bytes calldata data, bytes calldata signature) external view returns (bool);
}

// File: contracts/BytesUtils.sol

pragma solidity >0.4.23;

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

// File: @ensdomains/buffer/contracts/Buffer.sol

pragma solidity >0.4.18;

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

// File: contracts/algorithms/ModexpPrecompile.sol

pragma solidity >0.4.23;


library ModexpPrecompile {
    using Buffer for *;
    using BytesUtils for *;

    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < uint8(10)) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    function bytes32ToAsciiString(bytes32 _bytes32, uint len) private pure returns (string memory) {
        bytes memory s = new bytes((len*2)+2);
        s[0] = 0x30;
        s[1] = 0x78;
      
        for (uint i = 0; i < len; i++) {
            byte b = byte(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2+(2 * i)] = char(hi);
            s[2+(2 * i) + 1] = char(lo);
        }
        return string(s);
    }
    function bytesMemoryTobytes32(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }


    /**
    * @dev Computes (base ^ exponent) % modulus over big numbers.
    */
    
    function getM(bytes memory _modulus) private pure returns(bytes32 a) {
      assembly {
          a := mload(_modulus)
      }
    }
    
    function getInput(Buffer.buffer memory _input) private pure returns(bytes32 a) {
      assembly {
          a := mload(_input)
      }
    }

    function getInputAdd(Buffer.buffer memory _input) private pure returns(bytes32 a) {
      assembly {
          a := add(mload(_input), 32)
      }
    }

    function getCallAddress(bytes32 _call) private pure returns(bytes32 a) {
      assembly {
          a := mload(_call)
      }
    }
  
    function getMem(bytes32 _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(_data)
      }
    }

    function getOutput(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(_data)
      }
    }


    
    function modexp(bytes memory base, bytes memory exponent, bytes memory modulus) internal view returns (bool success, bytes memory output) {
    
        uint size = (32 * 3) + base.length + exponent.length + modulus.length;

        //require(1==2,bytes32ToAsciiString(bytes32(base.length),32));          // signature len = 0x100 ok  base = signature
        //require(1==2,bytes32ToAsciiString(bytes32(modulus.length),32));       // modulus   len = 0x100 ok
        //require(1==2,bytes32ToAsciiString(bytes32(size),32));                 // size          = 0x263 ok

        Buffer.buffer memory input;
        input.init(size);

        input.appendBytes32(bytes32(base.length));                              // signature 0x100   0x0020
        input.appendBytes32(bytes32(exponent.length));                          // exponent     03   0x0040
        input.appendBytes32(bytes32(modulus.length));                           // modulus   0x100   0x0060
        input.append(base);
        input.append(exponent);
        input.append(modulus);

        output = new bytes(modulus.length);                                     // 0x100

        //require(1==2,bytes32ToAsciiString(getM(modulus),32));                   // 0x100 string length of modulus
        //require(1==2,bytes32ToAsciiString(getInput(input),32));                 // 0xc80  input
        //require(1==2,bytes32ToAsciiString(getInputAdd(input),32));              // 0xca0  input
        
        //require(1==2,bytes32ToAsciiString(bytes32(uint256(address(this))),20)); // this contract = e.g. 0x85da6affb299f546c60f59bd50f0fef03208de0a ok
        
        //require(1==2,bytes32ToAsciiString(getCallAddress(bytes32(0x0000000000000000000000000000000000000000000000000000000000000005)),32)); // 0x0000000000000000000000000000000000000000000000000000000000000000

        //require(1==2,bytes32ToAsciiString(getMem(bytes32(0x0000000000000000000000000000000000000000000000000000000000000ca0)),32)); // 0x0000000000000000000000000000000000000000000000000000000000000100    input buffer
        //require(1==2,bytes32ToAsciiString(getMem(bytes32(0x0000000000000000000000000000000000000000000000000000000000000cc0)),32)); // 0x0000000000000000000000000000000000000000000000000000000000000003 
        //require(1==2,bytes32ToAsciiString(getMem(bytes32(0x0000000000000000000000000000000000000000000000000000000000000ce0)),32)); // 0x0000000000000000000000000000000000000000000000000000000000000100 
        
        
      //require(1==2,bytes32ToAsciiString(bytes32(uint256(address(RSAVerify))),20));
      
        
        assembly {
            success := staticcall(gas(), 5, add(mload(input), 32), size, add(output, 32), mload(modulus))      // gas(), call to(5,4,6 not 3) ?, 0xca0, insize 263, out 0x20 0x100
        }
        
        //require(1==2,bytes32ToAsciiString(output.readBytes32(0),32)); // with 5: 0x0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

    }
}

// File: contracts/algorithms/RSAVerify.sol

pragma solidity >0.4.23;



library RSAVerify {
    /**
    * @dev Recovers the input data from an RSA signature, returning the result in S.
    * @param N The RSA public modulus.
    * @param E The RSA public exponent.
    * @param S The signature to recover.
    * @return True if the recovery succeeded.
    */
    function rsarecover(bytes memory N, bytes memory E, bytes memory S) internal view returns (bool, bytes memory) {
        return ModexpPrecompile.modexp(S, E, N);  
    }
}

// File: contracts/algorithms/RSASHA256Algorithm.sol

pragma solidity >0.4.23;




/**
* @dev Implements the DNSSEC RSASHA256 algorithm.
*/
contract RSASHA256Algorithm is Algorithm {
    using BytesUtils for *;


    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < uint8(10)) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function bytes32ToAsciiString(bytes32 _bytes32, uint len) private pure returns (string memory) {
        bytes memory s = new bytes((len*2)+2);
        s[0] = 0x30;
        s[1] = 0x78;
      
        for (uint i = 0; i < len; i++) {
            byte b = byte(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2+(2 * i)] = char(hi);
            s[2+(2 * i) + 1] = char(lo);
        }
        return string(s);
    }

    function bytesMemoryTobytes32(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }


    function verify(bytes calldata key, bytes calldata data, bytes calldata sig) external view returns (bool) {
        bytes memory exponent;
        bytes memory modulus;


        // key DNSTYPE_DNSKEY + header -----------------------------------------

        //require(1==2,bytes32ToAsciiString(bytes32(key.length),32));                                                // 108 keyLength
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(key.substring(0,    32)),32));                      // DNSTYPE_DNSKEY of 2nd RRSet 0x0101 03 08 03 010001 acffb409bcc939f831f7a1e5ec88f7a59255ec53040be432  ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(key.substring(32,   32)),32));                      // 0x027390a4ce896d6f9086f3c5e177fbfe118163aaec7af1462c47945944c4e2c0 ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(key.substring(224,  32)),32));                      // 0x5466fb684cf009d7197c2cf79e792ab501e6a8a1ca519af2cb9b5f6367e94c0d ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(key.substring(256,   8)),32));                      // 0x47502451357be1b5000000000000000000000000000000000000000000000000 ok


        uint16 exponentLen = uint16(key.readUint8(4));
        
        //require(1==2,bytes32ToAsciiString(bytes32(uint256(exponentLen)),32));                                      // 3 exponentLength


        if (exponentLen != 0) {
            exponent = key.substring(5, exponentLen);
            modulus = key.substring(exponentLen + 5, key.length - exponentLen - 5);                                  // modulus == pubKey 0x100
            
            //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(exponent),32));                                 // exponent '0x010001'  
            
            //require(1==2,bytes32ToAsciiString(bytes32(uint256(modulus.length)),32));                               // 0xacffb409bcc939f831f7a1e5ec88f7a59255ec53040be432027390a4ce896d6f ....  len 0x100  pubKey ?????
            
        } else {
            exponentLen = key.readUint16(5);
            exponent = key.substring(7, exponentLen);
            modulus = key.substring(exponentLen + 7, key.length - exponentLen - 7);
        }



        // signature ----------------------------------------------------------

        //require(1==2,bytes32ToAsciiString(bytes32(uint256(sig.length)),32));                                        // signature len = 0x100 ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(0,  32)),32));                         // 0x6cabece2206db12ef1e1422d06c3712671b3294a3098e37be8026de834255237 ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(32, 32)),32));                         // 0x035dd98d5065b40cd7f0cfdd540a77e89e535e1b4f6609b445ce17eb80d884d8 ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(64, 32)),32));                         // 0xd8aed10c61f8473280e8eecb5b8e6dc3e014152c2a9db4d6ed16150c2b525e0e ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(96, 32)),32));                         //   ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(128,32)),32));                         //   ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(160,32)),32));                         //   ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(192,32)),32));                         //   ok
        //require(1==2,bytes32ToAsciiString(bytesMemoryTobytes32(sig.substring(224,32)),32));                         // 0x3a945d965d50ad1106dd2e872cb825e59f7c3f9fc8ceda8241a2d43b4ba1386d ok


        // Recover the message from the signature
        bool ok;
        bytes memory result;
        
        (ok, result) = RSAVerify.rsarecover(modulus, exponent, sig);
        
        
        require(ok == true,"inside rsarecover FAILED");
        require(result.length==modulus.length,bytes32ToAsciiString(bytes32(uint256(result.length)),32));


        // rsarecover ----------------------------------------------------------
        
        //require(1==2,  bytes32ToAsciiString(bytes32(uint256(result.length)),32));                                    // rsarecover len = 0x100 ok
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(0, 32)),32));                      // 0x0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0x20
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(32, 32)),32));                     // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0x40
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(64, 32)),32));                     // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0x60
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(96, 32)),32));                     // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0x80
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(128,32)),32));                     // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0xa0
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(160,32)),32));                     // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0xc0
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(192,32)),32));                     // 0xffffffffffffffffffffffff003031300d060960864801650304020105000420 0xe0  **** 20 bytes sha256 prefix header  0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20    
        //require(1==2,  bytes32ToAsciiString(bytesMemoryTobytes32(result.substring(224,32)),32));                     // 0x6388720de1ebc82a6bf8a9f9c2be80d9d14fea5311442a2ca99465aafbc4abb2 0x100 **** 32 bytes sha256(data) RDATA HASH ****

        
        // data == load, RRSets-------------------------------------------------

        //  require(sha256(data) == result.readBytes32(result.length - 32),bytes32ToAsciiString(bytes32(uint256(data.length)),32));                                      // RRSIG RDATA length       e.g. 0x34c  ok  or or 006d or 0x25c
        //  require(sha256(data) == result.readBytes32(result.length - 32),bytes32ToAsciiString(bytesMemoryTobytes32( data.substring(0, 32) ),32));                      // RRSIG RDATA  header      e.g. 0x0030080100000e1060417480601350000e0f0378797a000378797a0000300001 OK      
        //  require(sha256(data) == result.readBytes32(result.length - 32),bytes32ToAsciiString( sha256(data),32 ));                                                     // hash of data             e.g. 0xce4644fcaa29c92e15b0e41f311e42e392b7876ed26f2c53a3c8338b2d1ec6eb OK ****
        //  require(sha256(data) == result.readBytes32(result.length - 32),bytes32ToAsciiString(bytesMemoryTobytes32( data.substring(data.length-32, 32) ),32));         // data last word 3rd rrset e.g. 0xaf44124ba232307cc619e22554015eb5b6b13f53babb8525c8f74fdbbc46ec2d bad
        
        
        //  require(1==2,bytes32ToAsciiString(result.readBytes32(result.length - 32),32));                             // rsa recovered hash from sig,  0x6388720de1ebc82a6bf8a9f9c2be80d9d14fea5311442a2ca99465aafbc4abb2  ** ok **

        
        // require(sha256(data) == result.readBytes32(result.length - 32),"inside rsarecover sha256 FAILED");  // ****** ONLY FOR DEBUGGING *********

        // Verify it ends with the hash of our data
        return ok && sha256(data) == result.readBytes32(result.length - 32);
    }
}