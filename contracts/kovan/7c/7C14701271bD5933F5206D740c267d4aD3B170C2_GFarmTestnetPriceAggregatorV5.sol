/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// File: node_modules\@chainlink\contracts\src\v0.8\vendor\BufferChainlink.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function init(
    buffer memory buf,
    uint capacity
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function fromBytes(
    bytes memory b
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(
    buffer memory buf,
    uint capacity
  )
    private
    pure
  {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(
    uint a,
    uint b
  )
    private
    pure
    returns(
      uint
    )
  {
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
  function truncate(
    buffer memory buf
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function write(
    buffer memory buf,
    uint off,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function append(
    buffer memory buf,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function writeUint8(
    buffer memory buf,
    uint off,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function appendUint8(
    buffer memory buf,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function write(
    buffer memory buf,
    uint off,
    bytes32 data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
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
  function writeBytes20(
    buffer memory buf,
    uint off,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(
    buffer memory buf,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(
    buffer memory buf,
    bytes32 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function writeInt(
    buffer memory buf,
    uint off,
    uint data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
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
  function appendInt(
    buffer memory buf,
    uint data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// File: node_modules\@chainlink\contracts\src\v0.8\vendor\CBORChainlink.sol

pragma solidity >= 0.4.19;


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

// File: node_modules\@chainlink\contracts\src\v0.8\Chainlink.sol

pragma solidity ^0.8.0;



/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(
    Request memory self,
    bytes memory data
  )
    internal
    pure
  {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\ENSInterface.sol

pragma solidity ^0.8.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(
    bytes32 indexed node,
    address owner
  );

  // Logged when the resolver for a node changes.
  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  // Logged when the TTL of a node changes
  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );


  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(
    bytes32 node,
    address resolver
  ) external;

  function setOwner(
    bytes32 node,
    address owner
  ) external;

  function setTTL(
    bytes32 node,
    uint64 ttl
  ) external;

  function owner(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function resolver(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function ttl(
    bytes32 node
  )
    external
    view
    returns (
      uint64
    );

}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\LinkTokenInterface.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\OracleInterface.sol

pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    returns (
      bool
    );

  function isAuthorizedSender(
    address node
  )
    external
    view
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\ChainlinkRequestInterface.sol

pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\OperatorInterface.sol

pragma solidity ^0.8.0;



interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function distributeFunds(
    address payable[] calldata receivers,
    uint[] calldata amounts
  )
    external
    payable;

  function getAuthorizedSenders()
    external
    returns (
      address[] memory
    );

  function setAuthorizedSenders(
    address[] calldata senders
  ) external;

  function getForwarder()
    external
    returns (
      address
    );
}

// File: node_modules\@chainlink\contracts\src\v0.8\interfaces\PointerInterface.sol

pragma solidity ^0.8.0;

interface PointerInterface {
  
  function getAddress()
    external
    view
    returns (
      address
    );
}

// File: node_modules\@chainlink\contracts\src\v0.8\vendor\ENSResolver.sol

pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(
    bytes32 node
  )
    public
    view
    virtual
    returns (
      address
    );
}

// File: @chainlink\contracts\src\v0.8\ChainlinkClient.sol

pragma solidity ^0.8.0;







/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK_DIVISIBILITY = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ORACLE_ARGS_VERSION = 1;
  uint256 constant private OPERATOR_ARGS_VERSION = 2;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  OperatorInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(
    bytes32 indexed id
  );
  event ChainlinkFulfilled(
    bytes32 indexed id
  );
  event ChainlinkCancelled(
    bytes32 indexed id
  );

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddress The callback address that the response will be sent to
   * @param callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionSignature
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddress, callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return sendChainlinkRequestTo(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, ORACLE_ARGS_VERSION, oracle.oracleRequest.selector);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `requestOracleDataFrom` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleData(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return requestOracleDataFrom(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleDataFrom(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, OPERATOR_ARGS_VERSION, oracle.requestOracleData.selector);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @param argsVersion The version of data support (single word, multi word)
   * @return requestId The request ID
   */
  function rawRequest(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment,
    uint256 argsVersion,
    bytes4 funcSelector
  )
    private
    returns (
      bytes32 requestId
    )
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    req.nonce = requestCount;
    pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    bytes memory encodedData = abi.encodeWithSelector(
      funcSelector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress,
      req.callbackFunctionId,
      req.nonce,
      argsVersion,
      req.buf.buf);
    require(link.transferAndCall(oracleAddress, payment, encodedData), "unable to transferAndCall to oracle");
    requestCount += 1;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    internal
  {
    OperatorInterface requested = OperatorInterface(pendingRequests[requestId]);
    delete pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(
    address oracleAddress
  )
    internal
  {
    oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(
    address linkAddress
  )
    internal
  {
    link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() 
    internal
  {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(
    address oracleAddress,
    bytes32 requestId
  )
    internal
    notPendingRequest(requestId)
  {
    pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(
    bytes32 requestId
  )
    internal
    recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(
    bytes32 requestId
  )
  {
    require(msg.sender == pendingRequests[requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(
    bytes32 requestId
  )
  {
    require(pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// File: contracts\interfaces\CallbacksInterfaceV5.sol

pragma solidity 0.8.7;

interface CallbacksInterfaceV5{
    struct AggregatorAnswer{
        uint order;
        uint price;
        uint spreadP;
    }
    function openTradeMarketCallback(AggregatorAnswer memory) external;
    function closeTradeMarketCallback(AggregatorAnswer memory) external;
    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;
    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;
}

// File: contracts\interfaces\ChainlinkFeedInterfaceV5.sol

pragma solidity 0.8.7;

interface ChainlinkFeedInterfaceV5{
    function latestRoundData() external view returns (uint80,int,uint,uint,uint80);
}

// File: contracts\interfaces\LpInterfaceV5.sol

pragma solidity 0.8.7;

interface LpInterfaceV5{
   	function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint256) external returns (bool);
}

// File: contracts\interfaces\UniswapRouterInterfaceV5.sol

pragma solidity 0.8.7;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// File: contracts\interfaces\AggregatorInterfaceV5.sol

pragma solidity 0.8.7;

interface AggregatorInterfaceV5{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE }
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function pairMinOpenLimitSlippageP(uint) external view returns(uint);
    function closeFeeP(uint) external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function pairsCount() external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function referralP(uint) external view returns(uint);
    function nftLimitOrderFeeP(uint) external view returns(uint);
}

// File: contracts\interfaces\TokenInterfaceV5.sol

pragma solidity 0.8.7;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\interfaces\NftInterfaceV5.sol

pragma solidity 0.8.7;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterfaceV5.sol

pragma solidity 0.8.7;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
}

// File: contracts\interfaces\StorageInterfaceV5.sol

pragma solidity 0.8.7;






interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV5);
    function vault() external view returns(VaultInterfaceV5);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
}

// File: contracts\interfaces\PausableInterfaceV5.sol

pragma solidity 0.8.7;

interface PausableInterfaceV5{
    function isPaused() external view returns (bool);
}

// File: contracts\GFarmTestnetPriceAggregatorV5.sol







pragma solidity 0.8.7;

contract GFarmTestnetPriceAggregatorV5 is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    // Constants
    uint constant MAX_ORACLE_NODES = 20;

    // Trading storage contract
    StorageInterfaceV5 public tradingStorage;

    // LPs => link & token price
    LpInterfaceV5 public tokenDaiLp;
    uint public linkPriceDai = 20 * 1e10;   // PRECISION

    // Enums
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE }
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)

    // Variables
    uint public currentOrder;
    uint public pairsCount;
    uint public minAnswers = 1;

    // Structs
    struct Feed{
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint maxDeviation;                  // PRECISION (%)
    }
    struct Pair{
        string from;
        string to;
        bytes32[MAX_ORACLE_NODES] jobs;     // node index => job
        uint spreadP;                       // PRECISION
        Feed feed;
        uint minLeverage;
        uint maxLeverage;
        uint minOpenLimitSlippageP;         // PRECISION (%) 
        uint openFeeP;                      // PRECISION (% of leveraged pos)
        uint closeFeeP;                     // PRECISION (% of leveraged pos)
        uint oracleFeeP;                    // PRECISION (% of leveraged pos)
        uint nftLimitOrderFeeP;             // PRECISION (%) => leveraged pos
        uint referralP;                     // PRECISION (%) => leveraged pos
    }
    struct Request{
        uint orderId;
        OrderType orderType;
        uint pairIndex;
        bool initiated;
        uint linkFee;
    }

    // Arrays & mappings
    mapping(bytes32 => Request) public requests;
    mapping(uint => uint[]) public orderAnswers;
    mapping(uint => Pair) public pairs;
    mapping(string => mapping(string => bool)) public isPairListed;
    address[] public nodes;

    // Events
    event PriceReceived(
        bytes32 request,
        uint order,
        address node,
        uint pairIndex,
        uint price,
        uint referencePrice,
        uint linkFee
    );
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);
    event PairAdded(string from, string to);
    event NodeAdded(uint index, address a);
    event NodeReplaced(uint index, address old, address newA);
    event NumberUpdatedPair(string name, uint pairIndex, uint value);
    event JobUpdatedPair(uint pairIndex, uint jobIndex, bytes32 value);
    event JobUpdatedPairs(uint fromPairIndex, uint toPairIndex, uint jobIndex, bytes32 value);
    event FeedUpdatedPair(uint pairIndex, Feed feed);

    constructor(
        StorageInterfaceV5 _tradingStorage,
        LpInterfaceV5 _tokenDaiLp
    ){
        require(address(_tradingStorage) != address(0));
        tradingStorage = _tradingStorage;
        setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
        tokenDaiLp = _tokenDaiLp;
    }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == tradingStorage.gov(), "GOV_ONLY"); _; }
    modifier onlyTrading(){ require(msg.sender == tradingStorage.trading(), "TRADING_ONLY"); _; }
    modifier pairListed(uint _pairIndex){ require(isPairListed[pairs[_pairIndex].from][pairs[_pairIndex].to], "PAIR_NOT_LISTED"); _; }

    // Manage trading storage address
    // CAREFUL: IF ADDRESS WRONG, CONTRACT CAN BE STUCK
    function setTradingStorage(StorageInterfaceV5 _tradingStorage) external onlyGov{
        require(_tradingStorage.gov() == tradingStorage.gov());
        tradingStorage = _tradingStorage;
        emit AddressUpdated("tradingStorage", address(_tradingStorage));
    }
    // Update token/dai LP address
    function updateTokenDaiLp(LpInterfaceV5 _lp) external onlyGov{
        require(address(_lp) != address(0), "ADDRESS_0");
        require(PausableInterfaceV5(tradingStorage.trading()).isPaused()
        && PausableInterfaceV5(tradingStorage.callbacks()).isPaused(), "NOT_PAUSED");
        tokenDaiLp = _lp;
        emit AddressUpdated("tokenDaiLp", address(_lp));
    }
    // Update link price (used for oracle fee distribution to chainlink nodes)
    function updateLinkPriceDai(uint _newPrice) external onlyGov{
        require(_newPrice > 0);
        linkPriceDai = _newPrice;
        emit NumberUpdated("linkPriceDai", _newPrice);
    }

    // Manage nodes
    function addNode(address _a) external onlyGov{
        require(_a != address(0), "ADDRESS_0");
        require(nodes.length < MAX_ORACLE_NODES, "MAX_ORACLE_NODES");
        //for(uint i = 0; i < nodes.length; i++){ require(nodes[i] != _a, "ALREADY_LISTED"); }
        nodes.push(_a);
        emit NodeAdded(nodes.length-1, _a);
    }
    // Don't forget to replace his job ids in every pair
    function replaceNode(uint _index, address _a) external onlyGov{
        require(_index < nodes.length, "WRONG_INDEX");
        require(_a != address(0), "ADDRESS_0");
        emit NodeReplaced(_index, nodes[_index], _a);
        nodes[_index] = _a;
    }
    // Number of oracle answers to take the median
    function setMinAnswers(uint _minAnswers) external onlyGov{
        //require(_minAnswers >= 3);
        minAnswers = _minAnswers;
        emit NumberUpdated("minAnswers", _minAnswers);
    }

    // Manage trading pairs
    function addPair(Pair calldata _pair) external onlyGov{
        require(_pair.jobs[0] != bytes32(0), "JOBS_EMPTY");
        require(_pair.feed.maxDeviation > 0 && address(_pair.feed.feed1) != address(0), "WRONG_FEED");
        require(_pair.feed.feedCalculation != FeedCalculation.COMBINE || address(_pair.feed.feed2) != address(0), "FEED_2_MISSING");
        require(_pair.minLeverage > 0 && _pair.maxLeverage <= 1000 && _pair.minLeverage < _pair.maxLeverage, "WRONG_LEVERAGES");
        require(_pair.minOpenLimitSlippageP > 0 && _pair.oracleFeeP > 0 && _pair.nftLimitOrderFeeP > 0 && _pair.referralP > 0, "WRONG_FEES");
        require(!isPairListed[_pair.from][_pair.to], "ALREADY_LISTED");

        pairs[pairsCount] = _pair;
        isPairListed[_pair.from][_pair.to] = true;
        pairsCount++;

        emit PairAdded(_pair.from, _pair.to);
    }
    function updateSpread(uint _pairIndex, uint _spreadP) external onlyGov pairListed(_pairIndex){
        pairs[_pairIndex].spreadP = _spreadP;
        emit NumberUpdatedPair("spreadP", _pairIndex, _spreadP);
    }
    function updateJob(uint _pairIndex, uint _jobIndex, bytes32 _newJob) external onlyGov pairListed(_pairIndex){
        pairs[_pairIndex].jobs[_jobIndex] = _newJob;
        emit JobUpdatedPair(_pairIndex, _jobIndex, _newJob);
    }
    function updateJobs(uint _fromPairIndex, uint _toPairIndex, uint _jobIndex, bytes32 _newJob) external onlyGov{
        require(_fromPairIndex < _toPairIndex && _toPairIndex < pairsCount);
        for(uint i = _fromPairIndex; i <= _toPairIndex; i++){
            pairs[i].jobs[_jobIndex] = _newJob;
        }
        emit JobUpdatedPairs(_fromPairIndex, _toPairIndex, _jobIndex, _newJob);
    }
    function updateFeed(uint _pairIndex, Feed calldata _feed) external onlyGov pairListed(_pairIndex){
        require(_feed.maxDeviation > 0 && _feed.feed1 != address(0), "WRONG_FEED");
        require(_feed.feedCalculation != FeedCalculation.COMBINE || _feed.feed2 != address(0), "FEED_2_MISSING");
        pairs[_pairIndex].feed = _feed;
        emit FeedUpdatedPair(_pairIndex, pairs[_pairIndex].feed);
    }
    function updateMinMaxLeverage(uint _pairIndex, uint _min, uint _max) external onlyGov pairListed(_pairIndex){
        require(_min > 0 && _max <= 1000 && _min < _max);
        pairs[_pairIndex].minLeverage = _min;
        pairs[_pairIndex].maxLeverage = _max;
        emit NumberUpdatedPair("minLeverage", _pairIndex, _min);
        emit NumberUpdatedPair("maxLeverage", _pairIndex, _max);
    }
    function updateMinOpenLimitSlippageP(uint _pairIndex, uint _min) external onlyGov pairListed(_pairIndex){
        require(_min > 0);
        pairs[_pairIndex].minOpenLimitSlippageP = _min;
        emit NumberUpdatedPair("minOpenLimitSlippageP", _pairIndex, _min);
    }
    function updateOpenFeeP(uint _pairIndex, uint _openFeeP) external onlyGov pairListed(_pairIndex){
        pairs[_pairIndex].openFeeP = _openFeeP;
        emit NumberUpdatedPair("openFeeP", _pairIndex, _openFeeP);
    }
    function updateCloseFeeP(uint _pairIndex, uint _closeFeeP) external onlyGov pairListed(_pairIndex){
        pairs[_pairIndex].closeFeeP = _closeFeeP;
        emit NumberUpdatedPair("closeFeeP", _pairIndex, _closeFeeP);
    }
    function updateOracleFeeP(uint _pairIndex, uint _fee) external onlyGov pairListed(_pairIndex){
        require(_fee > 0);
        pairs[_pairIndex].oracleFeeP = _fee;
        emit NumberUpdatedPair("oracleFeeP", _pairIndex, _fee);
    }
    function updateReferralP(uint _pairIndex, uint _fee) external onlyGov pairListed(_pairIndex){
        require(_fee > 0);
        pairs[_pairIndex].referralP = _fee;
        emit NumberUpdatedPair("referralP", _pairIndex, _fee);
    }
    function updateNftLimitOrderFeeP(uint _pairIndex, uint _fee) external onlyGov pairListed(_pairIndex){
        require(_fee > 0);
        pairs[_pairIndex].nftLimitOrderFeeP = _fee;
        emit NumberUpdatedPair("nftLimitOrderFeeP", _pairIndex, _fee);
    }

    // Median function
    function swap(uint[] memory array, uint i, uint j) private pure { (array[i], array[j]) = (array[j], array[i]); }
    function sort(uint[] memory array, uint begin, uint end) private pure {
        if (begin >= end) { return; }
        uint j = begin;
        uint pivot = array[j];
        for (uint i = begin + 1; i < end; ++i) {
            if (array[i] < pivot) {
                swap(array, i, ++j);
            }
        }
        swap(array, begin, j);
        sort(array, begin, j);
        sort(array, j + 1, end);
    }
    function median(uint[] memory array) private pure returns(uint) {
        sort(array, 0, array.length);
        return array.length % 2 == 0 ? (array[array.length/2-1]+array[array.length/2])/2 : array[array.length/2];
    }

    // On-demand price request to oracles network
    function getPrice(
        uint _pairIndex,
        OrderType _orderType,
        uint _leveragedPosDai
    ) external onlyTrading returns(uint){

        // => if pair not listed, max leverage = 0 => can't open

        require(nodes.length >= 5, "5_NODES_NOT_LISTED");
        uint linkPerNode = linkFee(_pairIndex, _leveragedPosDai) / nodes.length;

        Pair storage p = pairs[_pairIndex];

        for(uint i = 0; i < nodes.length; i ++){
            if(p.jobs[i] == bytes32(0)){ continue; }

            Chainlink.Request memory request = buildChainlinkRequest(p.jobs[i], address(this), this.fulfill.selector);
            request.add("from", p.from);
            request.add("to", p.to);
            request.add("copyPath", "result");
            request.addInt("times", int(tradingStorage.PRECISION()));
            bytes32 requestId = sendChainlinkRequestTo(nodes[i], request, linkPerNode);
            requests[requestId] = Request(currentOrder, _orderType, _pairIndex, true, linkPerNode);
        }
        return currentOrder++;
    }

    function fulfill(bytes32 _requestId, uint _price) external recordChainlinkFulfillment(_requestId){
        require(requests[_requestId].initiated, "REQUEST_DONE");

        Request storage r = requests[_requestId];
        uint[] storage answers = orderAnswers[r.orderId];
        Pair storage p = pairs[r.pairIndex];
        Feed storage f = p.feed;
        
        int calculatedFeedPrice;

        (, int feedPrice1, , , ) = ChainlinkFeedInterfaceV5(f.feed1).latestRoundData();

        if(f.feedCalculation == FeedCalculation.DEFAULT){
            calculatedFeedPrice = feedPrice1;
        }else if(f.feedCalculation == FeedCalculation.INVERT){
            calculatedFeedPrice = 1e16/feedPrice1;
        }else{
            (, int feedPrice2, , , ) = ChainlinkFeedInterfaceV5(f.feed2).latestRoundData();
            calculatedFeedPrice = feedPrice1*1e8/feedPrice2;
        }

        uint _feedPrice = uint(calculatedFeedPrice*1e2); // int 1e8 => uint 1e10 tradingStorage.PRECISION()
        emit PriceReceived(_requestId, r.orderId, msg.sender, r.pairIndex, _price, _feedPrice, r.linkFee);

        if(_price == 0
        || _price >= _feedPrice && (_price-_feedPrice)*tradingStorage.PRECISION()*100/_feedPrice <= f.maxDeviation
        || _price < _feedPrice && (_feedPrice-_price)*tradingStorage.PRECISION()*100/_feedPrice <= f.maxDeviation){

            answers.push(_price);

            if(answers.length == minAnswers){

                CallbacksInterfaceV5.AggregatorAnswer memory a = CallbacksInterfaceV5.AggregatorAnswer(
                    r.orderId,
                    median(answers),
                    p.spreadP
                );

                CallbacksInterfaceV5 c = CallbacksInterfaceV5(tradingStorage.callbacks());

                if(r.orderType == OrderType.MARKET_OPEN){
                    c.openTradeMarketCallback(a);
                }else if(r.orderType == OrderType.MARKET_CLOSE){
                    c.closeTradeMarketCallback(a);
                }else if(r.orderType == OrderType.LIMIT_OPEN){
                    c.executeNftOpenOrderCallback(a);
                }else{
                    c.executeNftCloseOrderCallback(a);
                }
            }

            if(answers.length == nodes.length){ delete orderAnswers[r.orderId]; }
        }

        delete requests[_requestId];
    }

    // Claim back LINK tokens (if contract will be replaced for example)
    function claimBackLink() external onlyGov{
        TokenInterfaceV5 link = tradingStorage.linkErc677();
        link.transfer(tradingStorage.gov(), link.balanceOf(address(this)));
    }

    // Utils
    function linkFee(uint _pairIndex, uint _leveragedPosDai) public view returns(uint){
        return pairs[_pairIndex].oracleFeeP * _leveragedPosDai / linkPriceDai / 100;
    }
    function tokenDaiReservesLp() public view returns(uint, uint){
        (uint112 reserves0, uint112 reserves1, ) = tokenDaiLp.getReserves();
        return tokenDaiLp.token0() == address(tradingStorage.token()) ? (reserves0, reserves1) : (reserves1, reserves0);
    }
    function tokenPriceDai() external view returns(uint){
        (uint reserveToken, uint reserveDai) = tokenDaiReservesLp();
        return reserveDai * tradingStorage.PRECISION() / reserveToken;
    }

    // Useful getters
    function oracleNodesCount() external view returns(uint){
        return nodes.length;
    }
    function pairJobs(uint _pairIndex) external view returns(bytes32[MAX_ORACLE_NODES] memory){ 
        return pairs[_pairIndex].jobs; 
    }
    function pairFeed(uint _pairIndex) external view returns(Feed memory){ 
        return pairs[_pairIndex].feed; 
    }
    function openFeeP(uint _pairIndex) external view returns(uint){ 
        return pairs[_pairIndex].openFeeP; 
    }
    function closeFeeP(uint _pairIndex) external view returns(uint){ 
        return pairs[_pairIndex].closeFeeP; 
    }
    function oracleFeeP(uint _pairIndex) external view returns(uint){ 
        return pairs[_pairIndex].oracleFeeP; 
    }
    function referralP(uint _pairIndex) external view returns(uint){ 
        return pairs[_pairIndex].referralP; 
    }
    function nftLimitOrderFeeP(uint _pairIndex) external view returns(uint){ 
        return pairs[_pairIndex].nftLimitOrderFeeP; 
    }
    function pairMinLeverage(uint _pairIndex) external view returns(uint){
        return pairs[_pairIndex].minLeverage;
    }
    function pairMaxLeverage(uint _pairIndex) external view returns(uint){
        return pairs[_pairIndex].maxLeverage;
    }
    function pairMinOpenLimitSlippageP(uint _pairIndex) external view returns(uint){
        return pairs[_pairIndex].minOpenLimitSlippageP;
    }
}