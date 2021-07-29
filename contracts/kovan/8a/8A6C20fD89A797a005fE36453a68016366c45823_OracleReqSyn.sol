// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../vendor/BufferChainlink.sol";
import "../vendor/CBORChainlink.sol";


contract OracleReqSyn {
  using SafeMath for uint256;
  using CBORChainlink for BufferChainlink.buffer;

  uint256 constant private ARGS_VERSION = 1;
  uint256 private nonce;
  
  bytes32 public callBackRequestId;
  uint256 public fulfillData;

  mapping(address => uint256) public userWallet;

  event SynWallet(address indexed user, uint256 indexed chainID, uint256 amount);
  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes memory _data
  )
    private
  {
    bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
    uint256 expiration = now.add(5 minutes);

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      _dataVersion,
      _data);
  }

  function reqSynWallet(string memory _specId, uint256 _amount) external {
    BufferChainlink.buffer memory data;
    data = BufferChainlink.init(data, 256);
    data.encodeString("amount");
    data.encodeUInt(_amount);

    oracleRequest(msg.sender, 0, stringToBytes32(_specId), address(this), this.fulfill.selector, nonce, ARGS_VERSION,  data.buf);
    
    nonce.add(1);
  }
  function fulfill(bytes32 _requestId, uint256 _data) external {
    callBackRequestId = _requestId;
    fulfillData = _data;
  }
  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
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
      resize(buf, (len + off) * 2);
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.19;

import { BufferChainlink } from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeType(
    BufferChainlink.buffer memory buf,
    uint8 major,
    uint value
  )
    private
    pure
  {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(
    BufferChainlink.buffer memory buf,
    uint8 major
  )
    private
    pure
  {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(
    BufferChainlink.buffer memory buf,
    uint value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(
    BufferChainlink.buffer memory buf,
    bytes memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeBigNum(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(value)));
  }

  function encodeSignedBigNum(
    BufferChainlink.buffer memory buf,
    int input
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(-1 - input)));
  }

  function encodeString(
    BufferChainlink.buffer memory buf,
    string memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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