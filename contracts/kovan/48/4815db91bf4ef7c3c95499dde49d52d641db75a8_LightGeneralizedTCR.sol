/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity >=0.5.0 <0.7.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        (, uint len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        (uint memPtr, uint len) = payloadLocation(item);

        uint result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint memPtr, uint len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;
        
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}


/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.5.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add 
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))
                
                for { 
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}



/**
 *  @authors: [@mtsalenc]
 *  @reviewers: [@clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.5.16;


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}

 
 /**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.5;


/** @title IArbitrable
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract.
 *  -Allow dispute creation. For this a function must call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 */
interface IArbitrable {

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}


 /**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.5;


/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    /** @dev To be emitted when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be emitted when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be emitted when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes calldata _extraData) external payable returns(uint disputeID);

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns(uint cost);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes calldata _extraData) external payable;

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return cost Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes calldata _extraData) external view returns(uint cost);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint _disputeID) external view returns(uint start, uint end);

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) external view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) external view returns(uint ruling);

}


pragma solidity >=0.5;


/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {

    /** @dev To be emitted when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(IArbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

}


/**
 *  @title LightGeneralizedTCR
 *  This contract is a curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 */
contract LightGeneralizedTCR is IArbitrable, IEvidence {
    using CappedMath for uint256;

    /* Enums */

    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    /* Structs */

    struct Item {
        Status status; // The current status of the item.
        Request[] requests; // List of status change requests made for the item in the form requests[requestID].
    }

    // Arrays with 3 elements map with the Party enum for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        bool disputed; // True if a dispute was raised.
        uint256 disputeID; // ID of the dispute, if any.
        uint256 submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        bool resolved; // True if the request was executed and/or any raised disputes were resolved.
        address payable[3] parties; // Address of requester and challenger, if any, in the form parties[party].
        Round[] rounds; // Tracks each round of a dispute in the form rounds[roundID].
        Party ruling; // The final ruling given, if any.
        IArbitrator arbitrator; // The arbitrator trusted to solve disputes for this request.
        bytes arbitratorExtraData; // The extra data for the trusted arbitrator of this request.
        uint256 metaEvidenceID; // The meta evidence to be used in a dispute for this case.
    }

    struct Round {
        uint256[3] amountPaid; // Tracks the sum paid for each Party in this round. Includes arbitration fees, fee stakes and deposits.
        bool[3] hasPaid; // True if the Party has fully paid its fee in this round.
        uint256 feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        mapping(address => uint256[3]) contributions; // Maps contributors to their contributions for each side in the form contributions[address][party].
    }

    /* Storage */

    bool private initialized;
    IArbitrator public arbitrator; // The arbitrator contract.
    bytes public arbitratorExtraData; // Extra data for the arbitrator contract.

    address public relayContract; // The contract that is used to add or remove items directly to speed up the interchain communication.

    uint256 public constant RULING_OPTIONS = 2; // The amount of non 0 choices the arbitrator can give.

    address public governor; // The address that can make changes to the parameters of the contract.
    uint256 public submissionBaseDeposit; // The base deposit to submit an item.
    uint256 public removalBaseDeposit; // The base deposit to remove an item.
    uint256 public submissionChallengeBaseDeposit; // The base deposit to challenge a submission.
    uint256 public removalChallengeBaseDeposit; // The base deposit to challenge a removal request.
    uint256 public challengePeriodDuration; // The time after which a request becomes executable if not challenged.
    uint256 public metaEvidenceUpdates; // The number of times the meta evidence has been updated. Used to track the latest meta evidence ID.

    // Multipliers are in basis points.
    uint256 public winnerStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that won the previous round.
    uint256 public loserStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that lost the previous round.
    uint256 public sharedStakeMultiplier; // Multiplier for calculating the fee stake that must be paid in the case where arbitrator refused to arbitrate.
    uint256 public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    mapping(bytes32 => Item) public items; // Maps the item ID to its data in the form items[_itemID].
    mapping(address => mapping(uint256 => bytes32))
        public arbitratorDisputeIDToItemID; // Maps a dispute ID to the ID of the item with the disputed request in the form arbitratorDisputeIDToItemID[arbitrator][disputeID].

    /* Modifiers */

    modifier onlyGovernor() {
        require(msg.sender == governor, "The caller must be the governor.");
        _;
    }

    modifier onlyRelay() {
        require(msg.sender == relayContract, "The caller must be the relay.");
        _;
    }

    /* Events */

    /**
     *  @dev Emitted when a party makes a request, raises a dispute or when a request is resolved.
     *  @param _itemID The ID of the affected item.
     *  @param _updatedDirectly Whether this was emitted in either `addItemDirectly` or `removeItemDirectly`. This is used in the subgraph.
     */
    event ItemStatusChange(bytes32 indexed _itemID, bool _updatedDirectly);

    /**
     *  @dev Emitted when someone submits an item for the first time.
     *  @param _itemID The ID of the new item.
     *  @param _data The item data URI.
     */
    event NewItem(bytes32 indexed _itemID, string _data);

    /**
     *  @dev Emitted when someone submits a request.
     *  @param _itemID The ID of the affected item.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     */
    event RequestSubmitted(bytes32 indexed _itemID, uint256 _evidenceGroupID);

    /**
     *  @dev Emitted when a party contributes to an appeal.
     *  @param _itemID The ID of the item.
     *  @param _contributor The address making the contribution.
     *  @param _contribution How much was of the contribution was accepted.
     *  @param _side The party receiving the contribution.
     */
    event Contribution(
        bytes32 indexed _itemID,
        address indexed _contributor,
        uint256 _contribution,
        Party _side
    );

    /** @dev Emitted when the address of the connected TCR is set. The connected TCR is an instance of the Generalized TCR contract where each item is the address of a TCR related to this one.
     *  @param _connectedTCR The address of the connected TCR.
     */
    event ConnectedTCRSet(address indexed _connectedTCR);

    /** @dev Emitted when someone withdraws more than 0 rewards.
     *  @param _beneficiary The address that made contributions to a request.
     *  @param _itemID The ID of the item submission to withdraw.
     *  @param _request The request from which to withdraw.
     *  @param _round The round from which to withdraw.
     */
    event RewardWithdrawn(
        address indexed _beneficiary,
        bytes32 indexed _itemID,
        uint256 _request,
        uint256 _round
    );

    constructor() public {}

    /**
     *  @dev Initialize the arbitrable curated registry.
     *  @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _governor The trusted governor of this contract.
     *  @param _baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for the subsequent round.
     *  - The multiplier applied to the loser's fee stake for the subsequent round.
     *  @param _relayContract The address of the relay contract to add/remove items directly.
     */
    function initialize(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        address _connectedTCR,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        address _governor,
        uint256[4] memory _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] memory _stakeMultipliers,
        address _relayContract
    ) public {
        require(!initialized, "Already initialized.");

        emit MetaEvidence(0, _registrationMetaEvidence);
        emit MetaEvidence(1, _clearingMetaEvidence);
        emit ConnectedTCRSet(_connectedTCR);

        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        governor = _governor;
        submissionBaseDeposit = _baseDeposits[0];
        removalBaseDeposit = _baseDeposits[1];
        submissionChallengeBaseDeposit = _baseDeposits[2];
        removalChallengeBaseDeposit = _baseDeposits[3];
        challengePeriodDuration = _challengePeriodDuration;
        sharedStakeMultiplier = _stakeMultipliers[0];
        winnerStakeMultiplier = _stakeMultipliers[1];
        loserStakeMultiplier = _stakeMultipliers[2];
        relayContract = _relayContract;

        initialized = true;
    }

    /* External and Public */

    // ************************ //
    // *       Requests       * //
    // ************************ //

    /** @dev Directly add an item to the list bypassing request-challenge. Can only be used by the relay contract.
     *  @param _item The URI to the item data.
     */
    function addItemDirectly(string calldata _item) external onlyRelay {
        bytes32 itemID = keccak256(abi.encodePacked(_item));
        Item storage item = items[itemID];
        require(
            item.status == Status.Absent,
            "Item must be absent to be added."
        );

        if (item.requests.length == 0) emit NewItem(itemID, _item);

        item.status = Status.Registered;

        emit ItemStatusChange(itemID, true);
    }

    /** @dev Directly remove an item from the list bypassing request-challenge. Can only be used by the relay contract.
     *  @param _itemID The ID of the item to remove.
     */
    function removeItemDirectly(bytes32 _itemID) external onlyRelay {
        Item storage item = items[_itemID];
        require(
            item.status == Status.Registered,
            "Item must be registered to be removed."
        );

        item.status = Status.Absent;

        emit ItemStatusChange(_itemID, true);
    }

    /** @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable {
        bytes32 itemID = keccak256(abi.encodePacked(_item));
        Item storage item = items[itemID];
        require(
            item.status == Status.Absent,
            "Item must be absent to be added."
        );

        if (item.requests.length == 0) emit NewItem(itemID, _item);

        requestStatusChange(itemID, submissionBaseDeposit);
    }

    /** @dev Submit a request to remove an item from the list. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  @param _itemID The ID of the item to remove.
     *  @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function removeItem(bytes32 _itemID, string calldata _evidence)
        external
        payable
    {
        Item storage item = items[_itemID];
        require(
            item.status == Status.Registered,
            "Item must be registered to be removed."
        );

        // Emit evidence if it was provided.
        if (bytes(_evidence).length > 0) {
            // Using `length` instead of `length - 1` because a new request will be added on requestStatusChange().
            uint256 requestIndex = item.requests.length;
            uint256 evidenceGroupID = uint256(
                keccak256(abi.encodePacked(_itemID, requestIndex))
            );

            emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
        }

        requestStatusChange(_itemID, removalBaseDeposit);
    }

    /** @dev Challenges the request of the item. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  @param _itemID The ID of the item which request to challenge.
     *  @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function challengeRequest(bytes32 _itemID, string calldata _evidence)
        external
        payable
    {
        Item storage item = items[_itemID];

        require(
            item.status == Status.RegistrationRequested ||
                item.status == Status.ClearingRequested,
            "The item must have a pending request."
        );

        Request storage request = item.requests[item.requests.length - 1];
        require(
            now - request.submissionTime <= challengePeriodDuration,
            "Challenges must occur during the challenge period."
        );
        require(
            !request.disputed,
            "The request should not have already been disputed."
        );

        uint256 arbitrationCost = request.arbitrator.arbitrationCost(
            request.arbitratorExtraData
        );
        uint256 challengerBaseDeposit = item.status ==
            Status.RegistrationRequested
            ? submissionChallengeBaseDeposit
            : removalChallengeBaseDeposit;
        uint256 totalCost = arbitrationCost.addCap(challengerBaseDeposit);
        require(msg.value >= totalCost, "You must fully fund your side.");

        request.parties[uint256(Party.Challenger)] = msg.sender;

        Round storage round = request.rounds[0];
        contribute(
            _itemID,
            round,
            Party.Challenger,
            msg.sender,
            msg.value,
            totalCost
        );
        round.hasPaid[uint256(Party.Challenger)] = true;

        // Raise a dispute.
        request.disputeID = request.arbitrator.createDispute.value(
            arbitrationCost
        )(RULING_OPTIONS, request.arbitratorExtraData);
        arbitratorDisputeIDToItemID[address(request.arbitrator)][
            request.disputeID
        ] = _itemID;
        request.disputed = true;
        request.rounds.length++;
        round.feeRewards = round.feeRewards.subCap(arbitrationCost);

        uint256 evidenceGroupID = uint256(
            keccak256(abi.encodePacked(_itemID, item.requests.length - 1))
        );
        emit Dispute(
            request.arbitrator,
            request.disputeID,
            request.metaEvidenceID,
            evidenceGroupID
        );

        if (bytes(_evidence).length > 0) {
            emit Evidence(
                request.arbitrator,
                evidenceGroupID,
                msg.sender,
                _evidence
            );
        }
    }

    /** @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if both sides are fully funded.
     *  @param _itemID The ID of the item which request to fund.
     *  @param _side The recipient of the contribution.
     */
    function fundAppeal(bytes32 _itemID, Party _side) external payable {
        require(
            _side == Party.Requester || _side == Party.Challenger,
            "Invalid side."
        );
        require(
            items[_itemID].status == Status.RegistrationRequested ||
                items[_itemID].status == Status.ClearingRequested,
            "The item must have a pending request."
        );
        Request storage request = items[_itemID].requests[
            items[_itemID].requests.length - 1
        ];
        require(
            request.disputed,
            "A dispute must have been raised to fund an appeal."
        );
        (uint256 appealPeriodStart, uint256 appealPeriodEnd) = request
            .arbitrator
            .appealPeriod(request.disputeID);
        require(
            now >= appealPeriodStart && now < appealPeriodEnd,
            "Contributions must be made within the appeal period."
        );

        /* solium-disable indentation */
        uint256 multiplier;
        {
            Party winner = Party(
                request.arbitrator.currentRuling(request.disputeID)
            );
            if (winner == Party.None) {
                multiplier = sharedStakeMultiplier;
            } else if (_side == winner) {
                multiplier = winnerStakeMultiplier;
            } else {
                multiplier = loserStakeMultiplier;
                require(
                    block.timestamp < (appealPeriodStart + appealPeriodEnd) / 2,
                    "The loser must contribute during the first half of the appeal period."
                );
            }
        }
        /* solium-enable indentation */

        Round storage round = request.rounds[request.rounds.length - 1];
        uint256 appealCost = request.arbitrator.appealCost(
            request.disputeID,
            request.arbitratorExtraData
        );
        uint256 totalCost = appealCost.addCap(
            (appealCost.mulCap(multiplier)) / MULTIPLIER_DIVISOR
        );
        contribute(_itemID, round, _side, msg.sender, msg.value, totalCost);

        if (round.amountPaid[uint256(_side)] >= totalCost) {
            round.hasPaid[uint256(_side)] = true;
        }

        // Raise appeal if both sides are fully funded.
        if (
            round.hasPaid[uint256(Party.Challenger)] &&
            round.hasPaid[uint256(Party.Requester)]
        ) {
            request.arbitrator.appeal.value(appealCost)(
                request.disputeID,
                request.arbitratorExtraData
            );
            request.rounds.length++;
            round.feeRewards = round.feeRewards.subCap(appealCost);
        }
    }

    /** @dev Reimburses contributions if no disputes were raised. If a dispute was raised, sends the fee stake rewards and reimbursements proportionally to the contributions made to the winner of a dispute.
     *  @param _beneficiary The address that made contributions to a request.
     *  @param _itemID The ID of the item submission to withdraw from.
     *  @param _request The request from which to withdraw from.
     *  @param _round The round from which to withdraw from.
     */
    function withdrawFeesAndRewards(
        address payable _beneficiary,
        bytes32 _itemID,
        uint256 _request,
        uint256 _round
    ) public {
        Item storage item = items[_itemID];
        Request storage request = item.requests[_request];
        Round storage round = request.rounds[_round];
        require(request.resolved, "Request must be resolved.");

        uint256 reward;
        if (_round == request.rounds.length - 1) {
            // Reimburse if not enough fees were raised to appeal the ruling.
            reward =
                round.contributions[_beneficiary][uint256(Party.Requester)] +
                round.contributions[_beneficiary][uint256(Party.Challenger)];
        } else if (request.ruling == Party.None) {
            // Reimburse unspent fees proportionally if there is no winner or loser.
            uint256 rewardRequester = round.amountPaid[
                uint256(Party.Requester)
            ] > 0
                ? (round.contributions[_beneficiary][uint256(Party.Requester)] *
                    round.feeRewards) /
                    (round.amountPaid[uint256(Party.Challenger)] +
                        round.amountPaid[uint256(Party.Requester)])
                : 0;
            uint256 rewardChallenger = round.amountPaid[
                uint256(Party.Challenger)
            ] > 0
                ? (round.contributions[_beneficiary][
                    uint256(Party.Challenger)
                ] * round.feeRewards) /
                    (round.amountPaid[uint256(Party.Challenger)] +
                        round.amountPaid[uint256(Party.Requester)])
                : 0;

            reward = rewardRequester + rewardChallenger;
        } else {
            // Reward the winner.
            reward = round.amountPaid[uint256(request.ruling)] > 0
                ? (round.contributions[_beneficiary][uint256(request.ruling)] *
                    round.feeRewards) /
                    round.amountPaid[uint256(request.ruling)]
                : 0;
        }
        round.contributions[_beneficiary][uint256(Party.Requester)] = 0;
        round.contributions[_beneficiary][uint256(Party.Challenger)] = 0;

        if (reward > 0) _beneficiary.send(reward);

        if (reward > 0)
            emit RewardWithdrawn(_beneficiary, _itemID, _request, _round);
    }

    /** @dev Executes an unchallenged request if the challenge period has passed.
     *  @param _itemID The ID of the item to execute.
     */
    function executeRequest(bytes32 _itemID) external {
        Item storage item = items[_itemID];
        Request storage request = item.requests[item.requests.length - 1];
        require(
            now - request.submissionTime > challengePeriodDuration,
            "Time to challenge the request must pass."
        );
        require(!request.disputed, "The request should not be disputed.");

        if (item.status == Status.RegistrationRequested)
            item.status = Status.Registered;
        else if (item.status == Status.ClearingRequested)
            item.status = Status.Absent;
        else revert("There must be a request.");

        request.resolved = true;
        emit ItemStatusChange(_itemID, false);

        withdrawFeesAndRewards(
            request.parties[uint256(Party.Requester)],
            _itemID,
            item.requests.length - 1,
            0
        ); // Automatically withdraw for the requester.
    }

    /** @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     *  Accounts for the situation where the winner loses a case due to paying less appeal fees than expected.
     *  @param _disputeID ID of the dispute in the arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function rule(uint256 _disputeID, uint256 _ruling) public {
        Party resultRuling = Party(_ruling);
        bytes32 itemID = arbitratorDisputeIDToItemID[msg.sender][_disputeID];
        Item storage item = items[itemID];

        Request storage request = item.requests[item.requests.length - 1];
        Round storage round = request.rounds[request.rounds.length - 1];
        require(_ruling <= RULING_OPTIONS, "Invalid ruling option");
        require(
            address(request.arbitrator) == msg.sender,
            "Only the arbitrator can give a ruling"
        );
        require(!request.resolved, "The request must not be resolved.");

        // The ruling is inverted if the loser paid its fees.
        if (round.hasPaid[uint256(Party.Requester)])
            // If one side paid its fees, the ruling is in its favor. Note that if the other side had also paid, an appeal would have been created.
            resultRuling = Party.Requester;
        else if (round.hasPaid[uint256(Party.Challenger)])
            resultRuling = Party.Challenger;

        emit Ruling(IArbitrator(msg.sender), _disputeID, uint256(resultRuling));
        executeRuling(_disputeID, uint256(resultRuling));
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _itemID The ID of the item which the evidence is related to.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _itemID, string calldata _evidence)
        external
    {
        Item storage item = items[_itemID];
        Request storage request = item.requests[item.requests.length - 1];
        require(!request.resolved, "The dispute must not already be resolved.");

        uint256 evidenceGroupID = uint256(
            keccak256(abi.encodePacked(_itemID, item.requests.length - 1))
        );
        emit Evidence(
            request.arbitrator,
            evidenceGroupID,
            msg.sender,
            _evidence
        );
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Change the duration of the challenge period.
     *  @param _challengePeriodDuration The new duration of the challenge period.
     */
    function changeTimeToChallenge(uint256 _challengePeriodDuration)
        external
        onlyGovernor
    {
        challengePeriodDuration = _challengePeriodDuration;
    }

    /** @dev Change the base amount required as a deposit to submit an item.
     *  @param _submissionBaseDeposit The new base amount of wei required to submit an item.
     */
    function changeSubmissionBaseDeposit(uint256 _submissionBaseDeposit)
        external
        onlyGovernor
    {
        submissionBaseDeposit = _submissionBaseDeposit;
    }

    /** @dev Change the base amount required as a deposit to remove an item.
     *  @param _removalBaseDeposit The new base amount of wei required to remove an item.
     */
    function changeRemovalBaseDeposit(uint256 _removalBaseDeposit)
        external
        onlyGovernor
    {
        removalBaseDeposit = _removalBaseDeposit;
    }

    /** @dev Change the base amount required as a deposit to challenge a submission.
     *  @param _submissionChallengeBaseDeposit The new base amount of wei required to challenge a submission.
     */
    function changeSubmissionChallengeBaseDeposit(
        uint256 _submissionChallengeBaseDeposit
    ) external onlyGovernor {
        submissionChallengeBaseDeposit = _submissionChallengeBaseDeposit;
    }

    /** @dev Change the base amount required as a deposit to challenge a removal request.
     *  @param _removalChallengeBaseDeposit The new base amount of wei required to challenge a removal request.
     */
    function changeRemovalChallengeBaseDeposit(
        uint256 _removalChallengeBaseDeposit
    ) external onlyGovernor {
        removalChallengeBaseDeposit = _removalChallengeBaseDeposit;
    }

    /** @dev Change the governor of the curated registry.
     *  @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by parties when there is no winner or loser.
     *  @param _sharedStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeSharedStakeMultiplier(uint256 _sharedStakeMultiplier)
        external
        onlyGovernor
    {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by the winner of the previous round.
     *  @param _winnerStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeWinnerStakeMultiplier(uint256 _winnerStakeMultiplier)
        external
        onlyGovernor
    {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by the party that lost the previous round.
     *  @param _loserStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeLoserStakeMultiplier(uint256 _loserStakeMultiplier)
        external
        onlyGovernor
    {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /** @dev Change the arbitrator to be used for disputes that may be raised. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitrator The new trusted arbitrator to be used in disputes.
     *  @param _arbitratorExtraData The extra data used by the new arbitrator.
     */
    function changeArbitrator(
        IArbitrator _arbitrator,
        bytes calldata _arbitratorExtraData
    ) external onlyGovernor {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Change the address of connectedTCR, the Generalized TCR instance that stores addresses of TCRs related to this one.
     *  @param _connectedTCR The address of the connectedTCR contract to use.
     */
    function changeConnectedTCR(address _connectedTCR) external onlyGovernor {
        emit ConnectedTCRSet(_connectedTCR);
    }

    /** @dev Update the meta evidence used for disputes.
     *  @param _registrationMetaEvidence The meta evidence to be used for future registration request disputes.
     *  @param _clearingMetaEvidence The meta evidence to be used for future clearing request disputes.
     */
    function changeMetaEvidence(
        string calldata _registrationMetaEvidence,
        string calldata _clearingMetaEvidence
    ) external onlyGovernor {
        metaEvidenceUpdates++;
        emit MetaEvidence(2 * metaEvidenceUpdates, _registrationMetaEvidence);
        emit MetaEvidence(2 * metaEvidenceUpdates + 1, _clearingMetaEvidence);
    }

    /** @dev Change the address of the relay contract.
     *  @param _relayContract The new address of the relay contract.
     */
    function changeRelayContract(address _relayContract) external onlyGovernor {
        relayContract = _relayContract;
    }

    /* Internal */

    /** @dev Submit a request to change item's status. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  @param _itemID The keccak256 hash of the item data.
     *  @param _baseDeposit The base deposit for the request.
     */
    function requestStatusChange(bytes32 _itemID, uint256 _baseDeposit)
        internal
    {
        Item storage item = items[_itemID];
        Request storage request = item.requests[item.requests.length++];
        uint256 arbitrationCost = arbitrator.arbitrationCost(
            arbitratorExtraData
        );
        uint256 totalCost = arbitrationCost.addCap(_baseDeposit);
        require(msg.value >= totalCost, "You must fully fund your side.");

        if (item.status == Status.Absent) {
            item.status = Status.RegistrationRequested;
            request.metaEvidenceID = 2 * metaEvidenceUpdates;
        } else if (item.status == Status.Registered) {
            item.status = Status.ClearingRequested;
            request.metaEvidenceID = 2 * metaEvidenceUpdates + 1;
        }

        request.parties[uint256(Party.Requester)] = msg.sender;
        request.submissionTime = now;
        request.arbitrator = arbitrator;
        request.arbitratorExtraData = arbitratorExtraData;

        Round storage round = request.rounds[request.rounds.length++];
        uint256 evidenceGroupID = uint256(
            keccak256(abi.encodePacked(_itemID, item.requests.length - 1))
        );
        emit RequestSubmitted(_itemID, evidenceGroupID);

        contribute(
            _itemID,
            round,
            Party.Requester,
            msg.sender,
            msg.value,
            totalCost
        );
        round.hasPaid[uint256(Party.Requester)] = true;
    }

    /** @dev Returns the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return taken The amount of ETH taken.
     *  @return remainder The amount of ETH left from the contribution.
     */
    function calculateContribution(uint256 _available, uint256 _requiredAmount)
        internal
        pure
        returns (uint256 taken, uint256 remainder)
    {
        if (_requiredAmount > _available) return (_available, 0);
        // Take whatever is available, return 0 as leftover ETH.
        else return (_requiredAmount, _available - _requiredAmount);
    }

    /** @dev Make a fee contribution.
     *  @param _itemID The item receiving the contribution.
     *  @param _round The round to contribute.
     *  @param _side The side for which to contribute.
     *  @param _contributor The contributor.
     *  @param _amount The amount contributed.
     *  @param _totalRequired The total amount required for this side.
     *  @return The amount of appeal fees contributed.
     */
    function contribute(
        bytes32 _itemID,
        Round storage _round,
        Party _side,
        address payable _contributor,
        uint256 _amount,
        uint256 _totalRequired
    ) internal returns (uint256) {
        // Take up to the amount necessary to fund the current round at the current costs.
        uint256 contribution; // Amount contributed.
        uint256 remainingETH; // Remaining ETH to send back.
        (contribution, remainingETH) = calculateContribution(
            _amount,
            _totalRequired.subCap(_round.amountPaid[uint256(_side)])
        );
        _round.contributions[_contributor][uint256(_side)] += contribution;
        _round.amountPaid[uint256(_side)] += contribution;
        _round.feeRewards += contribution;

        // Reimburse leftover ETH.
        if (remainingETH > 0) _contributor.send(remainingETH); // Deliberate use of send in order to not block the contract in case of reverting fallback.

        if (contribution > 0)
            emit Contribution(_itemID, msg.sender, contribution, _side);

        return contribution;
    }

    /** @dev Execute the ruling of a dispute.
     *  @param _disputeID ID of the dispute in the arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function executeRuling(uint256 _disputeID, uint256 _ruling) internal {
        bytes32 itemID = arbitratorDisputeIDToItemID[msg.sender][_disputeID];
        Item storage item = items[itemID];
        Request storage request = item.requests[item.requests.length - 1];

        Party winner = Party(_ruling);

        if (winner == Party.Requester) {
            // Execute Request.
            if (item.status == Status.RegistrationRequested)
                item.status = Status.Registered;
            else if (item.status == Status.ClearingRequested)
                item.status = Status.Absent;
        } else {
            if (item.status == Status.RegistrationRequested)
                item.status = Status.Absent;
            else if (item.status == Status.ClearingRequested)
                item.status = Status.Registered;
        }

        request.resolved = true;
        request.ruling = Party(_ruling);

        emit ItemStatusChange(itemID, false);

        // Automatically withdraw first deposits and reimbursements (first round only).
        if (winner == Party.None) {
            withdrawFeesAndRewards(
                request.parties[uint256(Party.Requester)],
                itemID,
                item.requests.length - 1,
                0
            );
            withdrawFeesAndRewards(
                request.parties[uint256(Party.Challenger)],
                itemID,
                item.requests.length - 1,
                0
            );
        } else {
            withdrawFeesAndRewards(
                request.parties[uint256(winner)],
                itemID,
                item.requests.length - 1,
                0
            );
        }
    }

    // ************************ //
    // *       Getters        * //
    // ************************ //

    /** @dev Gets the contributions made by a party for a given round of a request.
     *  @param _itemID The ID of the item.
     *  @param _request The request to query.
     *  @param _round The round to query.
     *  @param _contributor The address of the contributor.
     *  @return contributions The contributions.
     */
    function getContributions(
        bytes32 _itemID,
        uint256 _request,
        uint256 _round,
        address _contributor
    ) external view returns (uint256[3] memory contributions) {
        Item storage item = items[_itemID];
        Request storage request = item.requests[_request];
        Round storage round = request.rounds[_round];
        contributions = round.contributions[_contributor];
    }

    /** @dev Returns item's information. Includes length of requests array.
     *  @param _itemID The ID of the queried item.
     *  @return status The current status of the item.
     *  @return numberOfRequests Length of list of status change requests made for the item.
     */
    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (Status status, uint256 numberOfRequests)
    {
        Item storage item = items[_itemID];
        return (item.status, item.requests.length);
    }

    /** @dev Gets information on a request made for the item.
     *  @param _itemID The ID of the queried item.
     *  @param _request The request to be queried.
     *  @return disputed True if a dispute was raised.
     *  @return disputeID ID of the dispute, if any..
     *  @return submissionTime Time when the request was made.
     *  @return resolved True if the request was executed and/or any raised disputes were resolved.
     *  @return parties Address of requester and challenger, if any.
     *  @return numberOfRounds Number of rounds of dispute.
     *  @return ruling The final ruling given, if any.
     *  @return arbitrator The arbitrator trusted to solve disputes for this request.
     *  @return arbitratorExtraData The extra data for the trusted arbitrator of this request.
     *  @return metaEvidenceID The meta evidence to be used in a dispute for this case.
     */
    function getRequestInfo(bytes32 _itemID, uint256 _request)
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            IArbitrator requestArbitrator,
            bytes memory requestArbitratorExtraData,
            uint256 metaEvidenceID
        )
    {
        Request storage request = items[_itemID].requests[_request];
        return (
            request.disputed,
            request.disputeID,
            request.submissionTime,
            request.resolved,
            request.parties,
            request.rounds.length,
            request.ruling,
            request.arbitrator,
            request.arbitratorExtraData,
            request.metaEvidenceID
        );
    }

    /** @dev Gets the information of a round of a request.
     *  @param _itemID The ID of the queried item.
     *  @param _request The request to be queried.
     *  @param _round The round to be queried.
     *  @return appealed Whether appealed or not.
     *  @return amountPaid Tracks the sum paid for each Party in this round.
     *  @return hasPaid True if the Party has fully paid its fee in this round.
     *  @return feeRewards Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
     */
    function getRoundInfo(
        bytes32 _itemID,
        uint256 _request,
        uint256 _round
    )
        external
        view
        returns (
            bool appealed,
            uint256[3] memory amountPaid,
            bool[3] memory hasPaid,
            uint256 feeRewards
        )
    {
        Item storage item = items[_itemID];
        Request storage request = item.requests[_request];
        Round storage round = request.rounds[_round];
        return (
            (_round + 1) < request.rounds.length - 1,
            round.amountPaid,
            round.hasPaid,
            round.feeRewards
        );
    }
}

