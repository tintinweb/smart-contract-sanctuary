// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CBORChainlink } from "./vendor/CBORChainlink.sol";
import { BufferChainlink } from "./vendor/BufferChainlink.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";

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
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(
    address ensAddress,
    bytes32 node
  )
    internal
  {
    ens = ENSInterface(ensAddress);
    ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  
  function getAddress()
    external
    view
    returns (
      address
    );
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
 * @title ERC20 interface to allow withdraw to accounts
 * @author Eric Nordelo
 */
interface IWithdrawable {
    /**
     * @dev transfer the amount of selected tokens to address
     */
    function withdrawTo(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenFunding {
    address appTokenAddress;
    address insuranceAddress;
    address stakeTokenAddress;
    address scopeTokenAddress;
}

struct TokenFundingData {
    address appToken;
    uint256 rMin;
    uint256 rMax;
    uint128 t; // unlock time for stake tokens (app tokens)
    uint128 maturity; // maturity time for scope tokens
    address[] owners;
    FundingScopeRoundsData[] fundingScopeRoundsData;
    FundingStakeRoundsData[] fundingStakeRoundsData;
}

struct FundingStakeRoundsData {
    uint64 openingTime;
    uint64 durationTime;
    uint128 stakeReward; // value between 0 and REWARD_PRECISION (1000)
    uint256 capTokensToBeStaked;
    uint256 stakedTokens;
}

struct FundingScopeRoundsData {
    uint64 openingTime;
    uint64 durationTime;
    uint128 discount; // value between 0 and DISCOUNT_PRECISION (1000)
    uint256 capTokensToBeSold;
    uint256 mintedTokens;
}

struct WithdrawProposal {
    uint128 positiveVotesCount;
    uint128 negativeVotesCount;
    address recipient;
    uint64 minApprovals;
    uint64 maxDenials;
    uint64 date;
    uint64 duration;
    uint256 amount;
    uint256 tokenFundingId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./implementations/ScopeToken.sol";
import "./implementations/StakeToken.sol";
import "./implementations/Insurance.sol";
import "./implementations/ProjectInfo.sol";
import "./oracles/OracleStructs.sol";
import "./oracles/SPOracle.sol";

/**
 * @title token funding contracts deployer and manager
 * @author Eric Nordelo
 */
contract TokenFundingManager is AccessControl, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenFundingIds;

    uint256 private constant PRECISION = 1000000;
    bytes32 private constant PRICE_ORACLE = keccak256("PRICE_ORACLE");
    bytes32 private constant ADMIN = keccak256("ADMIN");

    address public immutable withdrawManagerAddress;
    address public immutable insuranceImplementationAddress;
    address public immutable scopeTokenImplementationAddress;
    address public immutable stakeTokenImplementationAddress;
    address public immutable priceOracleImplementationAddress;
    address public immutable projectInfoImplementationAddress;

    mapping(uint256 => TokenFunding) private _tokenFundings;
    mapping(uint256 => address[]) private _tokenFundingsOwners;

    event CreateTokenFunding(
        uint256 id,
        address insuranceAddress,
        address stakeTokenAddress,
        address scopeTokenAddress,
        address priceOracleAddress,
        address projectInfoAddress
    );

    /**
     * @notice assign the default roles
     * @param _withdrawManagerAddress implementation to clone
     * @param _scopeTokenImplementationAddress implementation to clone
     * @param _stakeTokenImplementationAddress implementation to clone
     * @param _insuranceImplementationAddress implementation to clone
     * @param _priceOracleImplementationAddress implementation to clone
     * @param _projectInfoImplementationAddress implementation to clone
     */
    constructor(
        address _withdrawManagerAddress,
        address _scopeTokenImplementationAddress,
        address _stakeTokenImplementationAddress,
        address _insuranceImplementationAddress,
        address _priceOracleImplementationAddress,
        address _projectInfoImplementationAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);

        withdrawManagerAddress = _withdrawManagerAddress;
        scopeTokenImplementationAddress = _scopeTokenImplementationAddress;
        stakeTokenImplementationAddress = _stakeTokenImplementationAddress;
        insuranceImplementationAddress = _insuranceImplementationAddress;
        priceOracleImplementationAddress = _priceOracleImplementationAddress;
        projectInfoImplementationAddress = _projectInfoImplementationAddress;
    }

    /**
     * @notice allows admins to pause the contract
     */
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    /**
     * @notice allows admins to unpause the contract
     */
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    /**
     * @notice deploys tokens for this tokenFunding funding
     * @param tokenFundingData the data of the token to fund
     * @param _priceOracleInfo the struct with the data to initialize the oracles
     * @param _unstakeFee this value should be between 1 and FEE_PRECISION (1000)
     */
    function initializeTokenFunding(
        TokenFundingData calldata tokenFundingData,
        PriceOracleInfo calldata _priceOracleInfo,
        uint256 _unstakeFee
    ) external whenNotPaused {
        require(tokenFundingData.owners.length > 0, "No owners");
        require(tokenFundingData.t > block.timestamp, "Invalid unlock date"); // solhint-disable-line
        require(tokenFundingData.maturity > block.timestamp, "Invalid maturity date"); // solhint-disable-line
        require(tokenFundingData.rMin < tokenFundingData.rMax, "Invalid r interval");

        uint256 roundsCount = tokenFundingData.fundingScopeRoundsData.length;

        require(
            tokenFundingData.fundingScopeRoundsData[roundsCount - 1].openingTime +
                tokenFundingData.fundingScopeRoundsData[roundsCount - 1].durationTime <
                tokenFundingData.maturity,
            "Invalid dates"
        );

        // timestamps for oracle
        ScopeTimestamps memory timestamps = ScopeTimestamps({
            firstGSlabOpeningDate: tokenFundingData.fundingScopeRoundsData[0].openingTime,
            lastGSlabEndingDate: tokenFundingData.fundingScopeRoundsData[roundsCount - 1].openingTime +
                tokenFundingData.fundingScopeRoundsData[roundsCount - 1].durationTime,
            maturityDate: uint64(tokenFundingData.maturity)
        });

        _tokenFundingIds.increment();

        // deploys a minimal proxy contract from implementation
        address newInsurance = Clones.clone(insuranceImplementationAddress);

        address newPriceOracle = Clones.clone(priceOracleImplementationAddress);
        SPOracle(newPriceOracle).initialize(
            _priceOracleInfo.appToken,
            _priceOracleInfo,
            timestamps,
            tokenFundingData.owners
        );

        address newScopeToken = Clones.clone(scopeTokenImplementationAddress);
        ScopeToken(newScopeToken).initialize(
            "Privi Scope Token",
            "pRT",
            tokenFundingData,
            newInsurance,
            newPriceOracle
        );

        address newStakeToken = Clones.clone(stakeTokenImplementationAddress);
        StakeToken(newStakeToken).initialize(
            "Privi Stake Token",
            "pST",
            tokenFundingData,
            newInsurance,
            _unstakeFee
        );

        // intialize the insurance proxy with the token addresses
        Insurance(newInsurance).initialize(
            tokenFundingData.appToken,
            newStakeToken,
            newScopeToken,
            withdrawManagerAddress,
            tokenFundingData.maturity,
            tokenFundingData.t
        );

        _tokenFundings[_tokenFundingIds.current()] = TokenFunding({
            appTokenAddress: tokenFundingData.appToken,
            insuranceAddress: newInsurance,
            stakeTokenAddress: newStakeToken,
            scopeTokenAddress: newScopeToken
        });

        _tokenFundingsOwners[_tokenFundingIds.current()] = tokenFundingData.owners;

        address newProjectInfo = Clones.clone(projectInfoImplementationAddress);
        ProjectInfo(newProjectInfo).initialize(newStakeToken, newScopeToken, newInsurance, newPriceOracle);

        emit CreateTokenFunding(
            _tokenFundingIds.current(),
            newInsurance,
            newStakeToken,
            newScopeToken,
            newPriceOracle,
            newProjectInfo
        );
    }

    /**
     * @notice getter for the owners of a token funding
     */
    function getOwnersOf(uint256 _tokenFundingId) external view returns (address[] memory) {
        require(_tokenFundings[_tokenFundingId].appTokenAddress != address(0), "Unexistent app");
        return _tokenFundingsOwners[_tokenFundingId];
    }

    /**
     * @param _owner The address of the owner to look for
     * @param _tokenFundingId The id of the token funding
     * @return The index and the owners count
     */
    function getOwnerIndexAndOwnersCount(address _owner, uint256 _tokenFundingId)
        external
        view
        returns (int256, uint256)
    {
        require(_tokenFundings[_tokenFundingId].appTokenAddress != address(0), "Unexistent token funding");

        uint256 count = _tokenFundingsOwners[_tokenFundingId].length;
        for (uint256 i = 0; i < count; i++) {
            if (_tokenFundingsOwners[_tokenFundingId][i] == _owner) {
                return (int256(i), count);
            }
        }
        return (-1, count);
    }

    /**
     * @notice getter for tokenFundings
     * @param _tokenFundingId the id of the tokenFunding to get
     */
    function getTokenFunding(uint256 _tokenFundingId) public view returns (TokenFunding memory) {
        require(_tokenFundings[_tokenFundingId].appTokenAddress != address(0), "Unexistent token funding");
        return _tokenFundings[_tokenFundingId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./TokenFundingManager.sol";
import "./IWithdrawable.sol";
import "./Structs.sol";

/**
 * @title manager for withdrawals
 * @author Eric Nordelo
 * @notice manages the withdrawals proposals and the multisig logic
 */
contract WithdrawManager is AccessControl, Initializable {
    using Counters for Counters.Counter;

    Counters.Counter private _withdrawProposalIds;

    uint64 private constant PROPOSAL_DURATION = 1 weeks;

    address public tokenFundingManagerAddress;

    // map from Id to WithdrawProposal
    mapping(uint256 => WithdrawProposal) private _withdrawProposals;

    // stores a mapping of owners and if already voted by proposalId
    mapping(uint256 => mapping(address => bool)) private _withdrawProposalsVoted;

    event DirectWithdraw(uint256 indexed tokenFundingId, address indexed recipient, uint256 amount);
    event CreateWithdrawProposal(
        uint256 indexed tokenFundingId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event ApproveWithdrawProposal(
        uint256 indexed tokenFundingId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event DenyWithdrawProposal(
        uint256 indexed tokenFundingId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event VoteWithdrawProposal(
        address indexed voter,
        uint256 indexed tokenFundingId,
        uint256 indexed proposalId
    );
    event ExpireWithdrawProposal(
        uint256 indexed tokenFundingId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice sets the addresses to support integration
     * @param _tokenFundingManagerAddress the address of the Privi NFT contract
     */
    function initialize(address _tokenFundingManagerAddress)
        external
        initializer
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenFundingManagerAddress = _tokenFundingManagerAddress;
    }

    /**
     * @notice direct withdraw when there is only one owner
     * @param _recipient the recipient of the transfer
     * @param _tokenFundingId the token funding id
     * @param _amount the amount of the app tokens to withdraw
     */
    function withdrawTo(
        address _recipient,
        uint256 _tokenFundingId,
        uint256 _amount
    ) external {
        (int256 index, uint256 ownersCount) = TokenFundingManager(tokenFundingManagerAddress)
            .getOwnerIndexAndOwnersCount(msg.sender, _tokenFundingId);
        require(index >= 0, "Invalid requester");
        require(ownersCount == 1, "Multiple owners, voting is needed");

        TokenFunding memory tokenFunding = TokenFundingManager(tokenFundingManagerAddress).getTokenFunding(
            _tokenFundingId
        );

        require(
            IWithdrawable(tokenFunding.insuranceAddress).withdrawTo(_recipient, _amount),
            "Error at transfer"
        );

        emit DirectWithdraw(_tokenFundingId, _recipient, _amount);
    }

    /**
     * @notice create a proposal for withdraw funds
     * @param _recipient the recipient of the transfer
     * @param _tokenFundingId the token funding id
     * @param _amount the amount of the app tokens to withdraw
     */
    function createWithdrawProposal(
        address _recipient,
        uint256 _tokenFundingId,
        uint256 _amount
    ) external {
        (int256 index, uint256 ownersCount) = TokenFundingManager(tokenFundingManagerAddress)
            .getOwnerIndexAndOwnersCount(msg.sender, _tokenFundingId);
        require(index >= 0, "Invalid requester");
        require(ownersCount > 1, "Only one owner, voting is not needed");

        _withdrawProposalIds.increment();

        uint256 proposalId = _withdrawProposalIds.current();

        WithdrawProposal memory _withdrawProposal = WithdrawProposal({
            minApprovals: uint64(ownersCount),
            maxDenials: 1,
            positiveVotesCount: 0,
            negativeVotesCount: 0,
            tokenFundingId: _tokenFundingId,
            recipient: _recipient,
            amount: _amount,
            date: uint64(block.timestamp), // solhint-disable-line
            duration: PROPOSAL_DURATION
        });

        // save the proposal for voting
        _withdrawProposals[proposalId] = _withdrawProposal;

        emit CreateWithdrawProposal(_tokenFundingId, _recipient, _amount, proposalId);
    }

    /**
     * @notice allows owners to vote withdraw proposals for pods
     * @param _proposalId the id of the withdraw proposal
     * @param _vote the actual vote: true or false
     */
    function voteWithdrawProposal(uint256 _proposalId, bool _vote) external {
        require(_withdrawProposals[_proposalId].minApprovals != 0, "Unexistent proposal");

        WithdrawProposal memory withdrawProposal = _withdrawProposals[_proposalId];

        (int256 index, ) = TokenFundingManager(tokenFundingManagerAddress).getOwnerIndexAndOwnersCount(
            msg.sender,
            withdrawProposal.tokenFundingId
        );

        require(index >= 0, "Invalid owner");

        require(!_withdrawProposalsVoted[_proposalId][msg.sender], "Owner already voted");

        _withdrawProposalsVoted[_proposalId][msg.sender] = true;

        // check if expired
        // solhint-disable-next-line
        if (withdrawProposal.date + withdrawProposal.duration < block.timestamp) {
            // delete the recover gas
            delete _withdrawProposals[_proposalId];
            emit ExpireWithdrawProposal(
                withdrawProposal.tokenFundingId,
                withdrawProposal.recipient,
                withdrawProposal.amount,
                _proposalId
            );
        } else {
            // if the vote is positive
            if (_vote) {
                // if is the last vote to approve
                if (withdrawProposal.positiveVotesCount + 1 == withdrawProposal.minApprovals) {
                    delete _withdrawProposals[_proposalId];

                    TokenFunding memory tokenFunding = TokenFundingManager(tokenFundingManagerAddress)
                        .getTokenFunding(withdrawProposal.tokenFundingId);

                    require(
                        IWithdrawable(tokenFunding.insuranceAddress).withdrawTo(
                            withdrawProposal.recipient,
                            withdrawProposal.amount
                        ),
                        "Error at transfer"
                    );

                    emit ApproveWithdrawProposal(
                        withdrawProposal.tokenFundingId,
                        withdrawProposal.recipient,
                        withdrawProposal.amount,
                        _proposalId
                    );
                } else {
                    // update the proposal and emit the event
                    _withdrawProposals[_proposalId].positiveVotesCount++;
                    emit VoteWithdrawProposal(msg.sender, withdrawProposal.tokenFundingId, _proposalId);
                }
            }
            // if the vote is negative
            else {
                // if is the last vote to deny
                if (withdrawProposal.negativeVotesCount + 1 == withdrawProposal.maxDenials) {
                    // delete the proposal and emit the event
                    delete _withdrawProposals[_proposalId];
                    emit DenyWithdrawProposal(
                        withdrawProposal.tokenFundingId,
                        withdrawProposal.recipient,
                        withdrawProposal.amount,
                        _proposalId
                    );
                } else {
                    // update the proposal and emit the event
                    _withdrawProposals[_proposalId].negativeVotesCount++;
                    emit VoteWithdrawProposal(msg.sender, withdrawProposal.tokenFundingId, _proposalId);
                }
            }
        }
    }

    /**
     * @notice proposal struct getter
     * @param _proposalId The id of the withdraw proposal
     * @return the WithdrawProposal object
     */
    function getUpdateMediaProposal(uint256 _proposalId) external view returns (WithdrawProposal memory) {
        WithdrawProposal memory withdrawProposal = _withdrawProposals[_proposalId];
        require(withdrawProposal.minApprovals != 0, "Unexistent proposal");
        return withdrawProposal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../IWithdrawable.sol";
import "../Structs.sol";
import "./ScopeToken.sol";
import "./StakeToken.sol";

/**
 * @notice implementation of the insurance contract for minimal proxy deployments
 * @author Eric Nordelo
 */
contract Insurance is AccessControl, Initializable, IWithdrawable {
    bytes32 private constant STAKE_TOKEN = keccak256("STAKE_TOKEN");
    bytes32 private constant SCOPE_TOKEN = keccak256("SCOPE_TOKEN");
    bytes32 private constant WITHDRAW_MANAGER = keccak256("WITHDRAW_MANAGER");

    address public appTokenAddress;
    address public stakeTokenAddress;
    address public scopeTokenAddress;

    uint256 public unlockingDate;

    // solhint-disable-next-line
    constructor() {}

    /**
     * @notice initializes the minimal proxy clone (setup roles)
     */
    function initialize(
        address _appTokenAddress,
        address _stakeTokenAddress,
        address _scopeTokenAddress,
        address _withdrawManagerAddress,
        uint256 _maturity,
        uint256 _t
    ) external initializer {
        if (_maturity > _t) {
            unlockingDate = _maturity;
        } else {
            unlockingDate = _t;
        }

        appTokenAddress = _appTokenAddress;
        stakeTokenAddress = _stakeTokenAddress;
        scopeTokenAddress = _scopeTokenAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAKE_TOKEN, _stakeTokenAddress);
        _setupRole(SCOPE_TOKEN, _scopeTokenAddress);
        _setupRole(WITHDRAW_MANAGER, _withdrawManagerAddress);
    }

    /**
     * @notice returns the balance available for owners to withdraw at the moment,
     * before the unlocking date of stake and scope tokens the value is 0
     * @return the available balance in app tokens
     */
    function withdrawableBalance() public view returns (uint256) {
        // solhint-disable-next-line
        if (unlockingDate > block.timestamp) {
            return 0;
        }

        uint256 totalBalance = IERC20(appTokenAddress).balanceOf(address(this));
        uint256 owedValueInScopeTokens = ScopeToken(scopeTokenAddress).getAppTokensOwed();
        uint256 owedValueInStakeTokens = StakeToken(stakeTokenAddress).appTokensOwed();

        if (totalBalance > owedValueInScopeTokens + owedValueInStakeTokens) {
            return totalBalance - (owedValueInScopeTokens + owedValueInStakeTokens);
        } else {
            return 0;
        }
    }

    /**
     * @dev allows to claim through the token contracts
     */
    function sendAppTokens(address _to, uint256 _amount) external returns (bool) {
        if (hasRole(STAKE_TOKEN, msg.sender) || hasRole(SCOPE_TOKEN, msg.sender)) {
            return (IERC20(appTokenAddress).transfer(_to, _amount));
        } else {
            revert("Invalid caller");
        }
    }

    /**
     * @notice transfer the amount of selected tokens to address
     */
    function withdrawTo(address account, uint256 amount)
        external
        override
        onlyRole(WITHDRAW_MANAGER)
        returns (bool)
    {
        uint256 balance = withdrawableBalance();
        require(balance >= amount, "Insuficient withdrawable funds");
        return (IERC20(appTokenAddress).transfer(account, amount));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../Structs.sol";
import "./StakeToken.sol";
import "./ScopeToken.sol";
import "../oracles/SPOracle.sol";

/**
 * @notice implementation of the poyect info for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract ProjectInfo is Initializable {
    StakeToken private _stakeToken;
    ScopeToken private _scopeToken;
    SPOracle private _oracle;

    address private _insuranceContractAddress;

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        address _stakeTokenAddress,
        address _scopeTokenAddress,
        address _insuranceAddress,
        address _oracleAddress
    ) external initializer {
        _stakeToken = StakeToken(_stakeTokenAddress);
        _scopeToken = ScopeToken(_scopeTokenAddress);
        _oracle = SPOracle(_oracleAddress);

        _insuranceContractAddress = _insuranceAddress;
    }

    function getCurrentStakeRoundNumber() external view returns (uint256) {
        return _stakeToken.getRoundNumber();
    }

    function getCurrentScopeRoundNumber() external view returns (uint256) {
        return _scopeToken.getRoundNumber();
    }

    function getUnlockingTime() external view returns (uint256) {
        return _stakeToken.unlockingDate();
    }

    function getMaturityTime() external view returns (uint256) {
        return _scopeToken.maturityDate();
    }

    function getLowerRange() external view returns (uint256) {
        return _scopeToken.rMin();
    }

    function getUpperRange() external view returns (uint256) {
        return _scopeToken.rMax();
    }

    function getScopeTokenContract() external view returns (address) {
        return address(_scopeToken);
    }

    function getStakeTokenContract() external view returns (address) {
        return address(_stakeToken);
    }

    function getInsuranceContract() external view returns (address) {
        return _insuranceContractAddress;
    }

    function getOracleContract() external view returns (address) {
        return address(_oracle);
    }

    function getScopeRoundInfo(uint256 _roundIndex) external view returns (FundingScopeRoundsData memory) {
        return _scopeToken.getRoundInfo(_roundIndex);
    }

    function getStakeRoundInfo(uint256 _roundIndex) external view returns (FundingStakeRoundsData memory) {
        return _stakeToken.getRoundInfo(_roundIndex);
    }

    function getOracleSourceURL() external view returns (string memory) {
        return _oracle.apiURL();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../oracles/SPOracle.sol";
import "../Structs.sol";
import "./Insurance.sol";

/**
 * @notice implementation of the erc20 token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract ScopeToken is ERC20, AccessControl, Initializable {
    uint256 private constant DISCOUNT_PRECISION = 1000;
    uint256 private constant PRECISION = 1000000;

    address private _appToken;
    address private _insuranceContractAddress;

    uint256 public rMin;
    uint256 public rMax;

    string private _proxiedName;
    string private _proxiedSymbol;
    address private _priceOracleAddress;

    FundingScopeRoundsData[] private _fundingRoundsData;

    uint256 public maturityDate; // date of maturity of the options

    event ClaimTokens(address indexed holder, uint256 balance);

    // solhint-disable-next-line
    constructor() ERC20("Privi Scope Token Implementation", "pSTI") {}

    /**
     * @notice initializes the minimal proxy clone
     * @dev ! INSERTING AN ARRAY OF STRUCTS, VERY EXPENSIVE!!!
     * @param _name the name of the token
     * @param _symbol the symbol of the token
     * @param _tokenFundingData the token funding data
     * @param __insuranceContractAddress the insurance contract address for app token balance handling
     * @param __priceOracleAddress the price oracle contract address
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        TokenFundingData calldata _tokenFundingData,
        address __insuranceContractAddress,
        address __priceOracleAddress
    ) external initializer {
        _proxiedName = _name;
        _proxiedSymbol = _symbol;

        _appToken = _tokenFundingData.appToken;
        _insuranceContractAddress = __insuranceContractAddress;

        // initialize variables
        rMin = _tokenFundingData.rMin;
        rMax = _tokenFundingData.rMax;
        maturityDate = _tokenFundingData.maturity;
        _priceOracleAddress = __priceOracleAddress;

        require(_tokenFundingData.fundingScopeRoundsData.length > 0, "Invalid rounds count");
        for (uint256 i; i < _tokenFundingData.fundingScopeRoundsData.length; i++) {
            require(_tokenFundingData.fundingScopeRoundsData[i].mintedTokens == 0, "Invalid data");
            _fundingRoundsData.push(_tokenFundingData.fundingScopeRoundsData[i]);
        }

        for (uint256 i; i < _tokenFundingData.fundingScopeRoundsData.length - 1; i++) {
            require(_tokenFundingData.fundingScopeRoundsData[i].mintedTokens == 0, "Invalid data");
            if (
                _tokenFundingData.fundingScopeRoundsData[i].discount <
                _tokenFundingData.fundingScopeRoundsData[i + 1].discount ||
                _tokenFundingData.fundingScopeRoundsData[i].discount == 0
            ) {
                revert("Invalid discount distribution");
            }
            _fundingRoundsData.push(_tokenFundingData.fundingScopeRoundsData[i]);
        }
        _fundingRoundsData.push(
            _tokenFundingData.fundingScopeRoundsData[_tokenFundingData.fundingScopeRoundsData.length - 1]
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice allows to claim the app tokens at the right time
     */
    function claim() external {
        // solhint-disable-next-line
        require(maturityDate <= block.timestamp, "Maturity date not reached yet");

        (uint256 holderBalance, uint256 payout) = balanceAndPayoutOf(msg.sender);
        require(holderBalance > 0, "No tokens to claim");

        uint256 appTokensToReceive = ((holderBalance * payout) / PRECISION);

        // burn the tokens before transfer
        _burn(msg.sender, holderBalance);

        // send the tokens from payout
        bool transfered = Insurance(_insuranceContractAddress).sendAppTokens(msg.sender, appTokensToReceive);
        require(transfered, "Fail to transfer");

        emit ClaimTokens(msg.sender, appTokensToReceive);
    }

    /**
     * @notice returns the owed balance of the contract in app tokens at the time
     */
    function getAppTokensOwed() external view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 payout = scopeTokenPayout();

        return (supply * payout) / PRECISION;
    }

    /**
     * @notice returns the estimated payout at the time
     * @dev the actual value should be divided by precision
     */
    function scopeTokenPayout() public view returns (uint256) {
        // solhint-disable-next-line
        require(maturityDate <= block.timestamp, "Maturity has not been reached");

        uint256 p = SPOracle(_priceOracleAddress).latest_P();
        uint256 s = SPOracle(_priceOracleAddress).latest_S();

        require(p > 0, "P not set yet (call the oracle first)");
        require(s > 0, "S not set yet (call the oracle first)");

        // multiply * 10**15 to get 18 decimals as s and p (3 from input)
        uint256 rMaxWith18decimals = rMax * 10**15;
        uint256 rMinWith18decimals = rMin * 10**15;

        if (p < (rMinWith18decimals)) {
            return (rMaxWith18decimals * PRECISION) / (rMinWith18decimals);
        } else if (p > rMaxWith18decimals) {
            return PRECISION; // 1 for 1
        } else {
            return (rMaxWith18decimals * PRECISION) / p;
        }
    }

    /**
     * @notice returns the balance and the payout at the time
     */
    function balanceAndPayoutOf(address _holder) public view returns (uint256 balance, uint256 payout) {
        balance = balanceOf(_holder);
        payout = scopeTokenPayout();
    }

    /**
     * @notice returns the round info
     */
    function getRoundInfo(uint256 _roundIndex) public view returns (FundingScopeRoundsData memory) {
        require(_fundingRoundsData[_roundIndex].capTokensToBeSold > 0, "Unexistent round");
        return _fundingRoundsData[_roundIndex];
    }

    /**
     * @notice returns the index of the active round or zero if there is none
     */
    function getRoundNumber() public view returns (uint256) {
        // solhint-disable-next-line
        uint256 currentTime = block.timestamp;
        if (
            currentTime < _fundingRoundsData[0].openingTime ||
            currentTime >
            _fundingRoundsData[_fundingRoundsData.length - 1].openingTime +
                _fundingRoundsData[_fundingRoundsData.length - 1].durationTime *
                1 days
        ) {
            return 0;
        }
        for (uint256 i; i < _fundingRoundsData.length; i++) {
            if (
                currentTime >= _fundingRoundsData[i].openingTime &&
                currentTime < _fundingRoundsData[i].openingTime + _fundingRoundsData[i].durationTime * 1 days
            ) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @dev allow to investors buy scope tokens specifiying the amount of scope tokens
     * @param _amount allow to the investors that buy scope token specifying the amount
     */
    function buyTokensByAmountToGet(uint256 _amount) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;
        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokensToBeSold,
            "All tokens sold"
        );
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokensToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        uint256 _amountToPay = _amount;
        _amountToPay -= (_amountToPay * _fundingRoundsData[_roundIndex].discount) / DISCOUNT_PRECISION;
        require(_amountToPay > 0, "Invalid payment after discount");

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(_appToken).transferFrom(msg.sender, _insuranceContractAddress, _amountToPay);
        // solhint-disable-next-line
        require(result);
    }

    /**
     * @dev allow to investors buy scope tokens specifiying the amount of pay tokens
     * @param _amountToPay allow to the investors that buy scope token specifying the amount of pay token
     */
    function buyTokensByAmountToPay(uint256 _amountToPay) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;
        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokensToBeSold,
            "All tokens sold"
        );

        uint256 _amount = _amountToPay;

        // apply discount
        _amountToPay -= ((_amountToPay * _fundingRoundsData[_roundIndex].discount) / DISCOUNT_PRECISION);
        require(_amountToPay > 0, "Invalid payment after discount");
        require(_amount > 0, "Insuficient amount to pay");
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokensToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(_appToken).transferFrom(msg.sender, _insuranceContractAddress, _amountToPay);
        // solhint-disable-next-line
        require(result);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../Structs.sol";
import "./Insurance.sol";

/**
 * @notice implementation of the stake token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract StakeToken is ERC721, AccessControl, Initializable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant PRECISION = 1000000;
    uint256 private constant REWARD_PRECISION = 1000;
    uint256 private constant FEE_PRECISION = 1000;

    string private _proxiedName;
    string private _proxiedSymbol;

    FundingStakeRoundsData[] private _fundingRoundsData;

    address private _appToken;
    address private _insuranceContractAddress;

    uint128 public unlockingDate; // date of expiration of the options
    uint128 public unstakeFee = 50; // value between 1 and FEE_PRECISION

    mapping(uint256 => uint256) public tokensRewards;
    mapping(uint256 => uint256) public tokensRoundIndex;
    mapping(uint256 => uint256) public appTokensStaked;

    /**
     * @notice getters for total staked and owed values in app tokens
     */
    uint256 public appTokensOwed;
    uint256 public totalAppTokensStaked;

    event StakeTokens(address indexed holder, uint256 nftId, uint256 quantity);
    event ClaimTokens(address indexed holder, uint256 quantity);
    event UnstakeTokens(address indexed holder, uint256 quantityStaked, uint256 quantityReceivedAfterFee);

    // solhint-disable-next-line
    constructor() ERC721("Privi Stake Token", "pST") {}

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        string calldata proxiedName,
        string calldata proxiedSymbol,
        TokenFundingData calldata _tokenFundingData,
        address __insuranceContractAddress,
        uint256 _unstakeFee
    ) external initializer {
        _proxiedName = proxiedName;
        _proxiedSymbol = proxiedSymbol;
        _appToken = _tokenFundingData.appToken;
        _insuranceContractAddress = __insuranceContractAddress;

        unlockingDate = _tokenFundingData.t;

        if (_unstakeFee < 1 || _unstakeFee > FEE_PRECISION) {
            revert("Fee should be between 1 and FEE_PRECISION");
        }
        unstakeFee = uint128(_unstakeFee);

        require(_tokenFundingData.fundingStakeRoundsData.length > 0, "Invalid rounds count");
        for (uint256 i; i < _tokenFundingData.fundingStakeRoundsData.length - 1; i++) {
            require(_tokenFundingData.fundingStakeRoundsData[i].stakedTokens == 0, "Invalid data");
            if (
                _tokenFundingData.fundingStakeRoundsData[i].stakeReward <
                _tokenFundingData.fundingStakeRoundsData[i + 1].stakeReward ||
                _tokenFundingData.fundingStakeRoundsData[i].stakeReward == 0
            ) {
                revert("Invalid rewards distribution");
            }
            _fundingRoundsData.push(_tokenFundingData.fundingStakeRoundsData[i]);
        }
        _fundingRoundsData.push(
            _tokenFundingData.fundingStakeRoundsData[_tokenFundingData.fundingStakeRoundsData.length - 1]
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }

    /**
     * @notice allows to get the accrued reward of staked tokens
     * @param _tokenId the is of the nft token
     */
    function getAccruedReward(uint256 _tokenId) external view returns (uint256 accruedReward) {
        uint256 _roundId = tokensRoundIndex[_tokenId];
        require(_roundId != 0, "Unexistent token");

        // the index is the id minus 1
        uint256 roundEndingDate = _fundingRoundsData[_roundId - 1].openingTime +
            _fundingRoundsData[_roundId - 1].durationTime;

        // solhint-disable-next-line
        if (block.timestamp <= roundEndingDate) {
            return 0;
        }

        // apply the formula
        accruedReward =
            (((appTokensStaked[_tokenId] * _fundingRoundsData[_roundId - 1].stakeReward) / REWARD_PRECISION) *
                (block.timestamp - roundEndingDate)) / // solhint-disable-line
            (unlockingDate - roundEndingDate);
    }

    /**
     * @notice returns the round info
     */
    function getRoundInfo(uint256 _roundIndex) public view returns (FundingStakeRoundsData memory) {
        require(_fundingRoundsData[_roundIndex].capTokensToBeStaked > 0, "Unexistent round");
        return _fundingRoundsData[_roundIndex];
    }

    /**
     * @notice allows an account to stake app tokens in the contract
     * @param _amount the amount of app tokens to stake
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        require(
            IERC20(_appToken).transferFrom(msg.sender, _insuranceContractAddress, _amount),
            "Allowance required"
        );

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        uint256 reward = getCurrentReward();

        uint256 _roundId = getRoundNumber();
        tokensRoundIndex[newTokenId] = _roundId;

        tokensRewards[newTokenId] = reward;
        appTokensStaked[newTokenId] = _amount;

        // update the total staked and owed valued
        totalAppTokensStaked += _amount;
        appTokensOwed += _amount + ((_amount * reward) / REWARD_PRECISION);

        _mint(msg.sender, newTokenId);

        emit StakeTokens(msg.sender, newTokenId, _amount);
    }

    /**
     * @notice allows to claim the app tokens before time (without rewards and paying fee)
     */
    function unstake(uint256 _tokenId) external {
        // solhint-disable-next-line
        require(unlockingDate > block.timestamp, "Expiration date reached");
        require(msg.sender == ownerOf(_tokenId), "User doesn't own the token");

        uint256 stakedAmount = appTokensStaked[_tokenId];
        uint256 reward = tokensRewards[_tokenId];

        assert(stakedAmount > 0);

        uint256 appTokensToReceive = stakedAmount - ((stakedAmount * unstakeFee) / FEE_PRECISION);

        delete appTokensStaked[_tokenId];
        delete tokensRoundIndex[_tokenId];
        delete tokensRewards[_tokenId];

        // update the total staked and owed valued
        totalAppTokensStaked -= stakedAmount;
        appTokensOwed -= stakedAmount + ((stakedAmount * reward) / REWARD_PRECISION);

        // burn the tokens before transfer
        _burn(_tokenId);

        // send the tokens from payout
        bool transfered = Insurance(_insuranceContractAddress).sendAppTokens(msg.sender, appTokensToReceive);
        require(transfered, "Fail to transfer");

        emit UnstakeTokens(msg.sender, stakedAmount, appTokensToReceive);
    }

    /**
     * @notice allows to claim the app tokens at the right time
     */
    function claim(uint256 _tokenId) external {
        // solhint-disable-next-line
        require(unlockingDate <= block.timestamp, "Expiration date not reached yet");
        require(msg.sender == ownerOf(_tokenId), "User doesn't own the token");

        uint256 stakedAmount = appTokensStaked[_tokenId];
        uint256 reward = tokensRewards[_tokenId];

        assert(stakedAmount > 0);

        uint256 appTokensToReceive = stakedAmount + ((stakedAmount * reward) / REWARD_PRECISION);

        delete appTokensStaked[_tokenId];
        delete tokensRoundIndex[_tokenId];
        delete tokensRewards[_tokenId];

        // update the total staked and owed valued
        totalAppTokensStaked -= stakedAmount;
        appTokensOwed -= stakedAmount + ((stakedAmount * reward) / REWARD_PRECISION);

        // burn the tokens before transfer
        _burn(_tokenId);

        // send the tokens from payout
        bool transfered = Insurance(_insuranceContractAddress).sendAppTokens(msg.sender, appTokensToReceive);
        require(transfered, "Fail to transfer");

        emit ClaimTokens(msg.sender, appTokensToReceive);
    }

    /**
     * @notice returns the current round number
     */
    function getRoundNumber() public view returns (uint256) {
        // solhint-disable-next-line
        uint256 currentTime = block.timestamp;
        if (
            currentTime < _fundingRoundsData[0].openingTime ||
            currentTime >
            _fundingRoundsData[_fundingRoundsData.length - 1].openingTime +
                _fundingRoundsData[_fundingRoundsData.length - 1].durationTime *
                1 days
        ) {
            return 0;
        }
        for (uint256 i; i < _fundingRoundsData.length; i++) {
            if (
                currentTime >= _fundingRoundsData[i].openingTime &&
                currentTime < _fundingRoundsData[i].openingTime + _fundingRoundsData[i].durationTime * 1 days
            ) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @notice get current reward of staking (REWARD_PRECISION should be divided to returned value)
     */
    function getCurrentReward() public view returns (uint256) {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        // the index is the id minus 1
        return _fundingRoundsData[_roundId - 1].stakeReward;
    }

    /**
     * @dev disallows transfer functionality
     */
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Transfer not allowed");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PriceOracleInfo {
    string appToken;
    address linkToken;
    address chainlinkNode;
    string jobId;
    uint256 nodeFee; // should be the value multiplied by 1000 (0.1 = 100)
}

struct ScopeTimestamps {
    uint64 firstGSlabOpeningDate;
    uint64 lastGSlabEndingDate;
    uint64 maturityDate;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./OracleStructs.sol";

/**
 * @title oracle to get the assets price in USD
 * @author Eric Nordelo
 */
contract SPOracle is ChainlinkClient, Initializable {
    int256 private constant TIMES = 10**18;

    uint256 private _s;
    uint256 private _p;

    ScopeTimestamps public scopeTimestamps;

    /// @notice the token to get the price for
    string public token;

    /// @notice the url to get the prices
    string public apiURL;

    /// @notice the chainlink node
    address public chainlinkNode;

    /// @notice the node job id
    bytes32 public jobId;

    /// @notice the fee in LINK
    uint256 public nodeFee;

    /// @notice the address of the LINK token
    address public linkToken;

    address[] private _owners;

    // solhint-disable-next-line
    constructor() {}

    modifier onlyOwner() {
        uint256 count = _owners.length;
        bool isOwner = false;
        for (uint256 i = 0; i < count; i++) {
            if (_owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Only owners can modify the oracle");
        _;
    }

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        string memory _token,
        PriceOracleInfo memory _oracleInfo,
        ScopeTimestamps memory _timestamps,
        address[] memory __owners
    ) external initializer {
        _owners = __owners;
        token = _token;
        linkToken = _oracleInfo.linkToken;
        chainlinkNode = _oracleInfo.chainlinkNode;
        jobId = stringToBytes32(_oracleInfo.jobId);
        nodeFee = (_oracleInfo.nodeFee * LINK_DIVISIBILITY) / 1000;

        apiURL = "https://backend-exchange-oracle-prod.privi.store/past?token=";
        scopeTimestamps = _timestamps;

        setChainlinkToken(linkToken);
    }

    function setOracleInfo(PriceOracleInfo calldata _oracleInfo) external onlyOwner {
        linkToken = _oracleInfo.linkToken;
        chainlinkNode = _oracleInfo.chainlinkNode;
        jobId = stringToBytes32(_oracleInfo.jobId);
        nodeFee = (_oracleInfo.nodeFee * LINK_DIVISIBILITY) / 1000; // 0.01 LINK

        setChainlinkToken(linkToken);
    }

    function setAPIURL(string calldata _url) external onlyOwner {
        apiURL = _url;
    }

    // solhint-disable-next-line
    function update_S() external returns (bytes32 requestId) {
        // solhint-disable-next-line
        require(block.timestamp > scopeTimestamps.lastGSlabEndingDate, "Can't update S yet");
        require(_s == 0, "S already set");

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill_S.selector
        );

        // set the request params
        Chainlink.add(
            request,
            "get",
            string(
                abi.encodePacked(
                    apiURL,
                    token,
                    "&start=",
                    uint2str(scopeTimestamps.firstGSlabOpeningDate),
                    "&end=",
                    uint2str(scopeTimestamps.lastGSlabEndingDate)
                )
            )
        );
        Chainlink.add(request, "path", "vwap");
        Chainlink.addInt(request, "times", TIMES);

        // Send the request
        return sendChainlinkRequestTo(chainlinkNode, request, nodeFee);
    }

    // solhint-disable-next-line
    function update_P() external returns (bytes32 requestId) {
        // solhint-disable-next-line
        require(block.timestamp > scopeTimestamps.maturityDate, "Can't update P yet");
        require(_p == 0, "P already set");

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill_P.selector
        );

        // set the request params
        Chainlink.add(
            request,
            "get",
            string(
                abi.encodePacked(
                    apiURL,
                    token,
                    "&start=",
                    uint2str(scopeTimestamps.lastGSlabEndingDate),
                    "&end=",
                    uint2str(scopeTimestamps.maturityDate)
                )
            )
        );
        Chainlink.add(request, "path", "vwap");
        Chainlink.addInt(request, "times", TIMES);

        // Sends the request
        return sendChainlinkRequestTo(chainlinkNode, request, nodeFee);
    }

    /**
     * @dev Receive the response in the form of uint256
     */
    // solhint-disable-next-line
    function fulfill_S(bytes32 _requestId, uint256 __s) public recordChainlinkFulfillment(_requestId) {
        _s = __s;
    }

    /**
     * @dev Receive the response in the form of uint256
     */
    // solhint-disable-next-line
    function fulfill_P(bytes32 _requestId, uint256 __p) public recordChainlinkFulfillment(_requestId) {
        _p = __p;
    }

    /**
     * @dev returns the last S report of the oracle
     */
    // solhint-disable-next-line
    function latest_S() external view returns (uint256) {
        return _s;
    }

    /**
     * @dev returns the last P report of the oracle
     */
    // solhint-disable-next-line
    function latest_P() external view returns (uint256) {
        return _p;
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(source, 32))
        }
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

