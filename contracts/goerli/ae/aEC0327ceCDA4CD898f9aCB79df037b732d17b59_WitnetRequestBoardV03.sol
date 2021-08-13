/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

// File: contracts\interfaces\WitnetRequestBoardInterface.sol
/**
 * @title Witnet Requests Board Interface
 * @notice Interface of a Witnet Request Board (WRB)
 * It defines how to interact with the WRB in order to support:
 *  - Post and upgrade a data request
 *  - Read the result of a dr
 * @author Witnet Foundation
 */
interface WitnetRequestBoardInterface {

  /// @notice Event emitted when a new DR is posted
  event PostedRequest(uint256 id, address from);

  /// @notice Event emitted when a result is reported
  event PostedResult(uint256 id, address from);

  /// @notice Event emitted when a result is destroyed
  event DestroyedResult(uint256 id, address from);

  /// @notice Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the rewards.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns (uint256);

  /// @notice Retrieves result of previously posted DR, and removes it from storage.
  /// @param _id The unique identifier of a previously posted data request.
  /// @return The CBOR-encoded result of the DR.
  function destroyResult(uint256 _id) external returns (bytes memory);

  /// @notice Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns (uint256);

  /// @notice Retrieves the DR transaction hash of the _id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DR transaction
  function readDrTxHash(uint256 _id) external view returns (uint256);

  /// @notice Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult(uint256 _id) external view returns (bytes memory);

  /// @notice Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable;
 
}
// File: contracts\WitnetRequestBoard.sol
/**
 * @title Witnet Board functionality base contract.
 * @author Witnet Foundation
 **/
abstract contract WitnetRequestBoard is
    WitnetRequestBoardInterface
{
    receive() external payable {
        revert("WitnetRequestBoard: no transfers accepted");
    }
}
// File: contracts\patterns\Proxiable.sol
interface Proxiable {
    function proxiableUUID() external pure returns (bytes32);
}
// File: contracts\patterns\Initializable.sol
interface Initializable {
    /// @dev Initialize contract's storage-context.
    /// @dev Should fail when trying to initialize same contract instance more than once.
    function initialize(bytes calldata) external;

    /// @dev Notifies whenever a proxied-instance gets initialized. 
    event Initialized(
        address indexed from,
        address indexed baseAddr,
        bytes32 indexed baseCodehash,
        bytes32 versionTag
    );
}
// File: contracts\patterns\Upgradable.sol
/* solhint-disable var-name-mixedcase */




abstract contract Upgradable is Initializable, Proxiable {

    address internal immutable _BASE;
    bytes32 internal immutable _CODEHASH;
    bool internal immutable _UPGRADABLE;

    constructor (bool _isUpgradable) {
        address _base = address(this);
        bytes32 _codehash;        
        assembly {
            _codehash := extcodehash(_base)
        }
        _BASE = _base;
        _CODEHASH = _codehash;        
        _UPGRADABLE = _isUpgradable;
    }

    /// @dev Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address from) virtual external view returns (bool);


    /// TODO: the following methods should be all declared as pure 
    ///       whenever this Solidity's PR gets merged and released: 
    ///       https://github.com/ethereum/solidity/pull/10240

    /// @dev Retrieves base contract. Differs from address(this) when via delegate-proxy pattern.
    function base() public view returns (address) {
        return _BASE;
    }

    /// @dev Retrieves the immutable codehash of this contract, even if invoked as delegatecall.
    /// @return _codehash This contracts immutable codehash.
    function codehash() public view returns (bytes32 _codehash) {
        return _CODEHASH;
    }
    
    /// @dev Determines whether current instance allows being upgraded.
    /// @dev Returned value should be invariant from whoever is calling.
    function isUpgradable() public view returns (bool) {        
        return _UPGRADABLE;
    }

    /// @dev Retrieves human-redable named version of current implementation.
    function version() virtual public view returns (bytes32); 
}
// File: contracts\WitnetProxy.sol
/** @title WitnetProxy: upgradable delegate-proxy contract that routes Witnet data requests coming from a 
 * `UsingWitnet`-inheriting contract to a currently active `WitnetRequestBoard` implementation. 
 *
 * https://github.com/witnet/witnet-ethereum-bridge/tree/0.3.x
 *
 * Written in 2021 by the Witnet Foundation.
 **/
