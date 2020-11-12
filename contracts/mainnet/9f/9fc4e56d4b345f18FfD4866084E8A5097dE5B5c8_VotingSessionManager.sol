/**************************************************************************
 *            ____        _                              
 *           / ___|      | |     __ _  _   _   ___  _ __ 
 *          | |    _____ | |    / _` || | | | / _ \| '__|
 *          | |___|_____|| |___| (_| || |_| ||  __/| |   
 *           \____|      |_____|\__,_| \__, | \___||_|   
 *                                     |___/             
 * 
 **************************************************************************
 *
 *  The MIT License (MIT)
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2020 Cyril Lapinte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************
 *
 * Flatten Contract: VotingSessionManager
 *
 * Git Commit:
 * https://github.com/c-layer/contracts/commit/9993912325afde36151b04d0247ac9ea9ffa2a93
 *
 **************************************************************************/


// File: @c-layer/common/contracts/call/DelegateCall.sol

pragma solidity ^0.6.0;


/**
 * @title DelegateCall
 * @dev Calls delegates for non view functions only
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error Messages:
 **/
library DelegateCall {

  function _delegateCall(address _delegate) internal virtual returns (bool status)
  {
    bytes memory result;
    // solhint-disable-next-line avoid-low-level-calls
    (status, result) = _delegate.delegatecall(msg.data);
    require(status, string(result));
  }

  function _delegateCallBool(address _delegate) internal returns (bool status)
  {
    return abi.decode(_delegateCallBytes(_delegate), (bool));
  }

  function _delegateCallUint256(address _delegate) internal returns (uint256)
  {
    return abi.decode(_delegateCallBytes(_delegate), (uint256));
  }

  function _delegateCallBytes(address _delegate)
    internal returns (bytes memory result)
  {
    bool status;
    // solhint-disable-next-line avoid-low-level-calls
    (status, result) = _delegate.delegatecall(msg.data);
    require(status, string(result));
  }
}

// File: @c-layer/common/contracts/call/DelegateCallView.sol

pragma solidity ^0.6.0;


/**
 * @title DelegateCallView
 * @dev Calls delegates for view and non view functions
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error Messages:
 *   DV01: Cannot call forwardCallBytes directly
 **/
contract DelegateCallView {

  bytes4 internal constant FORWARD_CALL_BYTES = bytes4(keccak256("forwardCallBytes(address,bytes)"));

  function _delegateCallBool(address _delegate)
    internal view returns (bool)
  {
    return abi.decode(_delegateCallBytes(_delegate), (bool));
  }

  function _delegateCallUint256(address _delegate)
    internal view returns (uint256)
  {
    return abi.decode(_delegateCallBytes(_delegate), (uint256));
  }

  function _delegateCallBytes(address _delegate)
    internal view returns (bytes memory result)
  {
    bool status;
    (status, result) = address(this).staticcall(
      abi.encodeWithSelector(FORWARD_CALL_BYTES, _delegate, msg.data));
    require(status, string(result));
    result = abi.decode(result, (bytes));
  }

  /**
   * @dev enforce static immutability (view)
   * @dev in order to read delegate value through internal delegateCall
   */
  function forwardCallBytes(address _delegate, bytes memory _data)
    public returns (bytes memory result)
  {
    require(msg.sender == address(this), "DV01");
    bool status;
    // solhint-disable-next-line avoid-low-level-calls
    (status, result) = _delegate.delegatecall(_data);
    require(status, string(result));
  }
}

// File: @c-layer/common/contracts/operable/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * @dev functions, this simplifies the implementation of "user permissions".
 *
 *
 * Error messages
 *   OW01: Message sender is not the owner
 *   OW02: New owner must be valid
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
    require(msg.sender == owner, "OW01");
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
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
    require(_newOwner != address(0), "OW02");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: @c-layer/common/contracts/interface/IERC20.sol

pragma solidity ^0.6.0;


/**
 * @title IERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://github.com/ethereum/EIPs/issues/179
 *
 */
interface IERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function increaseApproval(address _spender, uint256 _addedValue)
    external returns (bool);

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    external returns (bool);
}

// File: @c-layer/common/contracts/interface/IProxy.sol

pragma solidity ^0.6.0;

/**
 * @title IProxy
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 **/
interface IProxy {

  function core() external view returns (address);

}

// File: @c-layer/common/contracts/core/Proxy.sol

pragma solidity ^0.6.0;



/**
 * @title Proxy
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   PR01: Only accessible by core
 *   PR02: Core request should be successful
 **/
contract Proxy is IProxy {

  address public override core;

  /**
   * @dev Throws if called by any account other than a core
   */
  modifier onlyCore {
    require(core == msg.sender, "PR01");
    _;
  }

  constructor(address _core) public {
    core = _core;
  }

  /**
   * @dev update the core
   */
  function updateCore(address _core)
    public onlyCore returns (bool)
  {
    core = _core;
    return true;
  }

  /**
   * @dev enforce static immutability (view)
   * @dev in order to read core value through internal core delegateCall
   */
  function staticCallUint256() internal view returns (uint256 value) {
    (bool status, bytes memory result) = core.staticcall(msg.data);
    require(status, string(result));
    value = abi.decode(result, (uint256));
  }
}

// File: @c-layer/token/contracts/interface/ITokenProxy.sol

pragma solidity ^0.6.0;




