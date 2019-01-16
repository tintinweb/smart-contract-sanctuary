pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if(a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Appends a byte array to the end of the buffer. Resizes if doing so
     * would exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, bytes data) internal pure returns(buffer memory) {
        if(data.length + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, data.length) * 2);
        }

        uint dest;
        uint src;
        uint len = data.length;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + buffer length + sizeof(buffer length)
            dest := add(add(bufptr, buflen), 32)
            // Update buffer length
            mstore(bufptr, add(buflen, mload(data)))
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
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
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, uint8 data) internal pure {
        if(buf.buf.length + 1 > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length)
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, data)
            // Update buffer length
            mstore(bufptr, add(buflen, 1))
        }
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        if(len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length) + len
            let dest := add(add(bufptr, buflen), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length
            mstore(bufptr, add(buflen, len))
        }
        return buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if(value <= 23) {
            buf.append(uint8((major << 5) | value));
        } else if(value <= 0xFF) {
            buf.append(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.append(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.append(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.append(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

library ChainlinkLib {
  bytes internal constant reqSig = "requestData(address,uint256,uint256,bytes32,address,bytes4,bytes32,bytes)";
  bytes4 internal constant oracleRequestDataFid = bytes4(keccak256(reqSig));
  bytes internal constant coordSig = "executeServiceAgreement(address,uint256,uint256,bytes32,address,bytes4,bytes32,bytes)";
  bytes4 internal constant coordinatorRequestDataFid = bytes4(keccak256(coordSig));

  using CBOR for Buffer.buffer;

  struct Run {
    bytes32 specId;
    address callbackAddress;
    bytes4 callbackFunctionId;
    bytes32 requestId;
    Buffer.buffer buf;
  }

  function initialize(
    Run memory self,
    bytes32 _specId,
    address _callbackAddress,
    string _callbackFunctionSignature
  ) internal pure returns (ChainlinkLib.Run memory) {
    Buffer.init(self.buf, 128);
    self.specId = _specId;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = bytes4(keccak256(bytes(_callbackFunctionSignature)));
    self.buf.startMap();
    return self;
  }

  function encodeForOracle(
    Run memory self,
    uint256 _clArgsVersion
  ) internal pure returns (bytes memory) {
    return abi.encodeWithSelector(
      oracleRequestDataFid,
      0, // overridden by onTokenTransfer
      0, // overridden by onTokenTransfer
      _clArgsVersion,
      self.specId,
      self.callbackAddress,
      self.callbackFunctionId,
      self.requestId,
      self.buf.buf);
  }

  function encodeForCoordinator(
    Run memory self,
    uint256 _clArgsVersion
  ) internal pure returns (bytes memory) {
    return abi.encodeWithSelector(
      coordinatorRequestDataFid, // need to change
      0, // overridden by onTokenTransfer
      0, // overridden by onTokenTransfer
      _clArgsVersion,
      self.specId,
      self.callbackAddress,
      self.callbackFunctionId,
      self.requestId,
      self.buf.buf);
  }

  function add(Run memory self, string _key, string _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  function addBytes(Run memory self, string _key, bytes _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  function addInt(Run memory self, string _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  function addUint(Run memory self, string _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  function addStringArray(Run memory self, string _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }

  function close(Run memory self) internal pure {
    self.buf.endSequence();
  }
}

contract ENSResolver {
  function addr(bytes32 node) public view returns (address);
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


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external returns (bool success);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external returns (uint256 balance);
  function decimals() external returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external returns (string tokenName);
  function symbol() external returns (string tokenSymbol);
  function totalSupply() external returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

interface OracleInterface {
  function cancel(bytes32 externalId) external;
  function fulfillData(uint256 internalId, bytes32 data) external returns (bool);
  function requestData(
    address sender,
    uint256 amount,
    uint256 version,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    bytes32 externalId,
    bytes data
  ) external;
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Chainlinked {
  using ChainlinkLib for ChainlinkLib.Run;
  using SafeMath for uint256;

  uint256 constant private clArgsVersion = 1;
  uint256 constant private linkDivisibility = 10**18;

  LinkTokenInterface private link;
  OracleInterface private oracle;
  uint256 private requests = 1;
  mapping(bytes32 => address) private unfulfilledRequests;

  ENSInterface private ens;
  bytes32 private ensNode;
  bytes32 constant private ensTokenSubname = keccak256("link");
  bytes32 constant private ensOracleSubname = keccak256("oracle");

  event ChainlinkRequested(bytes32 id);
  event ChainlinkFulfilled(bytes32 id);
  event ChainlinkCancelled(bytes32 id);

  function newRun(
    bytes32 _specId,
    address _callbackAddress,
    string _callbackFunctionSignature
  ) internal pure returns (ChainlinkLib.Run memory) {
    ChainlinkLib.Run memory run;
    return run.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  function chainlinkRequest(ChainlinkLib.Run memory _run, uint256 _amount)
    internal
    returns (bytes32)
  {
    _run.requestId = bytes32(requests);
    requests += 1;
    _run.close();
    unfulfilledRequests[_run.requestId] = oracle;
    emit ChainlinkRequested(_run.requestId);
    require(link.transferAndCall(oracle, _amount, encodeForOracle(_run)), "unable to transferAndCall to oracle");

    return _run.requestId;
  }

  function cancelChainlinkRequest(bytes32 _requestId)
    internal
  {
    OracleInterface requested = OracleInterface(unfulfilledRequests[_requestId]);
    delete unfulfilledRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancel(_requestId);
  }

  function LINK(uint256 _amount) internal pure returns (uint256) {
    return _amount.mul(linkDivisibility);
  }

  function setOracle(address _oracle) internal {
    oracle = OracleInterface(_oracle);
  }

  function setLinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  function chainlinkToken()
    internal
    view
    returns (address)
  {
    return address(link);
  }

  function oracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

  function newChainlinkWithENS(address _ens, bytes32 _node)
    internal
    returns (address, address)
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    ENSResolver resolver = ENSResolver(ens.resolver(ensNode));
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ensTokenSubname));
    setLinkToken(resolver.addr(linkSubnode));
    return (link, updateOracleWithENS());
  }

  function updateOracleWithENS()
    internal
    returns (address)
  {
    ENSResolver resolver = ENSResolver(ens.resolver(ensNode));
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ensOracleSubname));
    setOracle(resolver.addr(oracleSubnode));
    return oracle;
  }

  function encodeForOracle(ChainlinkLib.Run memory self)
          internal
          view
          returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.requestData.selector,
      0, // overridden by onTokenTransfer
      0, // overridden by onTokenTransfer
      clArgsVersion,
      self.specId,
      self.callbackAddress,
      self.callbackFunctionId,
      self.requestId,
      self.buf.buf);
  }

  function serviceRequest(ChainlinkLib.Run memory _run, uint256 _amount)
    internal
    returns (bytes32)
  {
    _run.requestId = bytes32(requests);
    requests += 1;
    _run.close();
    unfulfilledRequests[_run.requestId] = oracle;
    emit ChainlinkRequested(_run.requestId);
    require(link.transferAndCall(oracle, _amount, _run.encodeForCoordinator(clArgsVersion)), "unable to transferAndCall to oracle");

    return _run.requestId;
  }

  modifier checkChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == unfulfilledRequests[_requestId], "source must be the oracle of the request");
    _;
    delete unfulfilledRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
  }
}

contract AssetPriceConsumer is Chainlinked, Ownable {

    bytes32 public jobId;

    event RequestFulfilled(
        bytes32 indexed requestId,
        uint256 price
    );

    mapping(bytes32 => bytes32) requests;
    mapping(bytes32 => uint256) prices;

    constructor(address _oracle, bytes32 _jobId) public {
        setLinkToken(0x20fE562d797A42Dcb3399062AE9546cd06f63280);
        setOracle(_oracle);
        jobId = _jobId;
    }

    function requestWeiPrice(string _base) public {
        requestPrice(_base, "ETH", 1 ether);
    }

    function requestSatsPrice(string _base) public {
        requestPrice(_base, "BTC", 100000000);
    }

    function requestUSDPrice(string _base) public {
        requestPrice(_base, "USD", 100);
    }

    function requestEURPrice(string _base) public {
        requestPrice(_base, "EUR", 100);
    }

    function requestPrice(string _base, string _quote, int _times) internal {
        ChainlinkLib.Run memory run = newRun(jobId, this, "fulfill(bytes32,uint256)");
        run.add("base", _base);
        run.add("quote", _quote);
        run.add("copyPath", "price");
        run.addInt("times", _times);
        bytes32 requestId = chainlinkRequest(run, LINK(1));
        requests[requestId] = keccak256(abi.encodePacked(_base, _quote));
    }

    function cancelRequest(bytes32 _requestId) public onlyOwner {
        cancelChainlinkRequest(_requestId);
    }

    function fulfill(bytes32 _requestId, uint256 _price)
    public
    checkChainlinkFulfillment(_requestId)
    {
        emit RequestFulfilled(_requestId, _price);
        prices[requests[_requestId]] = _price;
        delete requests[_requestId];
    }

}