contract WitnetProxy {
  struct WitnetProxySlot {
    address implementation;
  }

  /// Event emitted when a new DR is posted.
  event Upgraded(address indexed implementation);  

  /// Constructor with no params as to ease eventual support of Singleton pattern (i.e. ERC-2470).
  constructor () {}

  /// WitnetProxies will never accept direct transfer of ETHs.
  receive() external payable {
    revert("WitnetProxy: no transfers accepted");
  }

  /// Payable fallback accepts delegating calls to payable functions.  
  fallback() external payable { /* solhint-disable no-complex-fallback */
    address _implementation = implementation();

    assembly { /* solhint-disable avoid-low-level-calls */
      // Gas optimized delegate call to 'implementation' contract.
      // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
      //       to actual implementation of `msg.sig` within `implementation` contract.
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)
      switch result
        case 0  { 
          // pass back revert message:
          revert(ptr, size) 
        }
        default {
          // pass back same data as returned by 'implementation' contract:
          return(ptr, size) 
        }
    }
  }

  /// Returns proxy's current implementation address.
  function implementation() public view returns (address) {
    return _proxySlot().implementation;
  }

  /// Upgrades the `implementation` address.
  /// @param _newImplementation New implementation address.
  /// @param _initData Raw data with which new implementation will be initialized.
  /// @return Returns whether new implementation would be further upgradable, or not.
  function upgradeTo(address _newImplementation, bytes memory _initData)
    public returns (bool)
  {
    // New implementation cannot be null:
    require(_newImplementation != address(0), "WitnetProxy: null implementation");

    address _oldImplementation = implementation();
    if (_oldImplementation != address(0)) {
      // New implementation address must differ from current one:
      require(_newImplementation != _oldImplementation, "WitnetProxy: nothing to upgrade");

      // Assert whether current implementation is intrinsically upgradable:
      try Upgradable(_oldImplementation).isUpgradable() returns (bool _isUpgradable) {
        require(_isUpgradable, "WitnetProxy: not upgradable");
      } catch {
        revert("WitnetProxy: unable to check upgradability");
      }

      // Assert whether current implementation allows `msg.sender` to upgrade the proxy:
      (bool _wasCalled, bytes memory _result) = _oldImplementation.delegatecall(
        abi.encodeWithSignature(
          "isUpgradableFrom(address)",
          msg.sender
        )
      );
      require(_wasCalled, "WitnetProxy: not compliant");
      require(abi.decode(_result, (bool)), "WitnetProxy: not authorized");
      require(
        Upgradable(_oldImplementation).proxiableUUID() == Upgradable(_newImplementation).proxiableUUID(),
        "WitnetProxy: proxiableUUIDs mismatch"
      );
    }

    // Initialize new implementation within proxy-context storage:
    (bool _wasInitialized,) = _newImplementation.delegatecall(
      abi.encodeWithSignature(
        "initialize(bytes)",
        _initData
      )
    );
    require(_wasInitialized, "WitnetProxy: unable to initialize");

    // If all checks and initialization pass, update implementation address:
    _proxySlot().implementation = _newImplementation;
    emit Upgraded(_newImplementation);

    // Asserts new implementation complies w/ minimal implementation of Upgradable interface:
    try Upgradable(_newImplementation).isUpgradable() returns (bool _isUpgradable) {
      return _isUpgradable;
    }
    catch {
      revert ("WitnetProxy: not compliant");
    }
  }

  /// @dev Complying with EIP-1967, retrieves storage struct containing proxy's current implementation address.
  function _proxySlot() private pure returns (WitnetProxySlot storage _slot) {
    assembly {
      // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      _slot.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    }
  }
}
// File: contracts\impls\WitnetBoardUpgradableBase.sol
/* solhint-disable var-name-mixedcase */

// Inherits from:




// Eventual deployment dependencies:


/**
 * @title Witnet Board base contract, with an Upgradable (and Destructible) touch.
 * @author Witnet Foundation
 **/