/**
 * @title IToken proxy
 * @dev Token proxy interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
abstract contract ITokenProxy is IERC20, Proxy {

  function canTransfer(address, address, uint256)
    virtual public view returns (uint256);

  function emitTransfer(address _from, address _to, uint256 _value)
    virtual public returns (bool);

  function emitApproval(address _owner, address _spender, uint256 _value)
    virtual public returns (bool);
}

// File: contracts/interface/IVotingDefinitions.sol

pragma solidity ^0.6.0;


/**
 * @title IVotingDefinitions
 * @dev IVotingDefinitions interface
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IVotingDefinitions {

  address internal constant ANY_TARGET = address(bytes20("AnyTarget"));
  bytes4 internal constant ANY_METHOD = bytes4(bytes32("AnyMethod"));

  enum SessionState {
    UNDEFINED,
    PLANNED,
    CAMPAIGN,
    VOTING,
    EXECUTION,
    GRACE,
    CLOSED,
    ARCHIVED
  }

  enum ProposalState {
    UNDEFINED,
    DEFINED,
    CANCELLED,
    LOCKED,
    APPROVED,
    REJECTED,
    RESOLVED,
    CLOSED,
    ARCHIVED
  }

  // 4 digits precisions on percentage values
  uint256 internal constant PERCENT = 1000000;

  uint64 internal constant MIN_PERIOD_LENGTH = 200;
  // MAX_PERIOD_LENGTH (approx 10000 years) protects against period overflow
  uint64 internal constant MAX_PERIOD_LENGTH = 3652500 days;
  uint64 internal constant CAMPAIGN_PERIOD = 5 days;
  uint64 internal constant VOTING_PERIOD = 2 days;
  uint64 internal constant EXECUTION_PERIOD = 1 days;
  uint64 internal constant GRACE_PERIOD = 6 days;
  uint64 internal constant OFFSET_PERIOD = 2 days;

  // Proposal requirements in percent
  uint256 internal constant NEW_PROPOSAL_THRESHOLD = 1;
  uint256 internal constant DEFAULT_EXECUTION_THRESHOLD = 1;
  uint128 internal constant DEFAULT_MAJORITY = 500000; // 50%
  uint128 internal constant DEFAULT_QUORUM = 200000; // 20%

  uint8 internal constant OPEN_PROPOSALS = 5;
  uint8 internal constant MAX_PROPOSALS = 20;
  uint8 internal constant MAX_PROPOSALS_OPERATOR = 25;

  uint256 internal constant SESSION_RETENTION_PERIOD = 365 days;
  uint256 internal constant SESSION_RETENTION_COUNT = 10;
}

// File: @c-layer/common/contracts/interface/IAccessDefinitions.sol

pragma solidity ^0.6.0;


/**
 * @title IAccessDefinitions
 * @dev IAccessDefinitions
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
contract IAccessDefinitions {

  // Hardcoded role granting all - non sysop - privileges
  bytes32 internal constant ALL_PRIVILEGES = bytes32("AllPrivileges");
  address internal constant ALL_PROXIES = address(0x416c6C50726F78696573); // "AllProxies"

  // Roles
  bytes32 internal constant FACTORY_CORE_ROLE = bytes32("FactoryCoreRole");
  bytes32 internal constant FACTORY_PROXY_ROLE = bytes32("FactoryProxyRole");

  // Sys Privileges
  bytes4 internal constant DEFINE_ROLE_PRIV =
    bytes4(keccak256("defineRole(bytes32,bytes4[])"));
  bytes4 internal constant ASSIGN_OPERATORS_PRIV =
    bytes4(keccak256("assignOperators(bytes32,address[])"));
  bytes4 internal constant REVOKE_OPERATORS_PRIV =
    bytes4(keccak256("revokeOperators(address[])"));
  bytes4 internal constant ASSIGN_PROXY_OPERATORS_PRIV =
    bytes4(keccak256("assignProxyOperators(address,bytes32,address[])"));
}

// File: @c-layer/common/contracts/interface/IOperableStorage.sol

pragma solidity ^0.6.0;



/**
 * @title IOperableStorage
 * @dev The Operable storage
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IOperableStorage is IAccessDefinitions {
  function proxyDelegateId(address _proxy) virtual public view returns (uint256);
  function delegate(uint256 _delegateId) virtual public view returns (address);

  function coreRole(address _address) virtual public view returns (bytes32);
  function proxyRole(address _proxy, address _address) virtual public view returns (bytes32);
  function rolePrivilege(bytes32 _role, bytes4 _privilege) virtual public view returns (bool);
  function roleHasPrivilege(bytes32 _role, bytes4 _privilege) virtual public view returns (bool);
  function hasCorePrivilege(address _address, bytes4 _privilege) virtual public view returns (bool);
  function hasProxyPrivilege(address _address, address _proxy, bytes4 _privilege) virtual public view returns (bool);

  event RoleDefined(bytes32 role);
  event OperatorAssigned(bytes32 role, address operator);
  event ProxyOperatorAssigned(address proxy, bytes32 role, address operator);
  event OperatorRevoked(address operator);
  event ProxyOperatorRevoked(address proxy, address operator);

  event ProxyDefined(address proxy, uint256 delegateId);
  event ProxyMigrated(address proxy, address newCore);
  event ProxyRemoved(address proxy);
}

// File: @c-layer/common/contracts/interface/IOperableCore.sol

pragma solidity ^0.6.0;



/**
 * @title IOperableCore
 * @dev The Operable contract enable the restrictions of operations to a set of operators
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IOperableCore is IOperableStorage {
  function defineRole(bytes32 _role, bytes4[] memory _privileges) virtual public returns (bool);
  function assignOperators(bytes32 _role, address[] memory _operators) virtual public returns (bool);
  function assignProxyOperators(
    address _proxy, bytes32 _role, address[] memory _operators) virtual public returns (bool);
  function revokeOperators(address[] memory _operators) virtual public returns (bool);
  function revokeProxyOperators(address _proxy, address[] memory _operators) virtual public returns (bool);

  function defineProxy(address _proxy, uint256 _delegateId) virtual public returns (bool);
  function migrateProxy(address _proxy, address _newCore) virtual public returns (bool);
  function removeProxy(address _proxy) virtual public returns (bool);
}

// File: @c-layer/oracle/contracts/interface/IUserRegistry.sol

pragma solidity ^0.6.0;


/**
 * @title IUserRegistry
 * @dev IUserRegistry interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 **/