/* solium-disable max-len */
/* solium-disable security/no-block-members */
/* solium-disable security/no-send */ // It is the user responsibility to accept ETH.

/**
 *  @title LightGeneralizedTCRView
 *  A view contract to fetch, batch, parse and return GTCR contract data efficiently.
 *  This contract includes functions that can halt execution due to out-of-gas exceptions. Because of this it should never be relied upon by other contracts.
 */
contract LightGeneralizedTCRView {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;
    using BytesLib for bytes;

    struct QueryResult {
        bytes32 ID;
        LightGeneralizedTCR.Status status;
        bool disputed;
        bool resolved;
        uint disputeID;
        uint appealCost;
        bool appealed;
        uint appealStart;
        uint appealEnd;
        LightGeneralizedTCR.Party ruling;
        address requester;
        address challenger;
        address arbitrator;
        bytes arbitratorExtraData;
        LightGeneralizedTCR.Party currentRuling;
        bool[3] hasPaid;
        uint feeRewards;
        uint submissionTime;
        uint[3] amountPaid;
        IArbitrator.DisputeStatus disputeStatus;
        uint numberOfRequests;
    }

    struct ArbitrableData {
        address governor;
        address arbitrator;
        bytes arbitratorExtraData;
        uint submissionBaseDeposit;
        uint removalBaseDeposit;
        uint submissionChallengeBaseDeposit;
        uint removalChallengeBaseDeposit;
        uint challengePeriodDuration;
        uint metaEvidenceUpdates;
        uint winnerStakeMultiplier;
        uint loserStakeMultiplier;
        uint sharedStakeMultiplier;
        uint MULTIPLIER_DIVISOR;
        uint arbitrationCost;
    }

    /** @dev Fetch arbitrable TCR data in a single call.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @return The latest data on an arbitrable TCR contract.
     */
    function fetchArbitrable(address _address) external view returns (ArbitrableData memory result) {
        LightGeneralizedTCR tcr = LightGeneralizedTCR(_address);
        result.governor = tcr.governor();
        result.arbitrator = address(tcr.arbitrator());
        result.arbitratorExtraData = tcr.arbitratorExtraData();
        result.submissionBaseDeposit = tcr.submissionBaseDeposit();
        result.removalBaseDeposit = tcr.removalBaseDeposit();
        result.submissionChallengeBaseDeposit = tcr.submissionChallengeBaseDeposit();
        result.removalChallengeBaseDeposit = tcr.removalChallengeBaseDeposit();
        result.challengePeriodDuration = tcr.challengePeriodDuration();
        result.metaEvidenceUpdates = tcr.metaEvidenceUpdates();
        result.winnerStakeMultiplier = tcr.winnerStakeMultiplier();
        result.loserStakeMultiplier = tcr.loserStakeMultiplier();
        result.sharedStakeMultiplier = tcr.sharedStakeMultiplier();
        result.MULTIPLIER_DIVISOR = tcr.MULTIPLIER_DIVISOR();
        result.arbitrationCost = IArbitrator(result.arbitrator).arbitrationCost(result.arbitratorExtraData);
    }

    /** @dev Fetch the latest data on an item in a single call.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The item data.
     */
    function getItem(address _address, bytes32 _itemID) public view returns (QueryResult memory result) {
        RoundData memory round = getLatestRoundRequestData(_address, _itemID);
        result = QueryResult({
            ID: _itemID,
            status: round.request.item.status,
            disputed: round.request.disputed,
            resolved: round.request.resolved,
            disputeID: round.request.disputeID,
            appealCost: 0,
            appealed: round.appealed,
            appealStart: 0,
            appealEnd: 0,
            ruling: round.request.ruling,
            requester: round.request.parties[uint(LightGeneralizedTCR.Party.Requester)],
            challenger: round.request.parties[uint(LightGeneralizedTCR.Party.Challenger)],
            arbitrator: address(round.request.arbitrator),
            arbitratorExtraData: round.request.arbitratorExtraData,
            currentRuling: LightGeneralizedTCR.Party.None,
            hasPaid: round.hasPaid,
            feeRewards: round.feeRewards,
            submissionTime: round.request.submissionTime,
            amountPaid: round.amountPaid,
            disputeStatus: IArbitrator.DisputeStatus.Waiting,
            numberOfRequests: round.request.item.numberOfRequests
        });
        if (round.request.disputed && round.request.arbitrator.disputeStatus(result.disputeID) == IArbitrator.DisputeStatus.Appealable) {
            result.currentRuling = LightGeneralizedTCR.Party(round.request.arbitrator.currentRuling(result.disputeID));
            result.disputeStatus = round.request.arbitrator.disputeStatus(result.disputeID);
            (result.appealStart, result.appealEnd) = round.request.arbitrator.appealPeriod(result.disputeID);
            result.appealCost = round.request.arbitrator.appealCost(result.disputeID, result.arbitratorExtraData);
        }
    }

    struct ItemRequest {
        bool disputed;
        uint disputeID;
        uint submissionTime;
        bool resolved;
        address requester;
        address challenger;
        address arbitrator;
        bytes arbitratorExtraData;
        uint metaEvidenceID;
    }

    /** @dev Fetch all requests for an item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The items requests.
     */
    function getItemRequests(address _address, bytes32 _itemID) external view returns (ItemRequest[] memory requests) {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        ItemData memory itemData = getItemData(_address, _itemID);
        requests = new ItemRequest[](itemData.numberOfRequests);
        for (uint i = 0; i < itemData.numberOfRequests; i++) {
            (
                bool disputed,
                uint disputeID,
                uint submissionTime,
                bool resolved,
                address payable[3] memory parties,
                ,
                ,
                IArbitrator arbitrator,
                bytes memory arbitratorExtraData,
                uint metaEvidenceID
            ) = gtcr.getRequestInfo(_itemID, i);

            // Sort requests by newest first.
            requests[itemData.numberOfRequests - i - 1] = ItemRequest({
                disputed: disputed,
                disputeID: disputeID,
                submissionTime: submissionTime,
                resolved: resolved,
                requester: parties[uint(LightGeneralizedTCR.Party.Requester)],
                challenger: parties[uint(LightGeneralizedTCR.Party.Challenger)],
                arbitrator: address(arbitrator),
                arbitratorExtraData: arbitratorExtraData,
                metaEvidenceID: metaEvidenceID
            });
        }
    }

    /** @dev Return the withdrawable rewards for a contributor.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @param _contributor The address of the contributor.
     *  @return The amount withdrawable per round per request.
     */
    function availableRewards(address _address, bytes32 _itemID, address _contributor) external view returns (uint rewards) {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);

        // Using arrays to avoid stack limit.
        uint[2] memory requestRoundCount = [uint(0), uint(0)];
        uint[2] memory indexes = [uint(0), uint(0)]; // Request index and round index.

        (,requestRoundCount[0]) = gtcr.getItemInfo(_itemID);
        for (indexes[0]; indexes[0] < requestRoundCount[0]; indexes[0]++) {
            LightGeneralizedTCR.Party ruling;
            bool resolved;
            (,,, resolved,, requestRoundCount[1], ruling,,,) = gtcr.getRequestInfo(_itemID, indexes[0]);
            if (!resolved) continue;
            for (indexes[1]; indexes[1] < requestRoundCount[1]; indexes[1]++) {
                (
                    ,
                    uint[3] memory amountPaid,
                    bool[3] memory hasPaid,
                    uint feeRewards
                ) = gtcr.getRoundInfo(_itemID, indexes[0], indexes[1]);

                uint[3] memory roundContributions = gtcr.getContributions(_itemID, indexes[0], indexes[1], _contributor);
                if (!hasPaid[uint(LightGeneralizedTCR.Party.Requester)] || !hasPaid[uint(LightGeneralizedTCR.Party.Challenger)]) {
                    // Amount reimbursable if not enough fees were raised to appeal the ruling.
                    rewards += roundContributions[uint(LightGeneralizedTCR.Party.Requester)] + roundContributions[uint(LightGeneralizedTCR.Party.Challenger)];
                } else if (ruling == LightGeneralizedTCR.Party.None) {
                    // Reimbursable fees proportional if there aren't a winner and loser.
                    rewards += amountPaid[uint(LightGeneralizedTCR.Party.Requester)] > 0
                        ? (roundContributions[uint(LightGeneralizedTCR.Party.Requester)] * feeRewards) / (amountPaid[uint(LightGeneralizedTCR.Party.Challenger)] + amountPaid[uint(LightGeneralizedTCR.Party.Requester)])
                        : 0;
                    rewards += amountPaid[uint(LightGeneralizedTCR.Party.Challenger)] > 0
                        ? (roundContributions[uint(LightGeneralizedTCR.Party.Challenger)] * feeRewards) / (amountPaid[uint(LightGeneralizedTCR.Party.Challenger)] + amountPaid[uint(LightGeneralizedTCR.Party.Requester)])
                        : 0;
                } else {
                    // Contributors to the winner take the rewards.
                    rewards += amountPaid[uint(ruling)] > 0
                        ? (roundContributions[uint(ruling)] * feeRewards) / amountPaid[uint(ruling)]
                        : 0;
                }
            }
            indexes[1] = 0;
        }
    }

    // Functions and structs below used mainly to avoid stack limit.
    struct ItemData {
        LightGeneralizedTCR.Status status;
        uint numberOfRequests;
    }

    struct RequestData {
        ItemData item;
        bool disputed;
        uint disputeID;
        uint submissionTime;
        bool resolved;
        address payable[3] parties;
        uint numberOfRounds;
        LightGeneralizedTCR.Party ruling;
        IArbitrator arbitrator;
        bytes arbitratorExtraData;
    }

    struct RoundData {
        RequestData request;
        bool appealed;
        uint[3] amountPaid;
        bool[3] hasPaid;
        uint feeRewards;
    }

    /** @dev Fetch data of the an item and return a struct.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getItemData(address _address, bytes32 _itemID) public view returns(ItemData memory item) {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        (
            LightGeneralizedTCR.Status status,
            uint numberOfRequests
        ) = gtcr.getItemInfo(_itemID);
        item = ItemData(status, numberOfRequests);
    }

    /** @dev Fetch the latest request of item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getLatestRequestData(address _address, bytes32 _itemID) public view returns (RequestData memory request)  {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        ItemData memory item = getItemData(_address, _itemID);
        (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint numberOfRounds,
            LightGeneralizedTCR.Party ruling,
            IArbitrator arbitrator,
            bytes memory arbitratorExtraData,
        ) = gtcr.getRequestInfo(_itemID, item.numberOfRequests - 1);
        request = RequestData(
            item,
            disputed,
            disputeID,
            submissionTime,
            resolved,
            parties,
            numberOfRounds,
            ruling,
            arbitrator,
            arbitratorExtraData
        );
    }

    /** @dev Fetch the latest round of the latest request of an item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getLatestRoundRequestData(address _address, bytes32 _itemID) public view returns (RoundData memory round)  {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        RequestData memory request = getLatestRequestData(_address, _itemID);
        (
            bool appealed,
            uint[3] memory amountPaid,
            bool[3] memory hasPaid,
            uint feeRewards
        ) = gtcr.getRoundInfo(_itemID, request.item.numberOfRequests - 1, request.numberOfRounds - 1);
        round = RoundData(
            request,
            appealed,
            amountPaid,
            hasPaid,
            feeRewards
        );
    }
}



/* solium-disable max-len */

