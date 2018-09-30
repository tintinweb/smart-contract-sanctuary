pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e084819685a0818b8f8d8281ce838f8d">[email&#160;protected]</a>
// released under Apache 2.0 licence
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}
library RLP {

 uint constant DATA_SHORT_START = 0x80;
 uint constant DATA_LONG_START = 0xB8;
 uint constant LIST_SHORT_START = 0xC0;
 uint constant LIST_LONG_START = 0xF8;

 uint constant DATA_LONG_OFFSET = 0xB7;
 uint constant LIST_LONG_OFFSET = 0xF7;


 struct RLPItem {
     uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
     uint _unsafe_length;    // Number of bytes. This is the full length of the string.
 }

 struct Iterator {
     RLPItem _unsafe_item;   // Item that&#39;s being iterated over.
     uint _unsafe_nextPtr;   // Position of the next item in the list.
 }

 /* Iterator */

 function next(Iterator memory self) internal constant returns (RLPItem memory subItem) {
     if(hasNext(self)) {
         var ptr = self._unsafe_nextPtr;
         var itemLength = _itemLength(ptr);
         subItem._unsafe_memPtr = ptr;
         subItem._unsafe_length = itemLength;
         self._unsafe_nextPtr = ptr + itemLength;
     }
     else
         revert();
 }

 function next(Iterator memory self, bool strict) internal constant returns (RLPItem memory subItem) {
     subItem = next(self);
     if(strict && !_validate(subItem))
         revert();
     return;
 }

 function hasNext(Iterator memory self) internal constant returns (bool) {
     var item = self._unsafe_item;
     return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
 }

 /* RLPItem */

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @return An RLPItem
 function toRLPItem(bytes memory self) internal constant returns (RLPItem memory) {
     uint len = self.length;
     if (len == 0) {
         return RLPItem(0, 0);
     }
     uint memPtr;
     assembly {
         memPtr := add(self, 0x20)
     }
     return RLPItem(memPtr, len);
 }

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @param strict Will revert if the data is not RLP encoded.
 /// @return An RLPItem
 function toRLPItem(bytes memory self, bool strict) internal constant returns (RLPItem memory) {
     var item = toRLPItem(self);
     if(strict) {
         uint len = self.length;
         if(_payloadOffset(item) > len)
             revert();
         if(_itemLength(item._unsafe_memPtr) != len)
             revert();
         if(!_validate(item))
             revert();
     }
     return item;
 }

 /// @dev Check if the RLP item is null.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isNull(RLPItem memory self) internal pure returns (bool ret) {
     return self._unsafe_length == 0;
 }

 /// @dev Check if the RLP item is a list.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is a list.
 function isList(RLPItem memory self) internal pure returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
     }
 }

 /// @dev Check if the RLP item is data.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is data.
 function isData(RLPItem memory self) internal pure returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := lt(byte(0, mload(memPtr)), 0xC0)
     }
 }

 /// @dev Check if the RLP item is empty (string or list).
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
     if (isNull(self)) {
         return false;
     }
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
 }

 /// @dev Get the number of items in an RLP encoded list.
 /// @param self The RLP item.
 /// @return The number of items.
 function items(RLPItem memory self) internal constant returns (uint) {
     if (!isList(self))
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     uint pos = memPtr + _payloadOffset(self);
     uint last = memPtr + self._unsafe_length - 1;
     uint itms;
     while (pos <= last) {
         pos += _itemLength(pos);
         itms++;
     }
     return itms;
 }

 /// @dev Create an iterator.
 /// @param self The RLP item.
 /// @return An &#39;Iterator&#39; over the item.
 function iterator(RLPItem memory self) internal constant returns (Iterator memory it) {
     if (!isList(self))
         revert();
     uint ptr = self._unsafe_memPtr + _payloadOffset(self);
     it._unsafe_item = self;
     it._unsafe_nextPtr = ptr;
 }

 /// @dev Return the RLP encoded bytes.
 /// @param self The RLPItem.
 /// @return The bytes.
 function toBytes(RLPItem memory self) internal constant returns (bytes memory bts) {
     var len = self._unsafe_length;
     if (len == 0)
         return;
     bts = new bytes(len);
     _copyToBytes(self._unsafe_memPtr, bts, len);
 }

 /// @dev Decode an RLPItem into bytes. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toData(RLPItem memory self) internal constant returns (bytes memory bts) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
 }

 /// @dev Get the list of sub-items from an RLP encoded list.
 /// Warning: This is inefficient, as it requires that the list is read twice.
 /// @param self The RLP item.
 /// @return Array of RLPItems.
 function toList(RLPItem memory self) internal constant returns (RLPItem[] memory list) {
     if(!isList(self))
         revert();
     var numItems = items(self);
     list = new RLPItem[](numItems);
     var it = iterator(self);
     uint idx;
     while(hasNext(it)) {
         list[idx] = next(it);
         idx++;
     }
 }

 /// @dev Decode an RLPItem into an ascii string. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAscii(RLPItem memory self) internal constant returns (string memory str) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     bytes memory bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
     str = string(bts);
 }

 /// @dev Decode an RLPItem into a uint. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toUint(RLPItem memory self) internal constant returns (uint data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len > 32 || len == 0)
         revert();
     assembly {
         data := div(mload(rStartPos), exp(256, sub(32, len)))
     }
 }

 /// @dev Decode an RLPItem into a boolean. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBool(RLPItem memory self) internal constant returns (bool data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         revert();
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     if (temp > 1)
         revert();
     return temp == 1 ? true : false;
 }

 /// @dev Decode an RLPItem into a byte. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toByte(RLPItem memory self) internal constant returns (byte data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         revert();
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     return byte(temp);
 }

 /// @dev Decode an RLPItem into an int. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toInt(RLPItem memory self) internal constant returns (int data) {
     return int(toUint(self));
 }

 /// @dev Decode an RLPItem into a bytes32. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBytes32(RLPItem memory self) internal constant returns (bytes32 data) {
     return bytes32(toUint(self));
 }

 /// @dev Decode an RLPItem into an address. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAddress(RLPItem memory self) internal constant returns (address data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 20)
         revert();
     assembly {
         data := div(mload(rStartPos), exp(256, 12))
     }
 }

 // Get the payload offset.
 function _payloadOffset(RLPItem memory self) private constant returns (uint) {
     if(self._unsafe_length == 0)
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if(b0 < DATA_SHORT_START)
         return 0;
     if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
         return 1;
     if(b0 < LIST_SHORT_START)
         return b0 - DATA_LONG_OFFSET + 1;
     return b0 - LIST_LONG_OFFSET + 1;
 }

 // Get the full length of an RLP item.
 function _itemLength(uint memPtr) private constant returns (uint len) {
     uint b0;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if (b0 < DATA_SHORT_START)
         len = 1;
     else if (b0 < DATA_LONG_START)
         len = b0 - DATA_SHORT_START + 1;
     else if (b0 < LIST_SHORT_START) {
         assembly {
             let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
     else if (b0 < LIST_LONG_START)
         len = b0 - LIST_SHORT_START + 1;
     else {
         assembly {
             let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
 }

 // Get start position and length of the data.
 function _decode(RLPItem memory self) private constant returns (uint memPtr, uint len) {
     if(!isData(self))
         revert();
     uint b0;
     uint start = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(start))
     }
     if (b0 < DATA_SHORT_START) {
         memPtr = start;
         len = 1;
         return;
     }
     if (b0 < DATA_LONG_START) {
         len = self._unsafe_length - 1;
         memPtr = start + 1;
     } else {
         uint bLen;
         assembly {
             bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
         }
         len = self._unsafe_length - 1 - bLen;
         memPtr = start + bLen + 1;
     }
     return;
 }

 // Assumes that enough memory has been allocated to store in target.
 function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen) private constant {
     // Exploiting the fact that &#39;tgt&#39; was the last thing to be allocated,
     // we can write entire words, and just overwrite any excess.
     assembly {
         {
                 let i := 0 // Start at arr + 0x20
                 let words := div(add(btsLen, 31), 32)
                 let rOffset := btsPtr
                 let wOffset := add(tgt, 0x20)
             tag_loop:
                 jumpi(end, eq(i, words))
                 {
                     let offset := mul(i, 0x20)
                     mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                     i := add(i, 1)
                 }
                 jump(tag_loop)
             end:
                 mstore(add(tgt, add(0x20, mload(tgt))), 0)
         }
     }
 }

     // Check that an RLP item is valid.
     function _validate(RLPItem memory self) private constant returns (bool ret) {
         // Check that RLP is well-formed.
         uint b0;
         uint b1;
         uint memPtr = self._unsafe_memPtr;
         assembly {
             b0 := byte(0, mload(memPtr))
             b1 := byte(1, mload(memPtr))
         }
         if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
             return false;
         return true;
     }
}

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
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
            // of the array. (We don&#39;t need to use the offset into the slot
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
            // if length < 32 bytes so let&#39;s prepare for that
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

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
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
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
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
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there&#39;s
                //  no said feature for inline assembly loops
                // cb = 1 - don&#39;t breaker
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

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let&#39;s prepare for that
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
                        // cb is a circuit breaker in the for loop since there&#39;s
                        //  no said feature for inline assembly loops
                        // cb = 1 - don&#39;t breaker
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
contract DepositContract {
  using SafeMath for uint256;
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;
  using BytesLib for bytes;

  string contractState = "preStaked";
  address tokenContract;
  address custodian;
  address custodianForeign;
  uint256 stakedAmount;
  uint256 depositCap;
  uint256 depositedAmount;
  mapping (uint256 => uint256) public tokenIdToAmount;
  mapping (uint256 => address) public tokenIdToMinter;

  struct Transaction {
    uint nonce;
    uint gasPrice;
    uint gasLimit;
    address to;
    uint value;
    bytes data;
    uint8 v;
    bytes32 r;
    bytes32 s;
    address from;
  }

  function () payable {}

  constructor (address _custodian) {
    custodian = _custodian;
  }

  modifier onlyCustodian() {
    require(custodian == msg.sender);
    _;
  }

  modifier statePreStaked () {
    require(keccak256(contractState) == keccak256("preStaked"));
    _;
  }

  modifier stateStaked () {
    require(keccak256(contractState) == keccak256("staked"));
    _;
  }

  event Deposit(address indexed depositer,
                uint256 amount,
                uint256 tokenId,
                address minter);
  event ChallengeInitiated(address indexed challenger,
                           address indexed depositedTo,
                           uint256 tokenId);
  event Challenge(address indexed rechallenger,
                  address indexed depositedTo,
                  uint256 tokenId,
                  uint256 finalChallengeNonce);
  event ChallengeResolved(uint256 tokenId);
  event Withdrawal(address indexed withdrawer,
                   uint256 indexed tokenId,
                   uint256 stakedAmount);

  bytes4 mintSignature = 0x94bf804d;
  bytes4 withdrawSignature = 0x2e1a7d4d;
  bytes4 transferFromSignature = 0xfe99049a;
  bytes4 custodianApproveSignature = 0x6e3c045e;
  uint256 gasPerChallenge = 206250;

  function setTokenContract(address _tokenContract) onlyCustodian statePreStaked
  public {
    tokenContract = _tokenContract;
  }


  function setCustodianForeign(address _custodianForeign) onlyCustodian
  statePreStaked public {
    custodianForeign = _custodianForeign;
  }

  function finalizeStake() onlyCustodian statePreStaked public {
    stakedAmount = address(this).balance;
    depositCap = address(this).balance;
    depositedAmount = 0;
    contractState = "staked";
  }

  function deposit(uint256 _tokenId, address _minter) payable public {
    depositedAmount += msg.value;
    tokenIdToAmount[_tokenId] = tokenIdToAmount[_tokenId].add(msg.value);
    tokenIdToMinter[_tokenId] = _minter;
    emit Deposit(msg.sender, msg.value, _tokenId, _minter);
  }

  // tokenIdToTimestamp
  mapping (uint256 => uint256) challengeTime;
  // tokenIdToAddress
  mapping (uint256 => address) challengeAddressClaim;
  // tokenIdToAddress
  mapping (uint256 => address) challengeRecipient;
  //mintToStake
  mapping (uint256 => uint256) challengeStake;
  //mintToEndNonce/depth
  mapping (uint256 => uint256) challengeEndNonce;
  //tokenIdToNonce
  mapping (uint256 => uint256) challengeNonce;
  //tokenIdToChallengerAddress
  mapping (uint256 => address) challenger;

  //For Debugging purposes
  event Test(bytes tx1, bytes tx2, bytes tx3);
  event Trace(bytes out);
  event TraceAddress(address out);
  event Trace32(bytes32 out);
  event TraceUint256(uint256 out);
  /*
  /**
   * @dev Initiates a withdrawal process. Starts the challenge period
   * Requires the msg sender to stake a payment (payable function)
   // TODO: check amount to stake, discern challenge time
   * @param _to address to send withdrawal
   * @param _tokenId uint256 Id of token on TokenContract
   * @param _rawTxBundle bytes32[] bundle that takes in concatenation of
            bytes _withdrawTx, bytes _lastTx, bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle, used for
            efficiency purposes
   * @param _txMsgHashes msghashes of transactions in bundle
   + @param _declaredNonce depth of chain of custody from token contract.
            IMPORTANT TO BE HONEST
  */
  function withdraw(address _to,
    uint256 _tokenId,
    bytes32[] _rawTxBundle,
    uint256[] _txLengths,
    bytes32[] _txMsgHashes,
    uint256 _declaredNonce) public payable  {
    // TODO:  discern challenge time,
    //check amount to stake
    require(msg.value >= gasPerChallenge.mul(tx.gasprice).mul(_declaredNonce));
    // splits bundle into individual rawTxs
    bytes[] rawTxList;
    splitTxBundle(_rawTxBundle, _txLengths, rawTxList);

    //_withdrawTx withdraw() message sent by withdrawer to TokenContract
    RLP.RLPItem[] memory withdrawTx = rawTxList[0].toRLPItem().toList();
    // _lastTx on TokenContract transferring custody of token to withdrawer
    RLP.RLPItem[] memory lastTx = rawTxList[1].toRLPItem().toList();
    // _custodianTx signed version of _lastTx
    RLP.RLPItem[] memory custodianTx = rawTxList[2].toRLPItem().toList();

    checkTransferTxAndCustodianTx(lastTx, custodianTx, _txMsgHashes[2]);

    address lastCustody = parseData(lastTx[5].toData(), 2).toAddress(12);
    require(withdrawTx[3].toAddress() == tokenContract);
    require(lastCustody == ecrecover(_txMsgHashes[0], //hash of withdrawTx
                                     uint8(withdrawTx[6].toUint()), //v
                                     withdrawTx[7].toBytes32(), //r
                                     withdrawTx[8].toBytes32()), //s
                                     "WithdrawalTx not signed by lastTx receipient");

    //checks nonce                   
    require(parseData(lastTx[5].toData(),4).toUint(0) + 1 == _declaredNonce,
        "nonces do not match");
    //require that a challenge period is not underway
    require(challengeTime[_tokenId] == 0);
    //start challenge period
    challengeTime[_tokenId] = now + 10 minutes;
    challengeEndNonce[_tokenId] = _declaredNonce;
    challengeAddressClaim[_tokenId] = lastCustody;
    challengeRecipient[_tokenId] = _to;
    challengeStake[_tokenId] = msg.value;
    emit Withdrawal(_to, _tokenId, msg.value);
  }

  /*
  /**
   * @dev For withdrawer to claims honest withdrawal
   * @param _tokenId uint256 Id of token on TokenContract
  */
  function claim(uint256 _tokenId) public {
    require(challengeTime[_tokenId] != 0,
            "the challenge period has not started yet");
    require(challengeTime[_tokenId] < now,
            "the challenge period has not ended yet");
    //challengeNonce represents the requirement for the next tx (thus the +1)
    require(challengeNonce[_tokenId] == challengeEndNonce[_tokenId] + 1 ||
                                        challengeNonce[_tokenId] == 0,
            "either a challenge has started, or the challenge response has not been proven to endNonce");
    challengeRecipient[_tokenId].send((tokenIdToAmount[_tokenId] ) +
                                       challengeStake[_tokenId]);
    tokenIdToAmount[_tokenId] = 0;
    resetChallenge(_tokenId);
  }

  /*
  /**
   * @dev For challenger to claim stake on fradulent challenge
     (challengeWithPastCustody())
   * @param _tokenId uint256 Id of token on TokenContract
  */
  function claimStake(uint256 _tokenId) public {
    require(challengeTime[_tokenId] != 0);
    require(challengeTime[_tokenId] < now);
    require(challengeNonce[_tokenId] != challengeEndNonce[_tokenId] &&
                                        challengeNonce[_tokenId] != 0,
            "challenge not initated/withdrawal is honest");

    challengeRecipient[_tokenId].send(challengeStake[_tokenId]);

    resetChallenge(_tokenId);
  }
  /*
  /**
   * @dev Challenges with future custody using a transaction proving transfer
   * once future custody is proven, it ends pays the challenger
   * @param _to address to send stake given success
   * @param _tokenId uint256 Id of token on TokenContract
   * @param _rawTxBundle bytes32[] bundle that takes in concatenation of
     bytes _transactionTx, bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle, for efficiency
   * @param _txMsgHashes msghashes of transactions in bundle
  */
  function challengeWithFutureCustody(address _to,
                                      uint256 _tokenId,
                                      bytes32[] _rawTxBundle,
                                      uint256[] _txLengths,
                                      bytes32[] _txMsgHashes) public {
    require(challengeTime[_tokenId] != 0);
    require(challengeTime[_tokenId] > now);

    // splits bundle into individual rawTxs
    bytes[] rawTxList;
    splitTxBundle(_rawTxBundle, _txLengths, rawTxList);

    RLP.RLPItem[] memory transferTx = rawTxList[0].toRLPItem().toList();
    RLP.RLPItem[] memory custodianTx = rawTxList[1].toRLPItem().toList();

    //TODO: NEED TO CHECK NONCE
    checkTransferTxAndCustodianTx(transferTx, custodianTx, _txMsgHashes[1]);
    require(challengeAddressClaim[_tokenId] ==
            parseData(transferTx[5].toData(), 1).toAddress(12),
            "token needs to be transfered from last proven custody");
    require(_tokenId == parseData(transferTx[5].toData(), 3).toUint(0),
            "needs to refer to the same tokenId");

    _to.send(challengeStake[_tokenId]);
    resetChallenge(_tokenId);
  }

/*
  /**
   * @dev Initiates a challenge with past custody using a chain of custody
   leading to the declared nonce once challenge period ends.
   *It should be designed such that it punishes challenging an honest withdrawal
   and incentivises challenging a fradulent one
   * requires challenger to stake.
   // TODO: extend challenge period when called
   * @param _to address to send stake given success
   * @param _tokenId uint256 Id of token on TokenContract
   * @param _rawTxBundle bytes32[] bundle that takes in concatenation of
      bytes _transactionTx, bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle, for efficiency
   * @param _txMsgHashes msghashes of transactions in bundle
  */
  function initiateChallengeWithPastCustody(address _to,
                                            uint256 _tokenId,
                                            bytes32[] _rawTxBundle,
                                            uint256[] _txLengths,
                                            bytes32[] _txMsgHashes)
                                            payable public {
    require(challengeTime[_tokenId] != 0);
    require(challengeTime[_tokenId] > now);
    require(msg.value >= gasPerChallenge.mul(tx.gasprice).
                         mul(challengeEndNonce[_tokenId]).div(5));

    // splits bundle into individual rawTxs
    bytes[] rawTxList;
    splitTxBundle(_rawTxBundle, _txLengths, rawTxList);

    RLP.RLPItem[] memory transferTx = rawTxList[0].toRLPItem().toList();
    RLP.RLPItem[] memory custodianTx = rawTxList[1].toRLPItem().toList();

    checkTransferTxAndCustodianTx(transferTx, custodianTx, _txMsgHashes[1]);
    //TODO: save on require statement by not including _tokenId in arguments
    require(_tokenId == parseData(transferTx[5].toData(), 3).toUint(0),
            "needs to refer to the same tokenId");
    require(tokenIdToMinter[_tokenId] == parseData(transferTx[5].toData(), 1).
            toAddress(12),
            "token needs to be transfered from last proven custody");
    //moves up root mint referecce to recipient address
    tokenIdToMinter[_tokenId] = parseData(transferTx[5].toData(), 2).
                                toAddress(12);
    challengeStake[_tokenId] += msg.value;
    challenger[_tokenId] = _to;
    challengeNonce[_tokenId] = 1;
    emit ChallengeInitiated(msg.sender, _to, _tokenId);
  }

  /*
  /**
   * @dev Add to the chain of custody leading to the declared nonce
   * once challenge period ends claim funds through claimStake()
   // TODO: remove loops (less efficient then single calls)
   * @param _to address to send stake given success
   * @param _tokenId uint256 Id of token on TokenContract
   * @param _rawTxBundle bytes32[] bundle that takes in concatenation of
     bytes _transactionTx, bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle, for efficiency
   * @param _txMsgHashes msghashes of transactions in bundle
  */
  // TODO: rename challegne
  function challengeWithPastCustody(address _to,
                                    uint256 _tokenId,
                                    bytes32[] _rawTxBundle,
                                    uint256[] _txLengths,
                                    bytes32[] _txMsgHashes) public {
    require(challengeTime[_tokenId] != 0);
    require(challengeTime[_tokenId] > now); //challenge is still open
    require(challengeNonce[_tokenId] > 0);

    // splits bundle into individual rawTxs
    bytes[] rawTxList;
    splitTxBundle(_rawTxBundle, _txLengths, rawTxList);

    //get rid of loops
    for (uint i = 0; i < _txLengths.length; i +=2) {
      RLP.RLPItem[] memory transferTx = rawTxList[i].toRLPItem().toList();
      RLP.RLPItem[] memory custodianTx = rawTxList[i + 1].toRLPItem().toList();

      checkTransferTxAndCustodianTx(transferTx, custodianTx, _txMsgHashes[i+1]);
      //TODO: save on require statement by not including _tokenId in arguments
      require(_tokenId == parseData(transferTx[5].toData(), 3).toUint(0),
              "needs to refer to the same tokenId");
      require(tokenIdToMinter[_tokenId] == parseData(transferTx[5].toData(), 1)
              .toAddress(12),
              "token needs to be transfered from last proven custody");
      require(parseData(transferTx[5].toData(),4).toUint(0) ==
              challengeNonce[_tokenId],
              "nonce needs to equal required challengeNonce");

      //moves up root mint referecce to recipient address
      tokenIdToMinter[_tokenId] = parseData(transferTx[5].toData(), 2)
                                  .toAddress(12);
      //updates challengeNonce to next step
      challengeNonce[_tokenId] += 1;
    }
    emit Challenge(msg.sender, _to, _tokenId, challengeNonce[_tokenId]);
  }

  /*
  /**
   * @dev The existence of two tokenIds with same nonce indicates presence of
     double signing on the part of the Custodian => should punish Custodian
   // TODO: how much to punish custodian???
   * @param _to address to send stake given success
   * @param _tokenId uint256 Id of token on TokenContract
   * @param _rawTxBundle bytes32[] concatenation of bytes _transactionTx,
     bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle, for efficiency
   * @param _txMsgHashes msghashes of transactions in bundle
  */
  function submitCustodianDoubleSign(address _to,
                                     uint256 _tokenId,
                                     bytes32[] _rawTxBundle,
                                     uint256[] _txLengths,
                                     bytes32[] _txMsgHashes) public {

    bytes[] rawTxList;
    splitTxBundle(_rawTxBundle, _txLengths, rawTxList);

    RLP.RLPItem[] memory transferTx = rawTxList[0].toRLPItem().toList();
    RLP.RLPItem[] memory custodianTx = rawTxList[1].toRLPItem().toList();
    RLP.RLPItem[] memory transferTx2 = rawTxList[2].toRLPItem().toList();
    RLP.RLPItem[] memory custodianTx2 = rawTxList[3].toRLPItem().toList();

    checkTransferTxAndCustodianTx(transferTx, custodianTx, _txMsgHashes[1]);
    checkTransferTxAndCustodianTx(transferTx2, custodianTx2, _txMsgHashes[3]);
    require(_tokenId == parseData(transferTx[5].toData(), 3).toUint(0),
            "needs to refer to the same tokenId");
    require(_tokenId == parseData(transferTx2[5].toData(), 3).toUint(0),
            "needs to refer to the same tokenId");
    require(parseData(transferTx2[5].toData(), 4).toUint(0) ==
            parseData(transferTx[5].toData(), 4).toUint(0),
            "needs to refer to the same nonce");

    //TODO: how much to punish custodian??? can we pay out the stake instead of
    //just burning it, pause contract??
    stakedAmount = 0;
    depositCap = 0;
  }

  /*
  /**
   * @dev Check the validity of the transfer and custodian transaction
   * @param  _transferTx RLP item array representing transferTx
   * @param _tokenId RLP item array representing corresponding custodianTx
   * @param _rawTxBundle bytes32 _custodianTx msgHash
  */
  function checkTransferTxAndCustodianTx(RLP.RLPItem[] _transferTx,
                                         RLP.RLPItem[] _custodianTx,
                                         bytes32 _custodianTxMsgHash) internal {
    require(_transferTx[3].toAddress() == tokenContract);
    require(_custodianTx[3].toAddress() == tokenContract);
    require(bytesToBytes4(parseData(_transferTx[5].toData(), 0), 0) ==
            transferFromSignature, "_transferTx is not transferFrom function");
    require(bytesToBytes4(parseData(_custodianTx[5].toData(), 0), 0) ==
            custodianApproveSignature, "_custodianTx is not custodianApproval");
    require(custodianForeign == ecrecover(_custodianTxMsgHash,
                                          uint8(_custodianTx[6].toUint()),
                                          _custodianTx[7].toBytes32(),
                                          _custodianTx[8].toBytes32()),
            "_custodianTx should be signed by custodian");
    //TODO: which is more efficient, checking parameters or hash?
    require(parseData(_transferTx[5].toData(),3).
            equal(parseData(_custodianTx[5].toData(),1)),
            "token_ids do not match");
    require(parseData(_transferTx[5].toData(),4).
            equal(parseData(_custodianTx[5].toData(),2)),
            "nonces do not match");
  }

  /*
  /**
   * @dev Splits a rawTxBundle received to its individual transactions.
   * Necessary due to limitation in amount of data transferable through solidity
   * @param  _rawTxBundle that is a concatenation of bytes _withdrawTx,
             bytes _lastTx, bytes _custodianTx
   * @param _txLengths lengths of transactions in rawTxBundle
   * @param _rawTxList list of individual transactions from _rawTxBundle
  */
  function splitTxBundle(bytes32[] _rawTxBundle,
                         uint256[] _txLengths,
                         bytes[] storage _rawTxList) internal {
    uint256 txStartPosition = 0;
    for (uint i = 0; i < _txLengths.length; i++) {
      _rawTxList[i] = sliceBytes32Arr(_rawTxBundle,
                                      txStartPosition,
                                      _txLengths[i]);
      txStartPosition = txStartPosition.add(_txLengths[i]);
      txStartPosition = txStartPosition + (64 - txStartPosition % 64);
    }
  }

  /*
  /**
   * @dev Splits a rawTxBundle received to its individual transactions.
   * Necessary due to limitation in amount of data transferable through solidity
   * @param  _transferTx RLP item array representing transferTx
   * @param _tokenId RLP item array representing corresponding custodianTx
   * @param _rawTxBundle bytes32 _custodianTx msgHash
  */
  //TODO: MAKE MORE EFFICENT
  function sliceBytes32Arr(bytes32[] _bytes32ArrBundle,
                           uint256 _startPosition,
                           uint256 _length) internal returns (bytes) {
    bytes memory out;
    uint256 i = _startPosition.div(64);
    uint256 endPosition = _startPosition.add(_length);
    uint256 z = endPosition.div(64);
    for (i ; i < z; i++) {
      out = out.concat(bytes32ToBytes(_bytes32ArrBundle[i]));
    }
    out = out.concat(bytes32ToBytes(_bytes32ArrBundle[z]).
              slice(0, (endPosition % 64 / 2) - 1));
    return out;
  }

  function resetChallenge(uint256 _tokenId) internal {
    challengeStake[_tokenId] = 0;
    challengeRecipient[_tokenId] = 0;
    challengeAddressClaim[_tokenId] = 0;
    challengeEndNonce[_tokenId] = 0;
    challengeTime[_tokenId] = 0;
    challengeNonce[_tokenId] = 0;
    emit ChallengeResolved(_tokenId);
  }

  /* Util functions --------------------------------------------------*/

  function parseData(bytes data, uint256 i) internal returns (bytes) {
    if (i == 0) {
      return data.slice(0,5);
    } else {
      return data.slice(4 + ((i-1) * 32), 32);
    }
  }

  //https://ethereum.stackexchange.com/questions/40920/convert-bytes32-to-bytes
  //TODO: Look for more efficient method
  function bytes32ToBytes(bytes32 _data) internal pure returns (bytes) {
    return abi.encodePacked(_data);
  }

  function bytesToBytes32(bytes b, uint offset) private pure returns (bytes32) {
    bytes32 out;
    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  function bytesToBytes4(bytes b, uint offset) private pure returns (bytes4) {
    bytes4 out;
    for (uint i = 0; i < 4; i++) {
      out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  function stringToBytes( string s) internal returns (bytes memory b3){
    b3 = bytes(s);
    return b3;
  }

  // Nick Johnson https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
  function uint256ToBytes(uint256 x) internal returns (bytes b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
  }

  // Tjaden Hess https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
  function addressToBytes(address a) internal returns (bytes b) {
    assembly {
        let m := mload(0x40)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
    }
  }

  function ecrecovery(bytes32 hash, bytes sig) public returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return 0;
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }

    // https://github.com/ethereum/go-ethereum/issues/2053
    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return 0;
    }

    /* prefix might be needed for geth only
     * https://github.com/ethereum/go-ethereum/issues/3731
     */
    // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    // hash = sha3(prefix, hash);

    return ecrecover(hash, v, r, s);
  }

  function ecverify(bytes32 hash, bytes sig, address signer)
  public returns (bool) {
    return signer == ecrecovery(hash, sig);
  }

}