abstract contract IUserRegistry {

  enum KeyCode {
    KYC_LIMIT_KEY,
    RECEPTION_LIMIT_KEY,
    EMISSION_LIMIT_KEY
  }

  event UserRegistered(uint256 indexed userId, address address_, uint256 validUntilTime);
  event AddressAttached(uint256 indexed userId, address address_);
  event AddressDetached(uint256 indexed userId, address address_);
  event UserSuspended(uint256 indexed userId);
  event UserRestored(uint256 indexed userId);
  event UserValidity(uint256 indexed userId, uint256 validUntilTime);
  event UserExtendedKey(uint256 indexed userId, uint256 key, uint256 value);
  event UserExtendedKeys(uint256 indexed userId, uint256[] values);
  event ExtendedKeysDefinition(uint256[] keys);

  function registerManyUsersExternal(address[] calldata _addresses, uint256 _validUntilTime)
    virtual external returns (bool);
  function registerManyUsersFullExternal(
    address[] calldata _addresses,
    uint256 _validUntilTime,
    uint256[] calldata _values) virtual external returns (bool);
  function attachManyAddressesExternal(uint256[] calldata _userIds, address[] calldata _addresses)
    virtual external returns (bool);
  function detachManyAddressesExternal(address[] calldata _addresses)
    virtual external returns (bool);
  function suspendManyUsersExternal(uint256[] calldata _userIds) virtual external returns (bool);
  function restoreManyUsersExternal(uint256[] calldata _userIds) virtual external returns (bool);
  function updateManyUsersExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended) virtual external returns (bool);
  function updateManyUsersExtendedExternal(
    uint256[] calldata _userIds,
    uint256 _key, uint256 _value) virtual external returns (bool);
  function updateManyUsersAllExtendedExternal(
    uint256[] calldata _userIds,
    uint256[] calldata _values) virtual external returns (bool);
  function updateManyUsersFullExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] calldata _values) virtual external returns (bool);

  function name() virtual public view returns (string memory);
  function currency() virtual public view returns (bytes32);

  function userCount() virtual public view returns (uint256);
  function userId(address _address) virtual public view returns (uint256);
  function validUserId(address _address) virtual public view returns (uint256);
  function validUser(address _address, uint256[] memory _keys)
    virtual public view returns (uint256, uint256[] memory);
  function validity(uint256 _userId) virtual public view returns (uint256, bool);

  function extendedKeys() virtual public view returns (uint256[] memory);
  function extended(uint256 _userId, uint256 _key)
    virtual public view returns (uint256);
  function manyExtended(uint256 _userId, uint256[] memory _key)
    virtual public view returns (uint256[] memory);

  function isAddressValid(address _address) virtual public view returns (bool);
  function isValid(uint256 _userId) virtual public view returns (bool);

  function defineExtendedKeys(uint256[] memory _extendedKeys) virtual public returns (bool);

  function registerUser(address _address, uint256 _validUntilTime)
    virtual public returns (bool);
  function registerUserFull(
    address _address,
    uint256 _validUntilTime,
    uint256[] memory _values) virtual public returns (bool);

  function attachAddress(uint256 _userId, address _address) virtual public returns (bool);
  function detachAddress(address _address) virtual public returns (bool);
  function detachSelf() virtual public returns (bool);
  function detachSelfAddress(address _address) virtual public returns (bool);
  function suspendUser(uint256 _userId) virtual public returns (bool);
  function restoreUser(uint256 _userId) virtual public returns (bool);
  function updateUser(uint256 _userId, uint256 _validUntilTime, bool _suspended)
    virtual public returns (bool);
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    virtual public returns (bool);
  function updateUserAllExtended(uint256 _userId, uint256[] memory _values)
    virtual public returns (bool);
  function updateUserFull(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] memory _values) virtual public returns (bool);
}

// File: @c-layer/oracle/contracts/interface/IRatesProvider.sol

pragma solidity ^0.6.0;


/**
 * @title IRatesProvider
 * @dev IRatesProvider interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
abstract contract IRatesProvider {

  function defineRatesExternal(uint256[] calldata _rates) virtual external returns (bool);

  function name() virtual public view returns (string memory);

  function rate(bytes32 _currency) virtual public view returns (uint256);

  function currencies() virtual public view
    returns (bytes32[] memory, uint256[] memory, uint256);
  function rates() virtual public view returns (uint256, uint256[] memory);

  function convert(uint256 _amount, bytes32 _fromCurrency, bytes32 _toCurrency)
    virtual public view returns (uint256);

  function defineCurrencies(
    bytes32[] memory _currencies,
    uint256[] memory _decimals,
    uint256 _rateOffset) virtual public returns (bool);
  function defineRates(uint256[] memory _rates) virtual public returns (bool);

  event RateOffset(uint256 rateOffset);
  event Currencies(bytes32[] currencies, uint256[] decimals);
  event Rate(bytes32 indexed currency, uint256 rate);
}

// File: @c-layer/token/contracts/interface/IRule.sol

pragma solidity ^0.6.0;


/**
 * @title IRule
 * @dev IRule interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 **/
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