/**
 *  @title LightGTCRFactory
 *  This contract acts as a registry for LightGeneralizedTCR instances.
 */
contract LightGTCRFactory {
    /**
     *  @dev Emitted when a new Generalized TCR contract is deployed using this factory.
     *  @param _address The address of the newly deployed Generalized TCR.
     */
    event NewGTCR(LightGeneralizedTCR indexed _address);

    LightGeneralizedTCR[] public instances;
    address public GTCR;

    /**
     *  @dev Constructor.
     *  @param _GTCR Address of the generalized TCR contract that is going to be used for each new deployment.
     */
    constructor(address _GTCR) public {
        GTCR = _GTCR;
    }

    /**
     *  @dev Deploy the arbitrable curated registry.
     *  @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _governor The trusted governor of this contract.
     *  @param _baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     *  @param _relayContract The address of the relay contract to add/remove items directly.
     */
    function deploy(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        address _connectedTCR,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        address _governor,
        uint256[4] memory _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] memory _stakeMultipliers,
        address _relayContract
    ) public {
        LightGeneralizedTCR instance = clone(GTCR);
        instance.initialize(
            _arbitrator,
            _arbitratorExtraData,
            _connectedTCR,
            _registrationMetaEvidence,
            _clearingMetaEvidence,
            _governor,
            _baseDeposits,
            _challengePeriodDuration,
            _stakeMultipliers,
            _relayContract
        );
        instances.push(instance);
        emit NewGTCR(instance);
    }

    /**
     * @notice Adaptation of @openzeppelin/contracts/proxy/Clones.sol.
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `GTCR`.
     * @param _implementation Address of the contract to clone.
     * This function uses the create opcode, which should never revert.
     */
    function clone(address _implementation)
        internal
        returns (LightGeneralizedTCR instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != LightGeneralizedTCR(0), "ERC1167: create failed");
    }

    /**
     * @return The number of deployed tcrs using this factory.
     */
    function count() external view returns (uint256) {
        return instances.length;
    }
}