abstract contract WitnetBoardUpgradableBase
    is
        Proxiable,
        Upgradable,
        WitnetRequestBoard
{
    bytes32 internal immutable _VERSION;

    constructor(
            bool _upgradable,
            bytes32 _versionTag
        )
        Upgradable(_upgradable)
    {
        _VERSION = _versionTag;
    }

    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() external payable {
        revert("WitnetBoardUpgradableBase: not implemented");
    }

    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradable, contract.
    ///      If implemented as an Upgradable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    function proxiableUUID() external pure override returns (bytes32) {
        return (
            /* keccak256("io.witnet.proxiable.board") */
            0x9969c6aff411c5e5f0807500693e8f819ce88529615cfa6cab569b24788a1018
        );
    }   

    // ================================================================================================================
    // --- Overrides 'Upgradable' --------------------------------------------------------------------------------------

    /// Retrieves human-readable version tag of current implementation.
    function version() public view override returns (bytes32) {
        return _VERSION;
    }
}
// File: contracts\patterns\Destructible.sol
interface Destructible {
    function destroy() external;
}
// File: contracts\impls\WitnetBoardDestructibleBase.sol
/**
 * @title Witnet Board base contract, with an Upgradable (and Destructible) touch.
 * @author Witnet Foundation
 **/
abstract contract WitnetBoardDestructibleBase
    is
        Destructible,
        WitnetBoardUpgradableBase
{
    constructor(
            bool _upgradable,
            bytes32 _versionTag
        )
        WitnetBoardUpgradableBase(_upgradable, _versionTag)
    {}
}
// File: contracts\libs\WitnetData.sol
/**
 * @title Contract containing the serialized bytecode of a Witnet Radon script.
 */
contract WitnetRequest {
    bytes public bytecode;

  /**
    * @dev A `WitnetRequest` is constructed around a `bytes memory` value containing a well-formed Witnet data request serialized
    * using Protocol Buffers. However, we cannot verify its validity at this point. This implies that contracts using
    * the WRB should not be considered trustless before a valid Proof-of-Inclusion has been posted for the requests.
    * The hash of the request is computed in the constructor to guarantee consistency. Otherwise there could be a
    * mismatch and a data request could be resolved with the result of another.
    * @param _bytecode Actual Radon script in bytes.
    */
    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
    }
}

library WitnetData {

    /// Witnet lambda function that computes the hash of a CBOR-encoded RADON script.
    /// @param _bytecode CBOR-encoded RADON.
    function computeScriptCodehash(bytes memory _bytecode) internal pure returns (uint256) {
        return uint256(sha256(_bytecode));
    }

    /// @notice Data kept in EVM-storage for every Data Request (DR) posted to Witnet.
    struct Query {
        address requestor;  // Address from which the DR was posted.
        address script;     // WitnetRequest contract address.        
        uint256 codehash;   // Codehash of the DR.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // escrow reward to by paid to the DR resolver.
        uint256 txhash;     // Hash of the Witnet tx that actually solved the DR.
    }

    /// @notice DR result data provided by Witnet.
    struct Result {
        bool success;       // Resolution was successful.
        CBOR value;         // Resulting value encoded as a Concise Binary Object Representation (CBOR).
    }

    /// @notice Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// @notice Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// @notice Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid RADON script.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }
}
// File: contracts\data\WitnetBoardData.sol
/**
 * @title Witnet Board base data model. 
 * @author Witnet Foundation
 */