// File: @c-layer/token/contracts/interface/ITokenStorage.sol

pragma solidity ^0.6.0;





/**
 * @title ITokenStorage
 * @dev Token storage interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
abstract contract ITokenStorage {
  enum TransferCode {
    UNKNOWN,
    OK,
    INVALID_SENDER,
    NO_RECIPIENT,
    INSUFFICIENT_TOKENS,
    LOCKED,
    FROZEN,
    RULE,
    INVALID_RATE,
    NON_REGISTRED_SENDER,
    NON_REGISTRED_RECEIVER,
    LIMITED_EMISSION,
    LIMITED_RECEPTION
  }

  enum Scope {
    DEFAULT
  }

  enum AuditStorageMode {
    ADDRESS,
    USER_ID,
    SHARED
  }

  enum AuditTriggerMode {
    UNDEFINED,
    NONE,
    SENDER_ONLY,
    RECEIVER_ONLY,
    BOTH
  }

  address internal constant ANY_ADDRESSES = address(0x416e79416464726573736573); // "AnyAddresses"

  event OracleDefined(
    IUserRegistry userRegistry,
    IRatesProvider ratesProvider,
    address currency);
  event TokenDelegateDefined(uint256 indexed delegateId, address delegate, uint256[] configurations);
  event TokenDelegateRemoved(uint256 indexed delegateId);
  event AuditConfigurationDefined(
    uint256 indexed configurationId,
    uint256 scopeId,
    AuditTriggerMode mode,
    uint256[] senderKeys,
    uint256[] receiverKeys,
    IRatesProvider ratesProvider,
    address currency);
  event AuditTriggersDefined(
    uint256 indexed configurationId,
    address[] senders,
    address[] receivers,
    AuditTriggerMode[] modes);
  event AuditsRemoved(address scope, uint256 scopeId);
  event SelfManaged(address indexed holder, bool active);

  event Minted(address indexed token, uint256 amount);
  event MintFinished(address indexed token);
  event Burned(address indexed token, uint256 amount);
  event RulesDefined(address indexed token, IRule[] rules);
  event LockDefined(
    address indexed lock,
    address sender,
    address receiver,
    uint256 startAt,
    uint256 endAt
  );
  event Seize(address indexed token, address account, uint256 amount);
  event Freeze(address address_, uint256 until);
  event ClaimDefined(
    address indexed token,
    address indexed claim,
    uint256 claimAt);
  event TokenLocksDefined(
    address indexed token,
    address[] locks);
  event TokenDefined(
    address indexed token,
    string name,
    string symbol,
    uint256 decimals);
  event LogTransferData(
    address token, address caller, address sender, address receiver,
    uint256 senderId, uint256[] senderKeys, bool senderFetched,
    uint256 receiverId, uint256[] receiverKeys, bool receiverFetched,
    uint256 value, uint256 convertedValue);
  event LogTransferAuditData(
    uint256 auditConfigurationId, uint256 scopeId,
    address currency, IRatesProvider ratesProvider,
    bool senderAuditRequired, bool receiverAuditRequired);
  event LogAuditData(
    uint64 createdAt, uint64 lastTransactionAt,
    uint256 cumulatedEmission, uint256 cumulatedReception
  );
}

// File: @c-layer/token/contracts/interface/ITokenCore.sol

pragma solidity ^0.6.0;




/**
 * @title ITokenCore
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 **/
abstract contract ITokenCore is ITokenStorage, IOperableCore {

  function name() virtual public view returns (string memory);
  function oracle() virtual public view returns (
    IUserRegistry userRegistry,
    IRatesProvider ratesProvider,
    address currency);

  function auditConfiguration(uint256 _configurationId)
    virtual public view returns (
      uint256 scopeId,
      AuditTriggerMode _mode,
      uint256[] memory senderKeys,
      uint256[] memory receiverKeys,
      IRatesProvider ratesProvider,
      address currency);
  function auditTrigger(uint256 _configurationId, address _sender, address _receiver)
    virtual public view returns (AuditTriggerMode);
  function delegatesConfigurations(uint256 _delegateId)
    virtual public view returns (uint256[] memory);

  function auditCurrency(
    address _scope,
    uint256 _scopeId
  ) virtual external view returns (address currency);
  function audit(
    address _scope,
    uint256 _scopeId,
    AuditStorageMode _storageMode,
    bytes32 _storageId) virtual external view returns (
    uint64 createdAt,
    uint64 lastTransactionAt,
    uint256 cumulatedEmission,
    uint256 cumulatedReception);

  /**************  ERC20  **************/
  function tokenName() virtual external view returns (string memory);
  function tokenSymbol() virtual external view returns (string memory);

  function decimals() virtual external returns (uint256);
  function totalSupply() virtual external returns (uint256);
  function balanceOf(address) virtual external returns (uint256);
  function allowance(address, address) virtual external returns (uint256);
  function transfer(address, address, uint256)
    virtual external returns (bool status);
  function transferFrom(address, address, address, uint256)
    virtual external returns (bool status);
  function approve(address, address, uint256)
    virtual external returns (bool status);
  function increaseApproval(address, address, uint256)
    virtual external returns (bool status);
  function decreaseApproval(address, address, uint256)
    virtual external returns (bool status);

  /***********  TOKEN DATA   ***********/
  function token(address _token) virtual external view returns (
    bool mintingFinished,
    uint256 allTimeMinted,
    uint256 allTimeBurned,
    uint256 allTimeSeized,
    address[] memory locks,
    uint256 freezedUntil,
    IRule[] memory);
  function lock(address _lock, address _sender, address _receiver) virtual external view returns (
    uint64 startAt, uint64 endAt);
  function canTransfer(address, address, uint256)
    virtual external returns (uint256);

  /***********  TOKEN ADMIN  ***********/
  function mint(address, address[] calldata, uint256[] calldata)
    virtual external returns (bool);
  function finishMinting(address)
    virtual external returns (bool);
  function burn(address, uint256)
    virtual external returns (bool);
  function seize(address _token, address, uint256)
    virtual external returns (bool);
  function defineLock(address, address, address, uint64, uint64)
    virtual external returns (bool);
  function defineTokenLocks(address _token, address[] memory locks)
    virtual external returns (bool);
  function freezeManyAddresses(
    address _token,
    address[] calldata _addresses,
    uint256 _until) virtual external returns (bool);
  function defineRules(address, IRule[] calldata) virtual external returns (bool);

  /************  CORE ADMIN  ************/
  function defineToken(
    address _token,
    uint256 _delegateId,
    string memory _name,
    string memory _symbol,
    uint256 _decimals) virtual external returns (bool);

  function defineOracle(
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    address _currency) virtual external returns (bool);
  function defineTokenDelegate(
    uint256 _delegateId,
    address _delegate,
    uint256[] calldata _configurations) virtual external returns (bool);
  function defineAuditConfiguration(
    uint256 _configurationId,
    uint256 _scopeId,
    AuditTriggerMode _mode,
    uint256[] calldata _senderKeys,
    uint256[] calldata _receiverKeys,
    IRatesProvider _ratesProvider,
    address _currency) virtual external returns (bool);
  function removeAudits(address _scope, uint256 _scopeId)
    virtual external returns (bool);
  function defineAuditTriggers(
    uint256 _configurationId,
    address[] calldata _senders,
    address[] calldata _receivers,
    AuditTriggerMode[] calldata _modes) virtual external returns (bool);

  function isSelfManaged(address _owner)
    virtual external view returns (bool);
  function manageSelf(bool _active)
    virtual external returns (bool);
}

