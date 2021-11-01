//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@datachainlab/cross-solidity/contracts/core/IContractModule.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solidity-rlp/contracts/RLPReader.sol";

contract MockCrossContract is IContractModule {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    bytes32 public constant TYPE_URL = keccak256(abi.encodePacked("/extension.types.MockAuthExtension"));

    struct CallInfo {
        IERC20 token;
        string functionName;
        RLPReader.RLPItem args;
    }

    modifier checkRlpFormat(bytes memory raw) {
        RLPReader.RLPItem[] memory items = raw.toRlpItem().toList();
        require(items.length >= 2, "items must be more than two");
        _;
    }

    function onContractCall(CrossContext calldata context, bytes calldata _callInfo)
        external
        override
        returns (bytes memory)
    {
        require(context.signers.length == 1, "signers length must be 1");
        require(
            context.signers[0].auth_type.mode == AuthType.AuthMode.AUTH_MODE_EXTENSION,
            "auth mode must be EXTENSION"
        );
        require(
            keccak256(abi.encodePacked(context.signers[0].auth_type.option.type_url)) == TYPE_URL,
            "extension must be MockAuthExtension"
        );

        CallInfo memory callInfo = bytesToCallInfo(_callInfo);

        require(keccak256(bytes(callInfo.functionName)) == keccak256(bytes("transfer")), "invalid callInfo");

        RLPReader.RLPItem[] memory args = callInfo.args.toList();

        address sender = bytesToAddress(context.signers[0].id);
        address recipient = args[0].toAddress();
        uint256 amount = args[1].toUint();

        require(callInfo.token.transferFrom(sender, recipient, amount), "MockCrossContract: fail to transfer");

        return bytes("mock call succeed");
    }

    function bytesToCallInfo(bytes memory raw) private checkRlpFormat(raw) returns (CallInfo memory callInfo) {
        RLPReader.Iterator memory iter = raw.toRlpItem().iterator();
        callInfo.token = IERC20(iter.next().toAddress());
        callInfo.functionName = string(iter.next().toBytes());
        if (iter.hasNext()) {
            callInfo.args = iter.next();
        }

        return callInfo;
    }

    function bytesToAddress(bytes memory b) internal pure returns (address addr) {
        assembly {
            addr := mload(add(b, 20))
        }
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.8;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;


/**
 * @title Runtime library for ProtoBuf serialization and/or deserialization.
 * All ProtoBuf generated code will use this library.
 */
library ProtoBufRuntime {
  // Types defined in ProtoBuf
  enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }
  // Constants for bytes calculation
  uint256 constant WORD_LENGTH = 32;
  uint256 constant HEADER_SIZE_LENGTH_IN_BYTES = 4;
  uint256 constant BYTE_SIZE = 8;
  uint256 constant REMAINING_LENGTH = WORD_LENGTH - HEADER_SIZE_LENGTH_IN_BYTES;
  string constant OVERFLOW_MESSAGE = "length overflow";

  //Storages
  /**
   * @dev Encode to storage location using assembly to save storage space.
   * @param location The location of storage
   * @param encoded The encoded ProtoBuf bytes
   */
  function encodeStorage(bytes storage location, bytes memory encoded)
    internal
  {
    /**
     * This code use the first four bytes as size,
     * and then put the rest of `encoded` bytes.
     */
    uint256 length = encoded.length;
    uint256 firstWord;
    uint256 wordLength = WORD_LENGTH;
    uint256 remainingLength = REMAINING_LENGTH;

    assembly {
      firstWord := mload(add(encoded, wordLength))
    }
    firstWord =
      (firstWord >> (BYTE_SIZE * HEADER_SIZE_LENGTH_IN_BYTES)) |
      (length << (BYTE_SIZE * REMAINING_LENGTH));

    assembly {
      sstore(location_slot, firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          sstore(
            add(location_slot, slotIndex),
            mload(add(add(encoded, wordLength), offset))
          )
        }
      }
    }
  }

  /**
   * @dev Decode storage location using assembly using the format in `encodeStorage`.
   * @param location The location of storage
   * @return The encoded bytes
   */
  function decodeStorage(bytes storage location)
    internal
    view
    returns (bytes memory)
  {
    /**
     * This code is to decode the first four bytes as size,
     * and then decode the rest using the decoded size.
     */
    uint256 firstWord;
    uint256 remainingLength = REMAINING_LENGTH;
    uint256 wordLength = WORD_LENGTH;

    assembly {
      firstWord := sload(location_slot)
    }

    uint256 length = firstWord >> (BYTE_SIZE * REMAINING_LENGTH);
    bytes memory encoded = new bytes(length);

    assembly {
      mstore(add(encoded, remainingLength), firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          mstore(
            add(add(encoded, wordLength), offset),
            sload(add(location_slot, slotIndex))
          )
        }
      }
    }
    return encoded;
  }

  /**
   * @dev Fast memory copy of bytes using assembly.
   * @param src The source memory address
   * @param dest The destination memory address
   * @param len The length of bytes to copy
   */
  function copyBytes(uint256 src, uint256 dest, uint256 len) internal pure {
    // Copy word-length chunks while possible
    for (; len >= WORD_LENGTH; len -= WORD_LENGTH) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += WORD_LENGTH;
      src += WORD_LENGTH;
    }

    // Copy remaining bytes
    uint256 mask = 256**(WORD_LENGTH - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /**
   * @dev Use assembly to get memory address.
   * @param r The in-memory bytes array
   * @return The memory address of `r`
   */
  function getMemoryAddress(bytes memory r) internal pure returns (uint256) {
    uint256 addr;
    assembly {
      addr := r
    }
    return addr;
  }

  /**
   * @dev Implement Math function of ceil
   * @param a The denominator
   * @param m The numerator
   * @return r The result of ceil(a/m)
   */
  function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
    return (a + m - 1) / m;
  }

  // Decoders
  /**
   * This section of code `_decode_(u)int(32|64)`, `_decode_enum` and `_decode_bool`
   * is to decode ProtoBuf native integers,
   * using the `varint` encoding.
   */

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    return (uint32(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    return (uint64(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    int32 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    int64 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded enum's integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_enum(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    return _decode_int64(p, bs);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded boolean
   * @return The length of `bs` used to get decoded
   */
  function _decode_bool(uint256 p, bytes memory bs)
    internal
    pure
    returns (bool, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    if (varint == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  /**
   * This section of code `_decode_sint(32|64)`
   * is to decode ProtoBuf native signed integers,
   * using the `zig-zag` encoding.
   */

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (int256 varint, uint256 sz) = _decode_varints(p, bs);
    return (int32(varint), sz);
  }

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (int256 varint, uint256 sz) = _decode_varints(p, bs);
    return (int64(varint), sz);
  }

  /**
   * @dev Decode string
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded string
   * @return The length of `bs` used to get decoded
   */
  function _decode_string(uint256 p, bytes memory bs)
    internal
    pure
    returns (string memory, uint256)
  {
    (bytes memory x, uint256 sz) = _decode_lendelim(p, bs);
    return (string(x), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_bytes(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes memory, uint256)
  {
    return _decode_lendelim(p, bs);
  }

  /**
   * @dev Decode ProtoBuf key
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded field ID
   * @return The decoded WireType specified in ProtoBuf
   * @return The length of `bs` used to get decoded
   */
  function _decode_key(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, WireType, uint256)
  {
    (uint256 x, uint256 n) = _decode_varint(p, bs);
    WireType typeId = WireType(x & 7);
    uint256 fieldId = x / 8;
    return (fieldId, typeId, n);
  }

  /**
   * @dev Decode ProtoBuf varint
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varint(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    /**
     * Read a byte.
     * Use the lower 7 bits and shift it to the left,
     * until the most significant bit is 0.
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 x = 0;
    uint256 sz = 0;
    uint256 length = bs.length + WORD_LENGTH;
    assembly {
      let b := 0x80
      p := add(bs, p)
      for {

      } eq(0x80, and(b, 0x80)) {

      } {
        if eq(lt(sub(p, bs), length), 0) {
          mstore(
            0,
            0x08c379a000000000000000000000000000000000000000000000000000000000
          ) //error function selector
          mstore(4, 32)
          mstore(36, 15)
          mstore(
            68,
            0x6c656e677468206f766572666c6f770000000000000000000000000000000000
          ) // length overflow in hex
          revert(0, 83)
        }
        let tmp := mload(p)
        let pos := 0
        for {

        } and(eq(0x80, and(b, 0x80)), lt(pos, 32)) {

        } {
          if eq(lt(sub(p, bs), length), 0) {
            mstore(
              0,
              0x08c379a000000000000000000000000000000000000000000000000000000000
            ) //error function selector
            mstore(4, 32)
            mstore(36, 15)
            mstore(
              68,
              0x6c656e677468206f766572666c6f770000000000000000000000000000000000
            ) // length overflow in hex
            revert(0, 83)
          }
          b := byte(pos, tmp)
          x := or(x, shl(mul(7, sz), and(0x7f, b)))
          sz := add(sz, 1)
          pos := add(pos, 1)
          p := add(p, 0x01)
        }
      }
    }
    return (x, sz);
  }

  /**
   * @dev Decode ProtoBuf zig-zag encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded signed integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varints(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    (uint256 u, uint256 sz) = _decode_varint(p, bs);
    int256 s;
    assembly {
      s := xor(shr(1, u), add(not(and(u, 1)), 1))
    }
    return (s, sz);
  }

  /**
   * @dev Decode ProtoBuf fixed-length encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uintf(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (uint256, uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 x = 0;
    uint256 length = bs.length + WORD_LENGTH;
    assert(p + sz <= length);
    assembly {
      let i := 0
      p := add(bs, p)
      let tmp := mload(p)
      for {

      } lt(i, sz) {

      } {
        x := or(x, shl(mul(8, i), byte(i, tmp)))
        p := add(p, 0x01)
        i := add(i, 1)
      }
    }
    return (x, sz);
  }

  /**
   * `_decode_(s)fixed(32|64)` is the concrete implementation of `_decode_uintf`
   */
  function _decode_fixed32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
    return (uint32(x), sz);
  }

  function _decode_fixed64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
    return (uint64(x), sz);
  }

  function _decode_sfixed32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
    int256 r;
    assembly {
      r := x
    }
    return (int32(r), sz);
  }

  function _decode_sfixed64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
    int256 r;
    assembly {
      r := x
    }
    return (int64(r), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_lendelim(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes memory, uint256)
  {
    /**
     * First read the size encoded in `varint`, then use the size to read bytes.
     */
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    bytes memory b = new bytes(len);
    uint256 length = bs.length + WORD_LENGTH;
    assert(p + sz + len <= length);
    uint256 sourcePtr;
    uint256 destPtr;
    assembly {
      destPtr := add(b, 32)
      sourcePtr := add(add(bs, p), sz)
    }
    copyBytes(sourcePtr, destPtr, len);
    return (b, sz + len);
  }

  // Encoders
  /**
   * @dev Encode ProtoBuf key
   * @param x The field ID
   * @param wt The WireType specified in ProtoBuf
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_key(uint256 x, WireType wt, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 i;
    assembly {
      i := or(mul(x, 8), mod(wt, 8))
    }
    return _encode_varint(i, p, bs);
  }

  /**
   * @dev Encode ProtoBuf varint
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varint(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 sz = 0;
    assembly {
      let bsptr := add(bs, p)
      let byt := and(x, 0x7f)
      for {

      } gt(shr(7, x), 0) {

      } {
        mstore8(bsptr, or(0x80, byt))
        bsptr := add(bsptr, 1)
        sz := add(sz, 1)
        x := shr(7, x)
        byt := and(x, 0x7f)
      }
      mstore8(bsptr, byt)
      sz := add(sz, 1)
    }
    return sz;
  }

  /**
   * @dev Encode ProtoBuf zig-zag encoding
   * @param x The signed integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varints(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 encodedInt = _encode_zigzag(x);
    return _encode_varint(encodedInt, p, bs);
  }

  /**
   * @dev Encode ProtoBuf bytes
   * @param xs The bytes array to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_bytes(bytes memory xs, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 xsLength = xs.length;
    uint256 sz = _encode_varint(xsLength, p, bs);
    uint256 count = 0;
    assembly {
      let bsptr := add(bs, add(p, sz))
      let xsptr := add(xs, 32)
      for {

      } lt(count, xsLength) {

      } {
        mstore8(bsptr, byte(0, mload(xsptr)))
        bsptr := add(bsptr, 1)
        xsptr := add(xsptr, 1)
        count := add(count, 1)
      }
    }
    return sz + count;
  }

  /**
   * @dev Encode ProtoBuf string
   * @param xs The string to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_string(string memory xs, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_bytes(bytes(xs), p, bs);
  }

  /**
   * `_encode_(u)int(32|64)`, `_encode_enum` and `_encode_bool`
   * are concrete implementation of `_encode_varint`
   */
  function _encode_uint32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varint(x, p, bs);
  }

  function _encode_uint64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varint(x, p, bs);
  }

  function _encode_int32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_int64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_enum(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_int64(x, p, bs);
  }

  function _encode_bool(bool x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    if (x) {
      return _encode_varint(1, p, bs);
    } else return _encode_varint(0, p, bs);
  }

  /**
   * `_encode_sint(32|64)`, `_encode_enum` and `_encode_bool`
   * are the concrete implementation of `_encode_varints`
   */
  function _encode_sint32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varints(x, p, bs);
  }

  function _encode_sint64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varints(x, p, bs);
  }

  /**
   * `_encode_(s)fixed(32|64)` is the concrete implementation of `_encode_uintf`
   */
  function _encode_fixed32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_uintf(x, p, bs, 4);
  }

  function _encode_fixed64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_uintf(x, p, bs, 8);
  }

  function _encode_sfixed32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint32 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 4);
  }

  function _encode_sfixed64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 8);
  }

  /**
   * @dev Encode ProtoBuf fixed-length integer
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_uintf(uint256 x, uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    assembly {
      let bsptr := add(sz, add(bs, p))
      let count := sz
      for {

      } gt(count, 0) {

      } {
        bsptr := sub(bsptr, 1)
        mstore8(bsptr, byte(sub(32, count), x))
        count := sub(count, 1)
      }
    }
    return sz;
  }

  /**
   * @dev Encode ProtoBuf zig-zag signed integer
   * @param i The unsigned integer to be encoded
   * @return The encoded unsigned integer
   */
  function _encode_zigzag(int256 i) internal pure returns (uint256) {
    if (i >= 0) {
      return uint256(i) * 2;
    } else return uint256(i * -2) - 1;
  }

  // Estimators
  /**
   * @dev Estimate the length of encoded LengthDelim
   * @param i The length of LengthDelim
   * @return The estimated encoded length
   */
  function _sz_lendelim(uint256 i) internal pure returns (uint256) {
    return i + _sz_varint(i);
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf field ID
   * @param i The field ID
   * @return The estimated encoded length
   */
  function _sz_key(uint256 i) internal pure returns (uint256) {
    if (i < 16) {
      return 1;
    } else if (i < 2048) {
      return 2;
    } else if (i < 262144) {
      return 3;
    } else {
      revert("not supported");
    }
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf varint
   * @param i The unsigned integer
   * @return The estimated encoded length
   */
  function _sz_varint(uint256 i) internal pure returns (uint256) {
    uint256 count = 1;
    assembly {
      i := shr(7, i)
      for {

      } gt(i, 0) {

      } {
        i := shr(7, i)
        count := add(count, 1)
      }
    }
    return count;
  }

  /**
   * `_sz_(u)int(32|64)` and `_sz_enum` are the concrete implementation of `_sz_varint`
   */
  function _sz_uint32(uint32 i) internal pure returns (uint256) {
    return _sz_varint(i);
  }

  function _sz_uint64(uint64 i) internal pure returns (uint256) {
    return _sz_varint(i);
  }

  function _sz_int32(int32 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint32(i));
  }

  function _sz_int64(int64 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint64(i));
  }

  function _sz_enum(int64 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint64(i));
  }

  /**
   * `_sz_sint(32|64)` and `_sz_enum` are the concrete implementation of zig-zag encoding
   */
  function _sz_sint32(int32 i) internal pure returns (uint256) {
    return _sz_varint(_encode_zigzag(i));
  }

  function _sz_sint64(int64 i) internal pure returns (uint256) {
    return _sz_varint(_encode_zigzag(i));
  }

  // Soltype extensions
  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from lowest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN_lower(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    uint256 r;
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    assert(p < bs.length + WORD_LENGTH);
    assembly {
      r := mload(add(p, bs))
    }
    for (uint256 i = len - 2; i < WORD_LENGTH; i++) {
      r /= 256;
    }
    return (bytes32(r), len + sz);
  }

  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from highest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    uint256 wordLength = WORD_LENGTH;
    uint256 byteSize = BYTE_SIZE;
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    bytes32 acc;
    assert(p < bs.length + WORD_LENGTH);
    assembly {
      acc := mload(add(p, bs))
      let difference := sub(wordLength, sub(len, 2))
      let bits := mul(byteSize, difference)
      acc := shl(bits, shr(bits, acc))
    }
    return (acc, len + sz);
  }

  /*
   * `_decode_sol*` are the concrete implementation of decoding Solidity types
   */
  function _decode_sol_address(uint256 p, bytes memory bs)
    internal
    pure
    returns (address, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytesN(20, p, bs);
    return (address(bytes20(r)), sz);
  }

  function _decode_sol_bool(uint256 p, bytes memory bs)
    internal
    pure
    returns (bool, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
    if (r == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  function _decode_sol_uint(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    return _decode_sol_uint256(p, bs);
  }

  function _decode_sol_uintN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
    uint256 r;
    assembly {
      r := u
    }
    return (r, sz);
  }

  function _decode_sol_uint8(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint8, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
    return (uint8(r), sz);
  }

  function _decode_sol_uint16(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint16, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(2, p, bs);
    return (uint16(r), sz);
  }

  function _decode_sol_uint24(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint24, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(3, p, bs);
    return (uint24(r), sz);
  }

  function _decode_sol_uint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(4, p, bs);
    return (uint32(r), sz);
  }

  function _decode_sol_uint40(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint40, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(5, p, bs);
    return (uint40(r), sz);
  }

  function _decode_sol_uint48(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint48, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(6, p, bs);
    return (uint48(r), sz);
  }

  function _decode_sol_uint56(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint56, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(7, p, bs);
    return (uint56(r), sz);
  }

  function _decode_sol_uint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(8, p, bs);
    return (uint64(r), sz);
  }

  function _decode_sol_uint72(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint72, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(9, p, bs);
    return (uint72(r), sz);
  }

  function _decode_sol_uint80(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint80, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(10, p, bs);
    return (uint80(r), sz);
  }

  function _decode_sol_uint88(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint88, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(11, p, bs);
    return (uint88(r), sz);
  }

  function _decode_sol_uint96(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint96, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(12, p, bs);
    return (uint96(r), sz);
  }

  function _decode_sol_uint104(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint104, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(13, p, bs);
    return (uint104(r), sz);
  }

  function _decode_sol_uint112(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint112, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(14, p, bs);
    return (uint112(r), sz);
  }

  function _decode_sol_uint120(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint120, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(15, p, bs);
    return (uint120(r), sz);
  }

  function _decode_sol_uint128(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint128, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(16, p, bs);
    return (uint128(r), sz);
  }

  function _decode_sol_uint136(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint136, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(17, p, bs);
    return (uint136(r), sz);
  }

  function _decode_sol_uint144(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint144, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(18, p, bs);
    return (uint144(r), sz);
  }

  function _decode_sol_uint152(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint152, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(19, p, bs);
    return (uint152(r), sz);
  }

  function _decode_sol_uint160(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint160, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(20, p, bs);
    return (uint160(r), sz);
  }

  function _decode_sol_uint168(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint168, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(21, p, bs);
    return (uint168(r), sz);
  }

  function _decode_sol_uint176(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint176, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(22, p, bs);
    return (uint176(r), sz);
  }

  function _decode_sol_uint184(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint184, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(23, p, bs);
    return (uint184(r), sz);
  }

  function _decode_sol_uint192(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint192, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(24, p, bs);
    return (uint192(r), sz);
  }

  function _decode_sol_uint200(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint200, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(25, p, bs);
    return (uint200(r), sz);
  }

  function _decode_sol_uint208(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint208, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(26, p, bs);
    return (uint208(r), sz);
  }

  function _decode_sol_uint216(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint216, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(27, p, bs);
    return (uint216(r), sz);
  }

  function _decode_sol_uint224(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint224, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(28, p, bs);
    return (uint224(r), sz);
  }

  function _decode_sol_uint232(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint232, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(29, p, bs);
    return (uint232(r), sz);
  }

  function _decode_sol_uint240(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint240, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(30, p, bs);
    return (uint240(r), sz);
  }

  function _decode_sol_uint248(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint248, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(31, p, bs);
    return (uint248(r), sz);
  }

  function _decode_sol_uint256(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(32, p, bs);
    return (uint256(r), sz);
  }

  function _decode_sol_int(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    return _decode_sol_int256(p, bs);
  }

  function _decode_sol_intN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
    int256 r;
    assembly {
      r := u
      r := signextend(sub(sz, 4), r)
    }
    return (r, sz);
  }

  function _decode_sol_bytes(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN(n, p, bs);
    return (u, sz);
  }

  function _decode_sol_int8(uint256 p, bytes memory bs)
    internal
    pure
    returns (int8, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(1, p, bs);
    return (int8(r), sz);
  }

  function _decode_sol_int16(uint256 p, bytes memory bs)
    internal
    pure
    returns (int16, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(2, p, bs);
    return (int16(r), sz);
  }

  function _decode_sol_int24(uint256 p, bytes memory bs)
    internal
    pure
    returns (int24, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(3, p, bs);
    return (int24(r), sz);
  }

  function _decode_sol_int32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(4, p, bs);
    return (int32(r), sz);
  }

  function _decode_sol_int40(uint256 p, bytes memory bs)
    internal
    pure
    returns (int40, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(5, p, bs);
    return (int40(r), sz);
  }

  function _decode_sol_int48(uint256 p, bytes memory bs)
    internal
    pure
    returns (int48, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(6, p, bs);
    return (int48(r), sz);
  }

  function _decode_sol_int56(uint256 p, bytes memory bs)
    internal
    pure
    returns (int56, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(7, p, bs);
    return (int56(r), sz);
  }

  function _decode_sol_int64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(8, p, bs);
    return (int64(r), sz);
  }

  function _decode_sol_int72(uint256 p, bytes memory bs)
    internal
    pure
    returns (int72, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(9, p, bs);
    return (int72(r), sz);
  }

  function _decode_sol_int80(uint256 p, bytes memory bs)
    internal
    pure
    returns (int80, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(10, p, bs);
    return (int80(r), sz);
  }

  function _decode_sol_int88(uint256 p, bytes memory bs)
    internal
    pure
    returns (int88, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(11, p, bs);
    return (int88(r), sz);
  }

  function _decode_sol_int96(uint256 p, bytes memory bs)
    internal
    pure
    returns (int96, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(12, p, bs);
    return (int96(r), sz);
  }

  function _decode_sol_int104(uint256 p, bytes memory bs)
    internal
    pure
    returns (int104, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(13, p, bs);
    return (int104(r), sz);
  }

  function _decode_sol_int112(uint256 p, bytes memory bs)
    internal
    pure
    returns (int112, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(14, p, bs);
    return (int112(r), sz);
  }

  function _decode_sol_int120(uint256 p, bytes memory bs)
    internal
    pure
    returns (int120, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(15, p, bs);
    return (int120(r), sz);
  }

  function _decode_sol_int128(uint256 p, bytes memory bs)
    internal
    pure
    returns (int128, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(16, p, bs);
    return (int128(r), sz);
  }

  function _decode_sol_int136(uint256 p, bytes memory bs)
    internal
    pure
    returns (int136, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(17, p, bs);
    return (int136(r), sz);
  }

  function _decode_sol_int144(uint256 p, bytes memory bs)
    internal
    pure
    returns (int144, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(18, p, bs);
    return (int144(r), sz);
  }

  function _decode_sol_int152(uint256 p, bytes memory bs)
    internal
    pure
    returns (int152, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(19, p, bs);
    return (int152(r), sz);
  }

  function _decode_sol_int160(uint256 p, bytes memory bs)
    internal
    pure
    returns (int160, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(20, p, bs);
    return (int160(r), sz);
  }

  function _decode_sol_int168(uint256 p, bytes memory bs)
    internal
    pure
    returns (int168, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(21, p, bs);
    return (int168(r), sz);
  }

  function _decode_sol_int176(uint256 p, bytes memory bs)
    internal
    pure
    returns (int176, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(22, p, bs);
    return (int176(r), sz);
  }

  function _decode_sol_int184(uint256 p, bytes memory bs)
    internal
    pure
    returns (int184, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(23, p, bs);
    return (int184(r), sz);
  }

  function _decode_sol_int192(uint256 p, bytes memory bs)
    internal
    pure
    returns (int192, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(24, p, bs);
    return (int192(r), sz);
  }

  function _decode_sol_int200(uint256 p, bytes memory bs)
    internal
    pure
    returns (int200, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(25, p, bs);
    return (int200(r), sz);
  }

  function _decode_sol_int208(uint256 p, bytes memory bs)
    internal
    pure
    returns (int208, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(26, p, bs);
    return (int208(r), sz);
  }

  function _decode_sol_int216(uint256 p, bytes memory bs)
    internal
    pure
    returns (int216, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(27, p, bs);
    return (int216(r), sz);
  }

  function _decode_sol_int224(uint256 p, bytes memory bs)
    internal
    pure
    returns (int224, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(28, p, bs);
    return (int224(r), sz);
  }

  function _decode_sol_int232(uint256 p, bytes memory bs)
    internal
    pure
    returns (int232, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(29, p, bs);
    return (int232(r), sz);
  }

  function _decode_sol_int240(uint256 p, bytes memory bs)
    internal
    pure
    returns (int240, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(30, p, bs);
    return (int240(r), sz);
  }

  function _decode_sol_int248(uint256 p, bytes memory bs)
    internal
    pure
    returns (int248, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(31, p, bs);
    return (int248(r), sz);
  }

  function _decode_sol_int256(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(32, p, bs);
    return (int256(r), sz);
  }

  function _decode_sol_bytes1(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes1, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(1, p, bs);
    return (bytes1(r), sz);
  }

  function _decode_sol_bytes2(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes2, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(2, p, bs);
    return (bytes2(r), sz);
  }

  function _decode_sol_bytes3(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes3, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(3, p, bs);
    return (bytes3(r), sz);
  }

  function _decode_sol_bytes4(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes4, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(4, p, bs);
    return (bytes4(r), sz);
  }

  function _decode_sol_bytes5(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes5, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(5, p, bs);
    return (bytes5(r), sz);
  }

  function _decode_sol_bytes6(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes6, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(6, p, bs);
    return (bytes6(r), sz);
  }

  function _decode_sol_bytes7(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes7, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(7, p, bs);
    return (bytes7(r), sz);
  }

  function _decode_sol_bytes8(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes8, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(8, p, bs);
    return (bytes8(r), sz);
  }

  function _decode_sol_bytes9(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes9, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(9, p, bs);
    return (bytes9(r), sz);
  }

  function _decode_sol_bytes10(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes10, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(10, p, bs);
    return (bytes10(r), sz);
  }

  function _decode_sol_bytes11(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes11, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(11, p, bs);
    return (bytes11(r), sz);
  }

  function _decode_sol_bytes12(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes12, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(12, p, bs);
    return (bytes12(r), sz);
  }

  function _decode_sol_bytes13(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes13, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(13, p, bs);
    return (bytes13(r), sz);
  }

  function _decode_sol_bytes14(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes14, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(14, p, bs);
    return (bytes14(r), sz);
  }

  function _decode_sol_bytes15(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes15, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(15, p, bs);
    return (bytes15(r), sz);
  }

  function _decode_sol_bytes16(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes16, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(16, p, bs);
    return (bytes16(r), sz);
  }

  function _decode_sol_bytes17(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes17, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(17, p, bs);
    return (bytes17(r), sz);
  }

  function _decode_sol_bytes18(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes18, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(18, p, bs);
    return (bytes18(r), sz);
  }

  function _decode_sol_bytes19(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes19, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(19, p, bs);
    return (bytes19(r), sz);
  }

  function _decode_sol_bytes20(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes20, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(20, p, bs);
    return (bytes20(r), sz);
  }

  function _decode_sol_bytes21(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes21, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(21, p, bs);
    return (bytes21(r), sz);
  }

  function _decode_sol_bytes22(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes22, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(22, p, bs);
    return (bytes22(r), sz);
  }

  function _decode_sol_bytes23(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes23, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(23, p, bs);
    return (bytes23(r), sz);
  }

  function _decode_sol_bytes24(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes24, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(24, p, bs);
    return (bytes24(r), sz);
  }

  function _decode_sol_bytes25(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes25, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(25, p, bs);
    return (bytes25(r), sz);
  }

  function _decode_sol_bytes26(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes26, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(26, p, bs);
    return (bytes26(r), sz);
  }

  function _decode_sol_bytes27(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes27, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(27, p, bs);
    return (bytes27(r), sz);
  }

  function _decode_sol_bytes28(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes28, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(28, p, bs);
    return (bytes28(r), sz);
  }

  function _decode_sol_bytes29(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes29, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(29, p, bs);
    return (bytes29(r), sz);
  }

  function _decode_sol_bytes30(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes30, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(30, p, bs);
    return (bytes30(r), sz);
  }

  function _decode_sol_bytes31(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes31, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(31, p, bs);
    return (bytes31(r), sz);
  }

  function _decode_sol_bytes32(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    return _decode_sol_bytes(32, p, bs);
  }

  /*
   * `_encode_sol*` are the concrete implementation of encoding Solidity types
   */
  function _encode_sol_address(address x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 20, p, bs);
  }

  function _encode_sol_uint(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 32, p, bs);
  }

  function _encode_sol_uint8(uint8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 1, p, bs);
  }

  function _encode_sol_uint16(uint16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 2, p, bs);
  }

  function _encode_sol_uint24(uint24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 3, p, bs);
  }

  function _encode_sol_uint32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 4, p, bs);
  }

  function _encode_sol_uint40(uint40 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 5, p, bs);
  }

  function _encode_sol_uint48(uint48 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 6, p, bs);
  }

  function _encode_sol_uint56(uint56 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 7, p, bs);
  }

  function _encode_sol_uint64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 8, p, bs);
  }

  function _encode_sol_uint72(uint72 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 9, p, bs);
  }

  function _encode_sol_uint80(uint80 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 10, p, bs);
  }

  function _encode_sol_uint88(uint88 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 11, p, bs);
  }

  function _encode_sol_uint96(uint96 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 12, p, bs);
  }

  function _encode_sol_uint104(uint104 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 13, p, bs);
  }

  function _encode_sol_uint112(uint112 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 14, p, bs);
  }

  function _encode_sol_uint120(uint120 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 15, p, bs);
  }

  function _encode_sol_uint128(uint128 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 16, p, bs);
  }

  function _encode_sol_uint136(uint136 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 17, p, bs);
  }

  function _encode_sol_uint144(uint144 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 18, p, bs);
  }

  function _encode_sol_uint152(uint152 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 19, p, bs);
  }

  function _encode_sol_uint160(uint160 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 20, p, bs);
  }

  function _encode_sol_uint168(uint168 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 21, p, bs);
  }

  function _encode_sol_uint176(uint176 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 22, p, bs);
  }

  function _encode_sol_uint184(uint184 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 23, p, bs);
  }

  function _encode_sol_uint192(uint192 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 24, p, bs);
  }

  function _encode_sol_uint200(uint200 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 25, p, bs);
  }

  function _encode_sol_uint208(uint208 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 26, p, bs);
  }

  function _encode_sol_uint216(uint216 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 27, p, bs);
  }

  function _encode_sol_uint224(uint224 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 28, p, bs);
  }

  function _encode_sol_uint232(uint232 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 29, p, bs);
  }

  function _encode_sol_uint240(uint240 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 30, p, bs);
  }

  function _encode_sol_uint248(uint248 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 31, p, bs);
  }

  function _encode_sol_uint256(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 32, p, bs);
  }

  function _encode_sol_int(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(x, 32, p, bs);
  }

  function _encode_sol_int8(int8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 1, p, bs);
  }

  function _encode_sol_int16(int16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 2, p, bs);
  }

  function _encode_sol_int24(int24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 3, p, bs);
  }

  function _encode_sol_int32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 4, p, bs);
  }

  function _encode_sol_int40(int40 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 5, p, bs);
  }

  function _encode_sol_int48(int48 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 6, p, bs);
  }

  function _encode_sol_int56(int56 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 7, p, bs);
  }

  function _encode_sol_int64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 8, p, bs);
  }

  function _encode_sol_int72(int72 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 9, p, bs);
  }

  function _encode_sol_int80(int80 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 10, p, bs);
  }

  function _encode_sol_int88(int88 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 11, p, bs);
  }

  function _encode_sol_int96(int96 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 12, p, bs);
  }

  function _encode_sol_int104(int104 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 13, p, bs);
  }

  function _encode_sol_int112(int112 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 14, p, bs);
  }

  function _encode_sol_int120(int120 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 15, p, bs);
  }

  function _encode_sol_int128(int128 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 16, p, bs);
  }

  function _encode_sol_int136(int136 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 17, p, bs);
  }

  function _encode_sol_int144(int144 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 18, p, bs);
  }

  function _encode_sol_int152(int152 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 19, p, bs);
  }

  function _encode_sol_int160(int160 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 20, p, bs);
  }

  function _encode_sol_int168(int168 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 21, p, bs);
  }

  function _encode_sol_int176(int176 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 22, p, bs);
  }

  function _encode_sol_int184(int184 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 23, p, bs);
  }

  function _encode_sol_int192(int192 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 24, p, bs);
  }

  function _encode_sol_int200(int200 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 25, p, bs);
  }

  function _encode_sol_int208(int208 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 26, p, bs);
  }

  function _encode_sol_int216(int216 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 27, p, bs);
  }

  function _encode_sol_int224(int224 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 28, p, bs);
  }

  function _encode_sol_int232(int232 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 29, p, bs);
  }

  function _encode_sol_int240(int240 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 30, p, bs);
  }

  function _encode_sol_int248(int248 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 31, p, bs);
  }

  function _encode_sol_int256(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(x, 32, p, bs);
  }

  function _encode_sol_bytes1(bytes1 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 1, p, bs);
  }

  function _encode_sol_bytes2(bytes2 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 2, p, bs);
  }

  function _encode_sol_bytes3(bytes3 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 3, p, bs);
  }

  function _encode_sol_bytes4(bytes4 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 4, p, bs);
  }

  function _encode_sol_bytes5(bytes5 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 5, p, bs);
  }

  function _encode_sol_bytes6(bytes6 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 6, p, bs);
  }

  function _encode_sol_bytes7(bytes7 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 7, p, bs);
  }

  function _encode_sol_bytes8(bytes8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 8, p, bs);
  }

  function _encode_sol_bytes9(bytes9 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 9, p, bs);
  }

  function _encode_sol_bytes10(bytes10 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 10, p, bs);
  }

  function _encode_sol_bytes11(bytes11 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 11, p, bs);
  }

  function _encode_sol_bytes12(bytes12 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 12, p, bs);
  }

  function _encode_sol_bytes13(bytes13 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 13, p, bs);
  }

  function _encode_sol_bytes14(bytes14 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 14, p, bs);
  }

  function _encode_sol_bytes15(bytes15 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 15, p, bs);
  }

  function _encode_sol_bytes16(bytes16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 16, p, bs);
  }

  function _encode_sol_bytes17(bytes17 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 17, p, bs);
  }

  function _encode_sol_bytes18(bytes18 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 18, p, bs);
  }

  function _encode_sol_bytes19(bytes19 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 19, p, bs);
  }

  function _encode_sol_bytes20(bytes20 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 20, p, bs);
  }

  function _encode_sol_bytes21(bytes21 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 21, p, bs);
  }

  function _encode_sol_bytes22(bytes22 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 22, p, bs);
  }

  function _encode_sol_bytes23(bytes23 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 23, p, bs);
  }

  function _encode_sol_bytes24(bytes24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 24, p, bs);
  }

  function _encode_sol_bytes25(bytes25 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 25, p, bs);
  }

  function _encode_sol_bytes26(bytes26 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 26, p, bs);
  }

  function _encode_sol_bytes27(bytes27 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 27, p, bs);
  }

  function _encode_sol_bytes28(bytes28 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 28, p, bs);
  }

  function _encode_sol_bytes29(bytes29 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 29, p, bs);
  }

  function _encode_sol_bytes30(bytes30 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 30, p, bs);
  }

  function _encode_sol_bytes31(bytes31 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 31, p, bs);
  }

  function _encode_sol_bytes32(bytes32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(x, 32, p, bs);
  }

  /**
   * @dev Encode the key of Solidity integer and/or fixed-size bytes array.
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_header(uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    p += _encode_varint(sz + 2, p, bs);
    p += _encode_key(1, WireType.LengthDelim, p, bs);
    p += _encode_varint(sz, p, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The unsinged integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(uint256 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The signed integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(int256 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The fixed-size byte array to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_bytes(bytes32 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_bytes_array(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Get the actual size needed to encoding an unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(uint256 x, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    uint256 base = 0xff;
    uint256 realSize = sz;
    while (
      x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == 0 && realSize > 0
    ) {
      realSize -= 1;
    }
    if (realSize == 0) {
      realSize = 1;
    }
    return realSize;
  }

  /**
   * @dev Get the actual size needed to encoding an signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(int256 x, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    int256 base = 0xff;
    if (x >= 0) {
      uint256 tmp = _get_real_size(uint256(x), sz);
      int256 remainder = (x & (base << (tmp * BYTE_SIZE - BYTE_SIZE))) >>
        (tmp * BYTE_SIZE - BYTE_SIZE);
      if (remainder >= 128) {
        tmp += 1;
      }
      return tmp;
    }

    uint256 realSize = sz;
    while (
      x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) ==
      (base << (realSize * BYTE_SIZE - BYTE_SIZE)) &&
      realSize > 0
    ) {
      realSize -= 1;
    }
    int256 remainder = (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE))) >>
      (realSize * BYTE_SIZE - BYTE_SIZE);
    if (remainder < 128) {
      realSize += 1;
    }
    return realSize;
  }

  /**
   * @dev Encode the fixed-bytes array
   * @param x The fixed-size byte array to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_bytes_array(
    bytes32 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    /**
     * The idea is to not encode the leading bytes of zero.
     */
    uint256 actualSize = sz;
    for (uint256 i = 0; i < sz; i++) {
      uint8 current = uint8(x[sz - 1 - i]);
      if (current == 0 && actualSize > 1) {
        actualSize--;
      } else {
        break;
      }
    }
    assembly {
      let bsptr := add(bs, p)
      let count := actualSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(actualSize, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return actualSize;
  }

  /**
   * @dev Encode the signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(
    int256 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    /**
     * The idea is to not encode the leading bytes of zero.or one,
     * depending on whether it is positive.
     */
    uint256 realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }

  /**
   * @dev Encode the unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(
    uint256 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    uint256 realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;
import "./ProtoBufRuntime.sol";

library GoogleProtobufAny {


  //struct definition
  struct Data {
    string type_url;
    bytes value;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_type_url(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_value(pointer, bs, r, counters);
      }

      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_type_url(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.type_url = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_value(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.value = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;

    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.type_url, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.value, pointer, bs);
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.type_url).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.value.length);
    return e;
  }

  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.type_url = input.type_url;
    output.value = input.value;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Any

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;
import "./ProtoBufRuntime.sol";
import "./GoogleProtobufAny.sol";
import "./gogoproto/gogo.sol";

library Channel {

  //enum definition
  // Solidity enum definitions
  enum State {
    STATE_UNINITIALIZED_UNSPECIFIED,
    STATE_INIT,
    STATE_TRYOPEN,
    STATE_OPEN,
    STATE_CLOSED
  }


  // Solidity enum encoder
  function encode_State(State x) internal pure returns (int64) {
    
    if (x == State.STATE_UNINITIALIZED_UNSPECIFIED) {
      return 0;
    }

    if (x == State.STATE_INIT) {
      return 1;
    }

    if (x == State.STATE_TRYOPEN) {
      return 2;
    }

    if (x == State.STATE_OPEN) {
      return 3;
    }

    if (x == State.STATE_CLOSED) {
      return 4;
    }
    revert();
  }


  // Solidity enum decoder
  function decode_State(int64 x) internal pure returns (State) {
    
    if (x == 0) {
      return State.STATE_UNINITIALIZED_UNSPECIFIED;
    }

    if (x == 1) {
      return State.STATE_INIT;
    }

    if (x == 2) {
      return State.STATE_TRYOPEN;
    }

    if (x == 3) {
      return State.STATE_OPEN;
    }

    if (x == 4) {
      return State.STATE_CLOSED;
    }
    revert();
  }


  // Solidity enum definitions
  enum Order {
    ORDER_NONE_UNSPECIFIED,
    ORDER_UNORDERED,
    ORDER_ORDERED
  }


  // Solidity enum encoder
  function encode_Order(Order x) internal pure returns (int64) {
    
    if (x == Order.ORDER_NONE_UNSPECIFIED) {
      return 0;
    }

    if (x == Order.ORDER_UNORDERED) {
      return 1;
    }

    if (x == Order.ORDER_ORDERED) {
      return 2;
    }
    revert();
  }


  // Solidity enum decoder
  function decode_Order(int64 x) internal pure returns (Order) {
    
    if (x == 0) {
      return Order.ORDER_NONE_UNSPECIFIED;
    }

    if (x == 1) {
      return Order.ORDER_UNORDERED;
    }

    if (x == 2) {
      return Order.ORDER_ORDERED;
    }
    revert();
  }


  //struct definition
  struct Data {
    Channel.State state;
    Channel.Order ordering;
    ChannelCounterparty.Data counterparty;
    string[] connection_hops;
    string version;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[6] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_state(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_ordering(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_counterparty(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_connection_hops(pointer, bs, nil(), counters);
      }
      else if (fieldId == 5) {
        pointer += _read_version(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    pointer = offset;
    r.connection_hops = new string[](counters[4]);

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_state(pointer, bs, nil(), counters);
      }
      else if (fieldId == 2) {
        pointer += _read_ordering(pointer, bs, nil(), counters);
      }
      else if (fieldId == 3) {
        pointer += _read_counterparty(pointer, bs, nil(), counters);
      }
      else if (fieldId == 4) {
        pointer += _read_connection_hops(pointer, bs, r, counters);
      }
      else if (fieldId == 5) {
        pointer += _read_version(pointer, bs, nil(), counters);
      }
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_state(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[6] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    Channel.State x = decode_State(tmp);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.state = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_ordering(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[6] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    Channel.Order x = decode_Order(tmp);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.ordering = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_counterparty(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[6] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (ChannelCounterparty.Data memory x, uint256 sz) = _decode_ChannelCounterparty(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.counterparty = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_connection_hops(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[6] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.connection_hops[r.connection_hops.length - counters[4]] = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_version(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[6] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[5] += 1;
    } else {
      r.version = x;
      if (counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_ChannelCounterparty(uint256 p, bytes memory bs)
    internal
    pure
    returns (ChannelCounterparty.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (ChannelCounterparty.Data memory r, ) = ChannelCounterparty._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (uint(r.state) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int64 _enum_state = encode_State(r.state);
    pointer += ProtoBufRuntime._encode_enum(_enum_state, pointer, bs);
    }
    if (uint(r.ordering) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int64 _enum_ordering = encode_Order(r.ordering);
    pointer += ProtoBufRuntime._encode_enum(_enum_ordering, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ChannelCounterparty._encode_nested(r.counterparty, pointer, bs);
    
    if (r.connection_hops.length != 0) {
    for(i = 0; i < r.connection_hops.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        4,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += ProtoBufRuntime._encode_string(r.connection_hops[i], pointer, bs);
    }
    }
    if (bytes(r.version).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      5,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.version, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + ProtoBufRuntime._sz_enum(encode_State(r.state));
    e += 1 + ProtoBufRuntime._sz_enum(encode_Order(r.ordering));
    e += 1 + ProtoBufRuntime._sz_lendelim(ChannelCounterparty._estimate(r.counterparty));
    for(i = 0; i < r.connection_hops.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.connection_hops[i]).length);
    }
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.version).length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (uint(r.state) != 0) {
    return false;
  }

  if (uint(r.ordering) != 0) {
    return false;
  }

  if (r.connection_hops.length != 0) {
    return false;
  }

  if (bytes(r.version).length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.state = input.state;
    output.ordering = input.ordering;
    ChannelCounterparty.store(input.counterparty, output.counterparty);
    output.connection_hops = input.connection_hops;
    output.version = input.version;

  }


  //array helpers for ConnectionHops
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addConnectionHops(Data memory self, string memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    string[] memory tmp = new string[](self.connection_hops.length + 1);
    for (uint256 i = 0; i < self.connection_hops.length; i++) {
      tmp[i] = self.connection_hops[i];
    }
    tmp[self.connection_hops.length] = value;
    self.connection_hops = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Channel

library ChannelCounterparty {


  //struct definition
  struct Data {
    string port_id;
    string channel_id;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_port_id(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_channel_id(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_port_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.port_id = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_channel_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.channel_id = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (bytes(r.port_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.port_id, pointer, bs);
    }
    if (bytes(r.channel_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.channel_id, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.port_id).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.channel_id).length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (bytes(r.port_id).length != 0) {
    return false;
  }

  if (bytes(r.channel_id).length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.port_id = input.port_id;
    output.channel_id = input.channel_id;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library ChannelCounterparty

library ChannelIdentifiedChannel {


  //struct definition
  struct Data {
    Channel.State state;
    Channel.Order ordering;
    ChannelCounterparty.Data counterparty;
    string[] connection_hops;
    string version;
    string port_id;
    string channel_id;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[8] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_state(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_ordering(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_counterparty(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_connection_hops(pointer, bs, nil(), counters);
      }
      else if (fieldId == 5) {
        pointer += _read_version(pointer, bs, r, counters);
      }
      else if (fieldId == 6) {
        pointer += _read_port_id(pointer, bs, r, counters);
      }
      else if (fieldId == 7) {
        pointer += _read_channel_id(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    pointer = offset;
    r.connection_hops = new string[](counters[4]);

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_state(pointer, bs, nil(), counters);
      }
      else if (fieldId == 2) {
        pointer += _read_ordering(pointer, bs, nil(), counters);
      }
      else if (fieldId == 3) {
        pointer += _read_counterparty(pointer, bs, nil(), counters);
      }
      else if (fieldId == 4) {
        pointer += _read_connection_hops(pointer, bs, r, counters);
      }
      else if (fieldId == 5) {
        pointer += _read_version(pointer, bs, nil(), counters);
      }
      else if (fieldId == 6) {
        pointer += _read_port_id(pointer, bs, nil(), counters);
      }
      else if (fieldId == 7) {
        pointer += _read_channel_id(pointer, bs, nil(), counters);
      }
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_state(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    Channel.State x = Channel.decode_State(tmp);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.state = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_ordering(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    Channel.Order x = Channel.decode_Order(tmp);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.ordering = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_counterparty(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (ChannelCounterparty.Data memory x, uint256 sz) = _decode_ChannelCounterparty(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.counterparty = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_connection_hops(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.connection_hops[r.connection_hops.length - counters[4]] = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_version(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[5] += 1;
    } else {
      r.version = x;
      if (counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_port_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[6] += 1;
    } else {
      r.port_id = x;
      if (counters[6] > 0) counters[6] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_channel_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[8] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[7] += 1;
    } else {
      r.channel_id = x;
      if (counters[7] > 0) counters[7] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_ChannelCounterparty(uint256 p, bytes memory bs)
    internal
    pure
    returns (ChannelCounterparty.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (ChannelCounterparty.Data memory r, ) = ChannelCounterparty._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (uint(r.state) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int64 _enum_state = Channel.encode_State(r.state);
    pointer += ProtoBufRuntime._encode_enum(_enum_state, pointer, bs);
    }
    if (uint(r.ordering) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int64 _enum_ordering = Channel.encode_Order(r.ordering);
    pointer += ProtoBufRuntime._encode_enum(_enum_ordering, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ChannelCounterparty._encode_nested(r.counterparty, pointer, bs);
    
    if (r.connection_hops.length != 0) {
    for(i = 0; i < r.connection_hops.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        4,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += ProtoBufRuntime._encode_string(r.connection_hops[i], pointer, bs);
    }
    }
    if (bytes(r.version).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      5,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.version, pointer, bs);
    }
    if (bytes(r.port_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      6,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.port_id, pointer, bs);
    }
    if (bytes(r.channel_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      7,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.channel_id, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + ProtoBufRuntime._sz_enum(Channel.encode_State(r.state));
    e += 1 + ProtoBufRuntime._sz_enum(Channel.encode_Order(r.ordering));
    e += 1 + ProtoBufRuntime._sz_lendelim(ChannelCounterparty._estimate(r.counterparty));
    for(i = 0; i < r.connection_hops.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.connection_hops[i]).length);
    }
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.version).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.port_id).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.channel_id).length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (uint(r.state) != 0) {
    return false;
  }

  if (uint(r.ordering) != 0) {
    return false;
  }

  if (r.connection_hops.length != 0) {
    return false;
  }

  if (bytes(r.version).length != 0) {
    return false;
  }

  if (bytes(r.port_id).length != 0) {
    return false;
  }

  if (bytes(r.channel_id).length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.state = input.state;
    output.ordering = input.ordering;
    ChannelCounterparty.store(input.counterparty, output.counterparty);
    output.connection_hops = input.connection_hops;
    output.version = input.version;
    output.port_id = input.port_id;
    output.channel_id = input.channel_id;

  }


  //array helpers for ConnectionHops
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addConnectionHops(Data memory self, string memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    string[] memory tmp = new string[](self.connection_hops.length + 1);
    for (uint256 i = 0; i < self.connection_hops.length; i++) {
      tmp[i] = self.connection_hops[i];
    }
    tmp[self.connection_hops.length] = value;
    self.connection_hops = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library ChannelIdentifiedChannel

library Packet {


  //struct definition
  struct Data {
    uint64 sequence;
    string source_port;
    string source_channel;
    string destination_port;
    string destination_channel;
    bytes data;
    Height.Data timeout_height;
    uint64 timeout_timestamp;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[9] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_sequence(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_source_port(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_source_channel(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_destination_port(pointer, bs, r, counters);
      }
      else if (fieldId == 5) {
        pointer += _read_destination_channel(pointer, bs, r, counters);
      }
      else if (fieldId == 6) {
        pointer += _read_data(pointer, bs, r, counters);
      }
      else if (fieldId == 7) {
        pointer += _read_timeout_height(pointer, bs, r, counters);
      }
      else if (fieldId == 8) {
        pointer += _read_timeout_timestamp(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_sequence(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.sequence = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_source_port(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.source_port = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_source_channel(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.source_channel = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_destination_port(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.destination_port = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_destination_channel(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[5] += 1;
    } else {
      r.destination_channel = x;
      if (counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_data(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[6] += 1;
    } else {
      r.data = x;
      if (counters[6] > 0) counters[6] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_timeout_height(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Height.Data memory x, uint256 sz) = _decode_Height(p, bs);
    if (isNil(r)) {
      counters[7] += 1;
    } else {
      r.timeout_height = x;
      if (counters[7] > 0) counters[7] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_timeout_timestamp(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[9] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    if (isNil(r)) {
      counters[8] += 1;
    } else {
      r.timeout_timestamp = x;
      if (counters[8] > 0) counters[8] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Height(uint256 p, bytes memory bs)
    internal
    pure
    returns (Height.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Height.Data memory r, ) = Height._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (r.sequence != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.sequence, pointer, bs);
    }
    if (bytes(r.source_port).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.source_port, pointer, bs);
    }
    if (bytes(r.source_channel).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.source_channel, pointer, bs);
    }
    if (bytes(r.destination_port).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.destination_port, pointer, bs);
    }
    if (bytes(r.destination_channel).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      5,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.destination_channel, pointer, bs);
    }
    if (r.data.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      6,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.data, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      7,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Height._encode_nested(r.timeout_height, pointer, bs);
    
    if (r.timeout_timestamp != 0) {
    pointer += ProtoBufRuntime._encode_key(
      8,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.timeout_timestamp, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_uint64(r.sequence);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.source_port).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.source_channel).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.destination_port).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.destination_channel).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.data.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(Height._estimate(r.timeout_height));
    e += 1 + ProtoBufRuntime._sz_uint64(r.timeout_timestamp);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.sequence != 0) {
    return false;
  }

  if (bytes(r.source_port).length != 0) {
    return false;
  }

  if (bytes(r.source_channel).length != 0) {
    return false;
  }

  if (bytes(r.destination_port).length != 0) {
    return false;
  }

  if (bytes(r.destination_channel).length != 0) {
    return false;
  }

  if (r.data.length != 0) {
    return false;
  }

  if (r.timeout_timestamp != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.sequence = input.sequence;
    output.source_port = input.source_port;
    output.source_channel = input.source_channel;
    output.destination_port = input.destination_port;
    output.destination_channel = input.destination_channel;
    output.data = input.data;
    Height.store(input.timeout_height, output.timeout_height);
    output.timeout_timestamp = input.timeout_timestamp;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Packet

library PacketState {


  //struct definition
  struct Data {
    string port_id;
    string channel_id;
    uint64 sequence;
    bytes data;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[5] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_port_id(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_channel_id(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_sequence(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_data(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_port_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.port_id = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_channel_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.channel_id = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_sequence(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.sequence = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_data(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.data = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (bytes(r.port_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.port_id, pointer, bs);
    }
    if (bytes(r.channel_id).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.channel_id, pointer, bs);
    }
    if (r.sequence != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.sequence, pointer, bs);
    }
    if (r.data.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.data, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.port_id).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.channel_id).length);
    e += 1 + ProtoBufRuntime._sz_uint64(r.sequence);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.data.length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (bytes(r.port_id).length != 0) {
    return false;
  }

  if (bytes(r.channel_id).length != 0) {
    return false;
  }

  if (r.sequence != 0) {
    return false;
  }

  if (r.data.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.port_id = input.port_id;
    output.channel_id = input.channel_id;
    output.sequence = input.sequence;
    output.data = input.data;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library PacketState

library Height {


  //struct definition
  struct Data {
    uint64 revision_number;
    uint64 revision_height;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_revision_number(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_revision_height(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_revision_number(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.revision_number = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_revision_height(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.revision_height = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (r.revision_number != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.revision_number, pointer, bs);
    }
    if (r.revision_height != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.revision_height, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_uint64(r.revision_number);
    e += 1 + ProtoBufRuntime._sz_uint64(r.revision_height);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.revision_number != 0) {
    return false;
  }

  if (r.revision_height != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.revision_number = input.revision_number;
    output.revision_height = input.revision_height;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Height

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;
import "@hyperledger-labs/yui-ibc-solidity/contracts/core/types/ProtoBufRuntime.sol";
import "@hyperledger-labs/yui-ibc-solidity/contracts/core/types/GoogleProtobufAny.sol";
import "@hyperledger-labs/yui-ibc-solidity/contracts/core/types/gogoproto/gogo.sol";

library Account {


  //struct definition
  struct Data {
    bytes id;
    AuthType.Data auth_type;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_id(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_auth_type(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_id(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.id = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_auth_type(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (AuthType.Data memory x, uint256 sz) = _decode_AuthType(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.auth_type = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_AuthType(uint256 p, bytes memory bs)
    internal
    pure
    returns (AuthType.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (AuthType.Data memory r, ) = AuthType._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (r.id.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.id, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += AuthType._encode_nested(r.auth_type, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(r.id.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(AuthType._estimate(r.auth_type));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.id.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.id = input.id;
    AuthType.store(input.auth_type, output.auth_type);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Account

library AuthType {

  //enum definition
  // Solidity enum definitions
  enum AuthMode {
    AUTH_MODE_UNSPECIFIED,
    AUTH_MODE_LOCAL,
    AUTH_MODE_CHANNEL,
    AUTH_MODE_EXTENSION
  }


  // Solidity enum encoder
  function encode_AuthMode(AuthMode x) internal pure returns (int32) {
    
    if (x == AuthMode.AUTH_MODE_UNSPECIFIED) {
      return 0;
    }

    if (x == AuthMode.AUTH_MODE_LOCAL) {
      return 1;
    }

    if (x == AuthMode.AUTH_MODE_CHANNEL) {
      return 2;
    }

    if (x == AuthMode.AUTH_MODE_EXTENSION) {
      return 3;
    }
    revert();
  }


  // Solidity enum decoder
  function decode_AuthMode(int64 x) internal pure returns (AuthMode) {
    
    if (x == 0) {
      return AuthMode.AUTH_MODE_UNSPECIFIED;
    }

    if (x == 1) {
      return AuthMode.AUTH_MODE_LOCAL;
    }

    if (x == 2) {
      return AuthMode.AUTH_MODE_CHANNEL;
    }

    if (x == 3) {
      return AuthMode.AUTH_MODE_EXTENSION;
    }
    revert();
  }


  //struct definition
  struct Data {
    AuthType.AuthMode mode;
    GoogleProtobufAny.Data option;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_mode(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_option(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_mode(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    AuthType.AuthMode x = decode_AuthMode(tmp);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.mode = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_option(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (GoogleProtobufAny.Data memory x, uint256 sz) = _decode_GoogleProtobufAny(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.option = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_GoogleProtobufAny(uint256 p, bytes memory bs)
    internal
    pure
    returns (GoogleProtobufAny.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (GoogleProtobufAny.Data memory r, ) = GoogleProtobufAny._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (uint(r.mode) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_mode = encode_AuthMode(r.mode);
    pointer += ProtoBufRuntime._encode_enum(_enum_mode, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += GoogleProtobufAny._encode_nested(r.option, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_enum(encode_AuthMode(r.mode));
    e += 1 + ProtoBufRuntime._sz_lendelim(GoogleProtobufAny._estimate(r.option));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (uint(r.mode) != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.mode = input.mode;
    GoogleProtobufAny.store(input.option, output.option);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library AuthType

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/types/Channel.sol";

// PacketHandler is a handler that handles a packet and acknowledgement
abstract contract PacketHandler {
    function handlePacket(Packet.Data memory packet) virtual internal returns (bytes memory acknowledgement);
    function handleAcknowledgement(Packet.Data memory packet, bytes memory acknowledgement) virtual internal;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./PacketHandler.sol";
import "./types/Auth.sol";

// IContractModule defines the expected interface of a contract module on Cross Framework
interface IContractModule {
    // onContractCall is a callback function that is called at the commit(simple-commit) phase
    function onContractCall(CrossContext calldata context, bytes calldata callInfo) external returns (bytes memory);

    // // onContractPrepare is a callback function that is called at the prepare(2pc) phase
    // function onContractPrepare(CrossContext calldata context, bytes calldata callInfo) external returns (bytes memory);

    // // onCommit is a callback function that is called at the commit(2pc) phase
    // // It is expected that it commits the changes in the contract module
    // function onCommit(CrossContext calldata context) external;

    // // onAbort is a callback function that is called at the commit(2pc) phase
    // // It is expected that it aborts the changes in the contract module
    // function onAbort(CrossContext calldata context) external;
}

// CrossContext is a context in cross-chain transaction
struct CrossContext {
    bytes tx_id;
    uint8 tx_index;
    Account.Data[] signers;
}