abstract contract WitnetBoardData {  

  struct WitnetBoardState {
    address base;
    address owner;    
    uint256 numRecords;
    mapping (uint => WitnetBoardDataRequest) requests;
  }

  struct WitnetBoardDataRequest {
    WitnetData.Query query;
    bytes result;
  }

  constructor() {
    _state().owner = msg.sender;
  }

  modifier notDestroyed(uint256 _id) {
    require(_id > 0 && _id <= _state().numRecords, "WitnetBoardData: not yet posted");
    require(_getRequestQuery(_id).requestor != address(0), "WitnetBoardData: destroyed");
    _;
  }

  modifier onlyOwner {
    require(msg.sender == _state().owner, "WitnetBoardData: only owner");
    _;    
  }

  modifier resultNotYetReported(uint256 _id) {
    require(_getRequestQuery(_id).txhash == 0, "WitnetBoardData: already solved");
    _;
  }

  modifier wasPosted(uint256 _id) {
    require(_id > 0 && _id <= _state().numRecords, "WitnetBoardData: not yet posted");
    _;
  }

  /// Gets admin/owner address.
  function owner() public view returns (address) {
    return _state().owner;
  }

  /// Returns storage pointer to contents of 'WitnetBoardState' struct.
  function _state()
    internal pure
    returns (WitnetBoardState storage _ptr)
  {
    assembly {
      _ptr.slot := WITNET_BOARD_DATA_SLOTHASH
    }
  }

  /// Gets WitnetData.Query struct contents of given request.
  function _getRequestQuery(uint256 _requestId)
    internal view
    returns (WitnetData.Query storage)
  {
    return _state().requests[_requestId].query;
  }
  
  bytes32 internal constant WITNET_BOARD_DATA_SLOTHASH =
    /* keccak256("io.witnet.board.data") */
    0x641d5bbf2c42118a382e660df7903a98dce7b5bb834d3ba9beae1890b2a72054;
}
// File: contracts\data\WitnetBoardDataACLs.sol
/**
 * @title Witnet Access Control Lists storage layout, for Witnet-trusted request boards.
 * @author Witnet Foundation
 */
abstract contract WitnetBoardDataACLs is WitnetBoardData {  
  struct WitnetBoardACLs {
    mapping (address => bool) isReporter_;
  }

  constructor() {
    _acls().isReporter_[msg.sender] = true;
  }

  modifier onlyReporters {
    require(_acls().isReporter_[msg.sender], "WitnetBoardDataACLs: unauthorized reporter");
    _;
  }  

  function _acls() internal pure returns (WitnetBoardACLs storage _struct) {
    assembly {
      _struct.slot := WITNET_BOARD_ACLS_SLOTHASH
    }
  }
  
  bytes32 internal constant WITNET_BOARD_ACLS_SLOTHASH =
    /* keccak256("io.witnet.board.data.acls") */
    0xcd72f56a6985e636b405ff061ec7e64e5428b269bdf2efabdd134b36b111d605;
}
// File: contracts\impls\trustable\WitnetRequestBoardV03.sol
/**
 * @title Witnet Requests Board V03
 * @notice Contract to bridge requests to Witnet Decenetralized Oracle Network.
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
 * The result of the requests will be posted back to this contract by the bridge nodes too.
 * @author Witnet Foundation
 */