// File: contracts/interface/IVotingSessionStorage.sol

pragma solidity ^0.6.0;





/**
 * @title IVotingSessionStorage
 * @dev IVotingSessionStorage interface
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IVotingSessionStorage is IVotingDefinitions {

  event SessionRuleUpdated(
    uint64 campaignPeriod,
    uint64 votingPeriod,
    uint64 executionPeriod,
    uint64 gracePeriod,
    uint64 periodOffset,
    uint8 openProposals,
    uint8 maxProposals,
    uint8 maxProposalsOperator,
    uint256 newProposalThreshold,
    address[] nonVotingAddresses);
  event ResolutionRequirementUpdated(
    address target,
    bytes4 methodSignature,
    uint128 majority,
    uint128 quorum,
    uint256 executionThreshold
  );

  event TokenDefined(address token, address core);
  event DelegateDefined(address delegate);

  event SponsorDefined(address indexed voter, address address_, uint64 until);

  event SessionScheduled(uint256 indexed sessionId, uint64 voteAt);
  event SessionArchived(uint256 indexed sessionId);
  event ProposalDefined(uint256 indexed sessionId, uint8 proposalId);
  event ProposalUpdated(uint256 indexed sessionId, uint8 proposalId);
  event ProposalCancelled(uint256 indexed sessionId, uint8 proposalId);
  event ResolutionExecuted(uint256 indexed sessionId, uint8 proposalId);

  event Vote(uint256 indexed sessionId, address voter, uint256 weight);
}

// File: contracts/interface/IVotingSessionDelegate.sol

pragma solidity ^0.6.0;



/**
 * @title IVotingSessionDelegate
 * @dev IVotingSessionDelegate interface
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IVotingSessionDelegate is IVotingSessionStorage {

  function nextSessionAt(uint256 _time) virtual public view returns (uint256 at);

  function sessionStateAt(uint256 _sessionId, uint256 _time) virtual public view returns (SessionState);

  function newProposalThresholdAt(uint256 _sessionId, uint256 _proposalsCount)
    virtual public view returns (uint256);

  function proposalApproval(uint256 _sessionId, uint8 _proposalId)
    virtual public view returns (bool);

  function proposalStateAt(uint256 _sessionId, uint8 _proposalId, uint256 _time)
    virtual public view returns (ProposalState);

  function updateSessionRule(
    uint64 _campaignPeriod,
    uint64 _votingPeriod,
    uint64 _executionPeriod,
    uint64 _gracePeriod,
    uint64 _periodOffset,
    uint8 _openProposals,
    uint8 _maxProposals,
    uint8 _maxProposalsQuaestor,
    uint256 _newProposalThreshold,
    address[] memory _nonVotingAddresses
  ) virtual public returns (bool);

  function updateResolutionRequirements(
    address[] memory _targets,
    bytes4[] memory _methodSignatures,
    uint128[] memory _majority,
    uint128[] memory _quorum,
    uint256[] memory _executionThreshold
  ) virtual public returns (bool);

  function defineProposal(
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf
  ) virtual public returns (bool);

  function updateProposal(
    uint8 _proposalId,
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf
  ) virtual public returns (bool);
  function cancelProposal(uint8 _proposalId) virtual public returns (bool);

  function submitVote(uint256 _votes) virtual public returns (bool);
  function submitVotesOnBehalf(
    address[] memory _voters,
    uint256 _votes
  ) virtual public returns (bool);

  function executeResolutions(uint8[] memory _proposalIds) virtual public returns (bool);

  function archiveSession() virtual public returns (bool);

}

// File: contracts/interface/IVotingSessionManager.sol

pragma solidity ^0.6.0;






/**
 * @title IVotingSessionManager
 * @dev IVotingSessionManager interface
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract IVotingSessionManager is IVotingSessionStorage {

  function contracts() public virtual view returns (
    IVotingSessionDelegate delegate, ITokenProxy token, ITokenCore core);

  function sessionRule() virtual public view returns (
    uint64 campaignPeriod,
    uint64 votingPeriod,
    uint64 executionPeriod,
    uint64 gracePeriod,
    uint64 periodOffset,
    uint8 openProposals,
    uint8 maxProposals,
    uint8 maxProposalsOperator,
    uint256 newProposalThreshold,
    address[] memory nonVotingAddresses);

  function resolutionRequirement(address _target, bytes4 _method) virtual public view returns (
    uint128 majority,
    uint128 quorum,
    uint256 executionThreshold);

  function oldestSessionId() virtual public view returns (uint256);

  function currentSessionId() virtual public view returns (uint256);

  function session(uint256 _sessionId) virtual public view returns (
    uint64 campaignAt,
    uint64 voteAt,
    uint64 executionAt,
    uint64 graceAt,
    uint64 closedAt,
    uint256 sessionProposalsCount,
    uint256 participation,
    uint256 totalSupply,
    uint256 circulatingSupply);

  function proposal(uint256 _sessionId, uint8 _proposalId) virtual public view returns (
    string memory name,
    string memory url,
    bytes32 proposalHash,
    address resolutionTarget,
    bytes memory resolutionAction);
  function proposalData(uint256 _sessionId, uint8 _proposalId) virtual public view returns (
    address proposedBy,
    uint128 requirementMajority,
    uint128 requirementQuorum,
    uint256 executionThreshold,
    uint8 dependsOn,
    uint8 alternativeOf,
    uint256 alternativesMask,
    uint256 approvals);

  function sponsorOf(address _voter) virtual public view returns (address sponsor, uint64 until);

  function lastVoteOf(address _voter) virtual public view returns (uint64 at);

  function nextSessionAt(uint256 _time) virtual public view returns (uint256 at);

  function sessionStateAt(uint256 _sessionId, uint256 _time) virtual public view returns (SessionState);

  function newProposalThresholdAt(uint256 _sessionId, uint256 _proposalsCount)
    virtual public view returns (uint256);

  function proposalApproval(uint256 _sessionId, uint8 _proposalId)
    virtual public view returns (bool);

  function proposalStateAt(uint256 _sessionId, uint8 _proposalId, uint256 _time)
    virtual public view returns (ProposalState);

  function defineContracts(ITokenProxy _token, IVotingSessionDelegate _delegate)
    virtual public returns (bool);

  function updateSessionRule(
    uint64 _campaignPeriod,
    uint64 _votingPeriod,
    uint64 _executionPeriod,
    uint64 _gracePeriod,
    uint64 _periodOffset,
    uint8 _openProposals,
    uint8 _maxProposals,
    uint8 _maxProposalsQuaestor,
    uint256 _newProposalThreshold,
    address[] memory _nonVotingAddresses
  ) virtual public returns (bool);

  function updateResolutionRequirements(
    address[] memory _targets,
    bytes4[] memory _methodSignatures,
    uint128[] memory _majority,
    uint128[] memory _quorum,
    uint256[] memory _executionThreshold
  ) virtual public returns (bool);

  function defineSponsor(address _sponsor, uint64 _until) virtual public returns (bool);
  function defineSponsorOf(Ownable _contract, address _sponsor, uint64 _until)
    virtual public returns (bool);

  function defineProposal(
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf
  ) virtual public returns (bool);

  function updateProposal(
    uint8 _proposalId,
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf
  ) virtual public returns (bool);
  function cancelProposal(uint8 _proposalId) virtual public returns (bool);

  function submitVote(uint256 _votes) virtual public returns (bool);
  function submitVotesOnBehalf(
    address[] memory _voters,
    uint256 _votes
  ) virtual public returns (bool);

  function executeResolutions(uint8[] memory _proposalIds) virtual public returns (bool);

  function archiveSession() virtual public returns (bool);
}

// File: @c-layer/common/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/voting/VotingSessionStorage.sol

pragma solidity ^0.6.0;





/**
 * @title VotingSessionStorage
 * @dev VotingSessionStorage contract
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
contract VotingSessionStorage is IVotingSessionStorage {
  using SafeMath for uint256;

  address internal constant ANY_ADDRESSES = address(0x416e79416464726573736573); // "AnyAddresses"

  struct SessionRule {
    uint64 campaignPeriod; // Before it starts, the vote will be locked
    uint64 votingPeriod; // Time period for voters to submit their votes
    uint64 executionPeriod; // Time period for executing resolutions
    uint64 gracePeriod; // delay between two votes

    uint64 periodOffset; // Offset before the first session period

    uint8 openProposals;
    uint8 maxProposals;
    uint8 maxProposalsOperator;
    uint256 newProposalThreshold;

    address[] nonVotingAddresses;
  }

  struct ResolutionRequirement {
    uint128 majority;
    uint128 quorum;
    uint256 executionThreshold;
  }

  struct Session {
    uint64 campaignAt;
    uint64 voteAt;
    uint64 executionAt;
    uint64 graceAt;
    uint64 closedAt;
    uint8 proposalsCount;
    uint256 participation;
    uint256 totalSupply;
    uint256 votingSupply;

    mapping(uint256 => Proposal) proposals;
  }

  // A proposal may be semanticaly in one of the following state:
  // DEFINED, VOTED, RESOLVED(?), PROCESSED
  struct Proposal {
    string name;
    string url;
    bytes32 proposalHash;
    address proposedBy;
    address resolutionTarget;
    bytes resolutionAction;

    ResolutionRequirement requirement;
    uint8 dependsOn; // The previous proposal must be either non approved or executed
    bool resolutionExecuted;
    bool cancelled;

    uint8 alternativeOf;
    uint256 approvals;
    uint256 alternativesMask; // only used for the parent alternative proposal
  }

  struct Sponsor {
    address address_;
    uint64 until;
  }

  IVotingSessionDelegate internal delegate_;
  ITokenProxy internal token_;
  ITokenCore internal core_;

  SessionRule internal sessionRule_ = SessionRule(
    CAMPAIGN_PERIOD,
    VOTING_PERIOD,
    EXECUTION_PERIOD,
    GRACE_PERIOD,
    OFFSET_PERIOD,
    OPEN_PROPOSALS,
    MAX_PROPOSALS,
    MAX_PROPOSALS_OPERATOR,
    NEW_PROPOSAL_THRESHOLD,
    new address[](0)
  );

  mapping(address => mapping(bytes4 => ResolutionRequirement)) internal resolutionRequirements;

  uint256 internal oldestSessionId_ = 1; // '1' simplifies checks when no sessions exists
  uint256 internal currentSessionId_ = 0;
  mapping(uint256 => Session) internal sessions;
  mapping(address => uint64) internal lastVotes;
  mapping(address => Sponsor) internal sponsors;

  /**
   * @dev currentTime
   */
  function currentTime() internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }
}

