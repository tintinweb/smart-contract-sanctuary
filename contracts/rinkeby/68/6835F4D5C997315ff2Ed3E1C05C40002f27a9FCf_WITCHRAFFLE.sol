/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.6.0;
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}
interface governance_interface {
    function lottery() external view returns (address);
    function randomness() external view returns (address);
}
interface lottery_interface {
    function fulfill_random(uint) external;
}
interface randomness_interface {
    function randomNumber(uint) external view returns (uint);
    function getRandom(uint, uint) external;
}
contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF
   *
   * @dev To prevent repetition of VRF output due to repetition against the
   * @dev user-supplied seed, that seed is combined in a hash with the a
   * @dev user-specific nonce, and the address of the consuming contract.
   *
   * @dev Of course, crucial security guranatees would be broken by repetition
   * @dev of the user-supplied seed, as all the other inputs can be anticipated
   * @dev and the user-specified seed is public once the initial request is
   * @dev made, so if the oracle has reason to belive that a user-specified seed
   * @dev will be repeated, it may be able to anticipate its future outputs. So
   * @dev it may make sense, for certain applications, for the VRF framework to
   * @dev simply refuse to operate, if given a seed it's seen before.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMath for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it.
   *
   * @dev The VRFCoordinator expects a calling contract to have a method with
   * @dev this signature, and will call it once it has verified the proof
   * @dev associated with the randomness.
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    external virtual;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The source of the seed data must be something which the oracle
   * @dev cannot anticipate. See "SECURITY CONSIDERATIONS" above.
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed Random seed from which output randomness is determined
   *
   * @return requestId which will be returned with the response to this request
   *
   * @dev The returned requestId can be used to distinguish responses to *
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    public returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed actually passed to the VRF in VRFCoordinator
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest)
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal LINK;
  address internal vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) public nonces;
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }
}
interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}
abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}
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
interface PointerInterface {
  function getAddress() external view returns (address);
}
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
   * @param _id The Job Specification ID
   * @param _callbackAddress The callback address
   * @param _callbackFunction The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param _data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    BufferChainlink.init(self.buf, _data.length);
    BufferChainlink.append(self.buf, _data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The string value to add
   */
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The bytes value to add
   */
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The int256 value to add
   */
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The uint256 value to add
   */
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _values The array of string values to add
   */
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}
contract RandomNumberConsumer is VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 internal fee;
    mapping (uint => uint) public randomNumber;
    mapping (bytes32 => uint) public requestIds;
    governance_interface public governance;
    uint256 public most_recent_random;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Ropsten
     * Chainlink VRF Coordinator address: 0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb
     * LINK token address:                0x20fE562d797A42Dcb3399062AE9546cd06f63280
     * Key Hash: 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205
     */
    constructor(address _governance)
        VRFConsumerBase(
            0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb, // VRF Coordinator
            0x20fE562d797A42Dcb3399062AE9546cd06f63280  // LINK Token
        ) public
    {
        keyHash = 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        governance = governance_interface(_governance);
    }

    /**
     * Requests randomness from a user-provided seed
     */

    function getRandom(uint256 userProvidedSeed, uint256 lotteryId) public {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        bytes32 _requestId = requestRandomness(keyHash, fee, userProvidedSeed);
        requestIds[_requestId] = lotteryId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external override {
        require(msg.sender == vrfCoordinator, "Fulillment only permitted by Coordinator");
        most_recent_random = randomness;
        uint lotteryId = requestIds[requestId];
        randomNumber[lotteryId] = randomness;
        lottery_interface(governance.lottery()).fulfill_random(randomness);
    }
}
contract Governance {
    uint256 public one_time;
    address public lottery;
    address public randomness;
    constructor() public {
        one_time = 1;
    }
    function init(address _lottery, address _randomness) public {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_lottery != address(0), "no-lottery-address-given");
        require(one_time > 0, "can-only-be-called-once");
        one_time = one_time - 1;
        randomness = _randomness;
        lottery = _lottery;
    }
}
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param _specId The Job Specification ID that the request will be created for
   * @param _callbackAddress The callback address that the response will be sent to
   * @param _callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param _oracle The address of the oracle for the request
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param _requestId The request ID
   * @param _payment The amount of LINK sent for the request
   * @param _callbackFunc The callback function specified for the request
   * @param _expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param _oracle The address of the oracle contract
   */
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

  /**
   * @notice Sets the LINK token address
   * @param _link The address of the LINK token contract
   */
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
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
    returns (address)
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param _oracle The address of the oracle contract that will fulfill the request
   * @param _requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param _ens The address of the ENS contract
   * @param _node The ENS node hash
   */
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver resolver = ENSResolver(ens.resolver(linkSubnode));
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
    ENSResolver resolver = ENSResolver(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Encodes the request to be sent to the oracle contract
   * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
   * will be validated in the oracle contract.
   * @param _req The initialized Chainlink Request
   * @return The bytes payload for the `transferAndCall` method
   */
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param _requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param _requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param _requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}
contract WITCHRAFFLE is ChainlinkClient {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    uint256 public lotteryId;
    address payable[] public players;
    governance_interface public governance;
    // .01 ETH
    uint256 public MINIMUM = 1000000000000000;
    // 0.1 LINK
    uint256 public ORACLE_PAYMENT = 100000000000000000;
    // Alarm stuff
    address CHAINLINK_ALARM_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    bytes32 CHAINLINK_ALARM_JOB_ID = "2ebb1c1a4b1e4229adac24ee0b5f784f";

    constructor(address _governance) public
    {
        setPublicChainlinkToken();
        lotteryId = 1;
        lottery_state = LOTTERY_STATE.CLOSED;
        governance = governance_interface(_governance);
    }

    function enter() public payable {
        assert(msg.value == MINIMUM);
        assert(lottery_state == LOTTERY_STATE.OPEN);
        players.push(msg.sender);
    }

  function start_new_lottery(uint256 duration) public {
    require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
    lottery_state = LOTTERY_STATE.OPEN;
    Chainlink.Request memory req = buildChainlinkRequest(CHAINLINK_ALARM_JOB_ID, address(this), this.fulfill_alarm.selector);
    req.addUint("until", now + duration);
    sendChainlinkRequestTo(CHAINLINK_ALARM_ORACLE, req, ORACLE_PAYMENT);
  }

  function fulfill_alarm(bytes32 _requestId)
    public
    recordChainlinkFulfillment(_requestId)
      {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        // add a require here so that only the oracle contract can
        // call the fulfill alarm method
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        lotteryId = lotteryId + 1;
        pickWinner();
    }


    function pickWinner() private {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        randomness_interface(governance.randomness()).getRandom(lotteryId, lotteryId);
        //this kicks off the request and returns through fulfill_random
    }

    function fulfill_random(uint256 randomness) external {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(randomness > 0, "random-not-found");
        // assert(msg.sender == governance.randomness());
        uint256 index = randomness % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        // You could have this run forever
        // start_new_lottery();
        // or with a cron job from a chainlink node would allow you to
        // keep calling "start_new_lottery" as well
    }

    function get_players() public view returns (address payable[] memory) {
        return players;
    }

    function get_pot() public view returns(uint256){
        return address(this).balance;
    }
}