contract WitnetRequestBoardV03
    is 
        WitnetBoardDataACLs,
        WitnetBoardDestructibleBase
{
    uint256 internal constant _ESTIMATED_REPORT_RESULT_GAS = 102496;
    
    constructor(bool _upgradable, bytes32 _versionTag)
        WitnetBoardDestructibleBase(_upgradable, _versionTag)
    {}

    // ================================================================================================================
    // --- Overrides 'Destructible' -----------------------------------------------------------------------------------

    /// Destroys current instance. Only callable by the owner.
    function destroy() external override onlyOwner {
        selfdestruct(payable(msg.sender));
    }


    // ================================================================================================================
    // --- Overrides 'Upgradable' -------------------------------------------------------------------------------------

    /// Initialize storage-context when invoked as delegatecall. 
    /// Should fail when trying to initialize same instance more than once.
    function initialize(bytes memory _initData) virtual external override {
        address _owner = _state().owner;
        if (_owner == address(0)) {
            // set owner if none set yet
            _owner = msg.sender;
            _state().owner = _owner;
        } else {
            // only owner can initialize:
            require(msg.sender == _owner, "WitnetRequestBoard: only owner");
        }        

        if (_state().base != address(0)) {
            // current implementation cannot be initialized more than once:
            require(_state().base != base(), "WitnetRequestBoard: already initialized");
        }        
        _state().base = base();

        emit Initialized(msg.sender, base(), codehash(), version());

        // Do actual base initialization:
        setReporters(abi.decode(_initData, (address[])));
    }

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        address _owner = _state().owner;
        return (
            // false if the WRB is intrinsically not upgradable
            isUpgradable() && (                
                _owner == address(0) ||
                _owner == _from
            )
        );
    }


    // ================================================================================================================
    // --- Utility functions not declared within an interface ---------------------------------------------------------

    /// Retrieves the whole DR post record from the WRB.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return The DR record. Fails if DR current bytecode differs from the one it had when posted.
    function readDr(uint256 _id)
        external view
        virtual
        wasPosted(_id)
        returns (WitnetData.Query memory)
    {
        return _checkDr(_id);
    }
    
    /// Retrieves the Radon script bytecode of a previously posted DR. Fails if changed after being posted. 
    /// @param _id The unique identifier of the previously posted DR.
    /// @return _bytecode The Radon script bytecode. Empty if the DR was already solved and destroyed.
    function readDataRequest(uint256 _id)
        external view
        virtual
        wasPosted(_id)
        returns (bytes memory _bytecode)
    {
        WitnetData.Query storage _dr = _getRequestQuery(_id);
        if (_dr.script != address(0)) {
            // if DR's request contract address is not zero,
            // we assume the DR has not been destroyed, so
            // DR's bytecode can still be fetched:
            _bytecode = WitnetRequest(_dr.script).bytecode();
            require(
                WitnetData.computeScriptCodehash(_bytecode) == _dr.codehash,
                "WitnetRequestBoard: bytecode changed after posting"
            );
        } 
    }

    /// Retrieves the gas price set for a previously posted DR.
    /// @param _id The unique identifier of a previously posted DR.
    /// @return The latest gas price set by either the DR requestor, or upgrader.
    function readGasPrice(uint256 _id)
        external view
        virtual
        wasPosted(_id)
        returns (uint256)
    {
        return _getRequestQuery(_id).gasprice;
    }

    /// Reports the result of a data request solved by Witnet network.
    /// @param _id The unique identifier of the data request.
    /// @param _txhash Hash of the solving tally transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _id,
            uint256 _txhash,
            bytes calldata _result
        )
        external
        virtual
        onlyReporters
        notDestroyed(_id)
        resultNotYetReported(_id)
    {
        require(_txhash != 0, "WitnetRequestBoard: Witnet tally tx hash cannot be zero");
        // Ensures the result byes do not have zero length
        // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
        require(_result.length != 0, "WitnetRequestBoard: result cannot be empty");

        WitnetBoardDataRequest storage _record = _state().requests[_id];
        _record.query.txhash = _txhash;
        _record.result = _result;

        emit PostedResult(_id, msg.sender);
        payable(msg.sender).transfer(_record.query.reward);
    }
    
    /// Returns the number of posted data requests in the WRB.
    /// @return The number of posted data requests in the WRB.
    function requestsCount() external virtual view returns (uint256) {
        // TODO: either rename this method (e.g. getNextId()) or change bridge node 
        //       as to interpret returned value as actual number of posted data requests 
        //       in the WRB.
        return _state().numRecords + 1;
    }

    /// @dev Adds given addresses to the active reporters control list.
    /// @param _reporters List of addresses to be added to the active reporters control list.
    function setReporters(address[] memory _reporters)
        public
        virtual
        onlyOwner
    {
        for (uint ix = 0; ix < _reporters.length; ix ++) {
            address _reporter = _reporters[ix];
            _acls().isReporter_[_reporter] = true;
        }
    }

    
    // ================================================================================================================
    // --- Implements 'WitnetRequestBoardInterface' -------------------------------------------------------------------

    /// Estimate the minimal amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    /// @return The minimal reward to be included for the given gas price.
    function estimateGasCost(uint256 _gasPrice)
        external pure
        virtual override
        returns (uint256)
    {
        // TODO: consider renaming this method as `estimateMinimalReward(uint256 _gasPrice)`
        return _gasPrice * _ESTIMATED_REPORT_RESULT_GAS;
    }

    /// Retrieves result of previously posted DR, and removes it from storage.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return _result The CBOR-encoded result of the DR.
    function destroyResult(uint256 _id)
        external
        virtual override
        returns (bytes memory _result)
    {
        WitnetBoardDataRequest storage _record = _state().requests[_id];
        require(msg.sender == _record.query.requestor, "WitnetRequestBoard: only actual requestor");
        require(_record.query.txhash != 0, "WitnetRequestBoard: not yet solved");
        _result = _record.result;
        delete _state().requests[_id];
        emit DestroyedResult(_id, msg.sender);
    }

    /// Posts a data request into the WRB in expectation that it will be relayed
    /// and resolved in Witnet with a total reward that equals to msg.value.
    /// @param _requestAddr The Witnet request contract address which provides actual RADON bytecode.
    /// @return _id The unique identifier of the posted DR.
    function postDataRequest(address _requestAddr)
        public payable
        virtual override
        returns (uint256 _id)
    {
        require(_requestAddr != address(0), "WitnetRequestBoard: null request");

        // Checks the tally reward is covering gas cost
        uint256 minResultReward = tx.gasprice * _ESTIMATED_REPORT_RESULT_GAS;
        require(msg.value >= minResultReward, "WitnetRequestBoard: reward too low");

        _id = ++ _state().numRecords;
        WitnetData.Query storage _dr = _getRequestQuery(_id);

        _dr.script = _requestAddr;
        _dr.requestor = msg.sender;
        _dr.codehash = WitnetData.computeScriptCodehash(
            WitnetRequest(_requestAddr).bytecode()
        );
        _dr.gasprice = tx.gasprice;
        _dr.reward = msg.value;

        // Let observers know that a new request has been posted
        emit PostedRequest(_id, msg.sender);
    }
    
    /// Retrieves Witnet tx hash of a previously solved DR.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return The hash of the DataRequest transaction in Witnet.
    function readDrTxHash(uint256 _id)
        external view        
        virtual override
        wasPosted(_id)
        returns (uint256)
    {
        return _getRequestQuery(_id).txhash;
    }
    
    /// Retrieves the result (if already available) of one data request from the WRB.
    /// @param _id The unique identifier of the data request.
    /// @return The result of the DR.
    function readResult(uint256 _id)
        external view
        virtual override        
        wasPosted(_id)
        returns (bytes memory)
    {
        WitnetBoardDataRequest storage _record = _state().requests[_id];
        require(_record.query.txhash != 0, "WitnetRequestBoard: not yet solved");
        return _record.result;
    }    

    /// Increments the reward of a data request by adding the transaction value to it.
    /// @param _id The unique identifier of a previously posted data request.
    function upgradeDataRequest(uint256 _id)
        external payable
        virtual override        
        wasPosted(_id)
    {
        WitnetData.Query storage _dr = _getRequestQuery(_id);
        require(_dr.txhash == 0, "WitnetRequestBoard: already solved");

        uint256 _newReward = _dr.reward + msg.value;

        // If gas price is increased, then check if new rewards cover gas costs
        if (tx.gasprice > _dr.gasprice) {
            // Checks the reward is covering gas cost
            uint256 _minResultReward = tx.gasprice * _ESTIMATED_REPORT_RESULT_GAS;
            require(
                _newReward >= _minResultReward,
                "WitnetRequestBoard: reward too low"
            );
            _dr.gasprice = tx.gasprice;
        }
        _dr.reward = _newReward;
    }


    // ================================================================================================================
    // --- Private functions ------------------------------------------------------------------------------------------

    function _checkDr(uint256 _id)
        private view returns (WitnetData.Query storage _dr)
    {
        _dr = _getRequestQuery(_id);
        if (_dr.script != address(0)) {
            // if DR's request contract address is not zero,
            // we assume the DR has not been destroyed, so
            // DR's bytecode can still be fetched:
            bytes memory _bytecode = WitnetRequest(_dr.script).bytecode();
            require(
                WitnetData.computeScriptCodehash(_bytecode) == _dr.codehash,
                "WitnetRequestBoard: bytecode changed after posting"
            );
        }        
    }
}