// File: contracts/voting/VotingSessionManager.sol

pragma solidity ^0.6.0;






/**
 * @title VotingSessionManager
 * @dev VotingSessionManager contract
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   VM01: Session doesn't exist
 *   VM02: Token is invalid
 *   VM03: Delegate is invalid
 *   VM04: Token has no valid core
 *   VM05: Only contract owner may define its sponsor
 */
contract VotingSessionManager is IVotingSessionManager, DelegateCallView, VotingSessionStorage {
  using DelegateCall for address;

  modifier onlyOperator() {
    require(core_.hasProxyPrivilege(
      msg.sender, address(this), msg.sig), "VM01");
    _;
  }

  /**
   * @dev constructor
   */
  constructor(ITokenProxy _token, IVotingSessionDelegate _delegate) public {
    defineContractsInternal(_token, _delegate);

    resolutionRequirements[ANY_TARGET][ANY_METHOD] =
      ResolutionRequirement(DEFAULT_MAJORITY, DEFAULT_QUORUM, DEFAULT_EXECUTION_THRESHOLD);
  }

  /**
   * @dev token
   */
  function contracts() public override view returns (
    IVotingSessionDelegate delegate, ITokenProxy token, ITokenCore core)
  {
    return (delegate_, token_, core_);
  }

  /**
   * @dev sessionRule
   */
  function sessionRule() public override view returns (
    uint64 campaignPeriod,
    uint64 votingPeriod,
    uint64 executionPeriod,
    uint64 gracePeriod,
    uint64 periodOffset,
    uint8 openProposals,
    uint8 maxProposals,
    uint8 maxProposalsOperator,
    uint256 newProposalThreshold,
    address[] memory nonVotingAddresses) {
    return (
      sessionRule_.campaignPeriod,
      sessionRule_.votingPeriod,
      sessionRule_.executionPeriod,
      sessionRule_.gracePeriod,
      sessionRule_.periodOffset,
      sessionRule_.openProposals,
      sessionRule_.maxProposals,
      sessionRule_.maxProposalsOperator,
      sessionRule_.newProposalThreshold,
      sessionRule_.nonVotingAddresses);
  }

  /**
   * @dev resolutionRequirement
   */
  function resolutionRequirement(address _target, bytes4 _method) public override view returns (
    uint128 majority,
    uint128 quorum,
    uint256 executionThreshold) {
    ResolutionRequirement storage requirement =
      resolutionRequirements[_target][_method];

    return (
      requirement.majority,
      requirement.quorum,
      requirement.executionThreshold);
  }

  /**
   * @dev oldestSessionId
   */
  function oldestSessionId() public override view returns (uint256) {
    return oldestSessionId_;
  }

  /**
   * @dev currentSessionId
   */
  function currentSessionId() public override view returns (uint256) {
    return currentSessionId_;
  }

  /**
   * @dev session
   */
  function session(uint256 _sessionId) public override view returns (
    uint64 campaignAt,
    uint64 voteAt,
    uint64 executionAt,
    uint64 graceAt,
    uint64 closedAt,
    uint256 proposalsCount,
    uint256 participation,
    uint256 totalSupply,
    uint256 votingSupply)
  {
    Session storage session_ = sessions[_sessionId];
    return (
      session_.campaignAt,
      session_.voteAt,
      session_.executionAt,
      session_.graceAt,
      session_.closedAt,
      session_.proposalsCount,
      session_.participation,
      session_.totalSupply,
      session_.votingSupply);
  }

  /**
   * @dev sponsorOf
   */
  function sponsorOf(address _voter) public override view returns (address address_, uint64 until) {
    Sponsor storage sponsor_ = sponsors[_voter];
    address_ = sponsor_.address_;
    until = sponsor_.until;
  }

  /**
   * @dev lastVoteOf
   */
  function lastVoteOf(address _voter) public override view returns (uint64 at) {
    return lastVotes[_voter];
  }

  /**
   * @dev proposal
   */
  function proposal(uint256 _sessionId, uint8 _proposalId) public override view returns (
    string memory name,
    string memory url,
    bytes32 proposalHash,
    address resolutionTarget,
    bytes memory resolutionAction)
  {
    Proposal storage proposal_ = sessions[_sessionId].proposals[_proposalId];
    return (
      proposal_.name,
      proposal_.url,
      proposal_.proposalHash,
      proposal_.resolutionTarget,
      proposal_.resolutionAction);
  }

  /**
   * @dev proposalData
   */
  function proposalData(uint256 _sessionId, uint8 _proposalId) public override view returns (
    address proposedBy,
    uint128 requirementMajority,
    uint128 requirementQuorum,
    uint256 executionThreshold,
    uint8 dependsOn,
    uint8 alternativeOf,
    uint256 alternativesMask,
    uint256 approvals)
  {
    Proposal storage proposal_ = sessions[_sessionId].proposals[_proposalId];
    return (
      proposal_.proposedBy,
      proposal_.requirement.majority,
      proposal_.requirement.quorum,
      proposal_.requirement.executionThreshold,
      proposal_.dependsOn,
      proposal_.alternativeOf,
      proposal_.alternativesMask,
      proposal_.approvals);
  }

  /**
   * @dev nextSessionAt
   */
  function nextSessionAt(uint256) public override view returns (uint256) {
    return _delegateCallUint256(address(delegate_));
  }

  /**
   * @dev sessionStateAt
   */
  function sessionStateAt(uint256, uint256) public override
    view returns (SessionState)
  {
    return SessionState(_delegateCallUint256(address(delegate_)));
  }

  /**
   * @dev newProposalThresholdAt
   */
  function newProposalThresholdAt(uint256, uint256)
    public override view returns (uint256)
  {
    return _delegateCallUint256(address(delegate_));
  }

  /**
   * @dev proposalApproval
   */
  function proposalApproval(uint256, uint8)
    public override view returns (bool)
  {
    return _delegateCallBool(address(delegate_));
  }

  /**
   * @dev proposalStateAt
   */
  function proposalStateAt(uint256, uint8, uint256)
    public override view returns (ProposalState)
  {
    return ProposalState(_delegateCallUint256(address(delegate_)));
  }

  /**
   * @dev define contracts
   */
  function defineContracts(ITokenProxy _token, IVotingSessionDelegate _delegate)
    public override onlyOperator() returns (bool)
  {
    return defineContractsInternal(_token, _delegate);
  }

  /**
   * @dev updateSessionRule
   */
  function updateSessionRule(
    uint64, uint64, uint64, uint64, uint64, uint8, uint8, uint8, uint256, address[] memory)
    public override onlyOperator() returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev updateResolutionRequirements
   */
  function updateResolutionRequirements(
    address[] memory, bytes4[] memory, uint128[] memory, uint128[] memory, uint256[] memory)
    public override onlyOperator() returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev defineSponsor
   */
  function defineSponsor(address _sponsor, uint64 _until) public override returns (bool) {
    sponsors[msg.sender] = Sponsor(_sponsor, _until);
    emit SponsorDefined(msg.sender, _sponsor, _until);
    return true;
  }

  /**
   * @dev defineSponsorOf
   */
  function defineSponsorOf(Ownable _contract, address _sponsor, uint64 _until)
    public override returns (bool)
  {
    require(_contract.owner() == msg.sender, "VM05");
    sponsors[address(_contract)] = Sponsor(_sponsor, _until);
    emit SponsorDefined(address(_contract), _sponsor, _until);
    return true;
  }

  /**
   * @dev defineProposal
   */
  function defineProposal(string memory, string memory,
    bytes32, address, bytes memory, uint8, uint8) public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev updateProposal
   */
  function updateProposal(
    uint8, string memory, string memory, bytes32, address, bytes memory, uint8, uint8)
    public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev cancelProposal
   */
  function cancelProposal(uint8) public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev submitVote
   */
  function submitVote(uint256) public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev submitVotesOnBehalf
   */
  function submitVotesOnBehalf(address[] memory, uint256) public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev execute resolutions
   */
  function executeResolutions(uint8[] memory) public override returns (bool)
  {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev archiveSession
   **/
  function archiveSession() public override returns (bool) {
    return address(delegate_)._delegateCall();
  }

  /**
   * @dev define contracts internal
   */
  function defineContractsInternal(ITokenProxy _token, IVotingSessionDelegate _delegate)
    internal returns (bool)
  {
    require(address(_token) != address(0), "VM02");
    require(address(_delegate) != address(0), "VM03");

    ITokenCore core = ITokenCore(_token.core());
    require(address(core) != address(0), "VM04");

    if (token_ != _token || core_ != core) {
      token_ = _token;
      core_ = core;
      emit TokenDefined(address(token_), address(core_));
    }

    if (delegate_ != _delegate) {
      delegate_ = _delegate;
      emit DelegateDefined(address(delegate_));
    }
    return true;
  }
}