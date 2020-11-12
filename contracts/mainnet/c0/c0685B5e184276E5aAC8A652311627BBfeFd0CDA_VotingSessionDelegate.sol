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
 * Flatten Contract: VotingSessionDelegate
 *
 * Git Commit:
 * https://github.com/c-layer/contracts/commit/9993912325afde36151b04d0247ac9ea9ffa2a93
 *
 **************************************************************************/


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

// File: contracts/voting/VotingSessionDelegate.sol

pragma solidity ^0.6.0;




/**
 * @title VotingSessionDelegate
 * @dev VotingSessionDelegate contract
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   VD01: Session doesn't exist
 *   VD02: Proposal doesn't exist
 *   VD03: Campaign period must be within valid range
 *   VD04: Voting period must be within valid range
 *   VD05: Execution period must be within valid range
 *   VD06: Grace period must be within valid range
 *   VD07: Period offset must be within valid range
 *   VD08: Open proposals limit must be lower than the max proposals limit
 *   VD09: Operator proposal limit must be greater than 0
 *   VD10: New proposal threshold must be greater than 0
 *   VD11: The current session is not in GRACE, CLOSED or ARCHIVED state
 *   VD12: Duplicates entries are not allowed in non voting contracts
 *   VD13: Inconsistent numbers of methods signatures
 *   VD14: Inconsistent numbers of min participations
 *   VD15: Inconsistent numbers of quorums
 *   VD16: Inconsistent numbers of execution thresholds
 *   VD17: Default majority cannot be null
 *   VD18: Execute resolution threshold must be greater than 0
 *   VD19: Operator proposal limit is reached
 *   VD20: Too many proposals yet for this session
 *   VD21: Not enough tokens for a new proposal
 *   VD22: Current session is not in PLANNED state
 *   VD23: Only the author can update a proposal
 *   VD24: Proposal must not be already cancelled
 *   VD25: The previous session can only be in GRACE state to allow rules change
 *   VD26: Not enough tokens to execute
 *   VD27: Voting Session resolutions are not allowed in EXECUTION
 *   VD28: Only Voting Session operations are allowed in GRACE
 *   VD29: The proposal is not in APPROVED state
 *   VD30: Invalid resolution order
 *   VD31: The resolution must be successfull
 *   VD32: The session is too recent to be archived
 *   VD33: Unable to set the lock
 *   VD34: Cannot depends on itself or inexisting porposal
 *   VD35: Reference proposal for alternates must have the lowest proposalId
 *   VD36: Session is not in VOTING state
 *   VD37: Voters must be provided
 *   VD38: Sender must be either the voter, the voter's sponsor or an operator
 *   VD39: The voter has been marked 'voted'. If the voter has not voted yet,
 *         he is then part of the non voting addresses.
 *   VD40: Cannot vote for a cancelled proposal
 *   VD41: Cannot submit multiple votes for a proposal and its alternatives
 *   VD42: The vote contains too many proposals
 */
contract VotingSessionDelegate is IVotingSessionDelegate, VotingSessionStorage {

  modifier onlyExistingSession(uint256 _sessionId) {
    require(_sessionId >= oldestSessionId_ && _sessionId <= currentSessionId_, "VD01");
    _;
  }

  modifier onlyExistingProposal(uint256 _sessionId, uint8 _proposalId) {
    require(_sessionId >= oldestSessionId_ && _sessionId <= currentSessionId_, "VD01");
    require(_proposalId > 0 && _proposalId <= sessions[_sessionId].proposalsCount, "VD02");
    _;
  }

  /**
   * @dev nextSessionAt
   */
  function nextSessionAt(uint256 _time) public override view returns (uint256 voteAt) {
    uint256 sessionPeriod =
      sessionRule_.campaignPeriod
      + sessionRule_.votingPeriod
      + sessionRule_.executionPeriod
      + sessionRule_.gracePeriod;

    uint256 currentSessionClosedAt =
      (currentSessionId_ != 0) ? uint256(sessions[currentSessionId_].closedAt) : 0;

    voteAt = (_time + sessionRule_.campaignPeriod);
    voteAt = (voteAt > currentSessionClosedAt) ? voteAt : currentSessionClosedAt;

    uint256 closestPeriodAt = voteAt / sessionPeriod * sessionPeriod + sessionRule_.periodOffset;
    voteAt = (voteAt != closestPeriodAt) ? closestPeriodAt + sessionPeriod : closestPeriodAt;
  }

  /**
   * @dev sessionStateAt
   */
  function sessionStateAt(uint256 _sessionId, uint256 _time) public override
    view returns (SessionState)
  {
    if (_sessionId == 0 || _sessionId > currentSessionId_) {
      return SessionState.UNDEFINED;
    }

    if (_sessionId < oldestSessionId_) {
      return SessionState.ARCHIVED;
    }

    Session storage session_ = sessions[_sessionId];

    if (_time < uint256(session_.campaignAt)) {
      return SessionState.PLANNED;
    }

    if (_time < uint256(session_.voteAt)) {
      return SessionState.CAMPAIGN;
    }

    if (_time < uint256(session_.executionAt))
    {
      return SessionState.VOTING;
    }

    if (_time < uint256(session_.graceAt))
    {
      return SessionState.EXECUTION;
    }

    if (_time < uint256(session_.closedAt))
    {
      return SessionState.GRACE;
    }

    return SessionState.CLOSED;
  }

  /**
   * @dev newProposalThresholdAt
   */
  function newProposalThresholdAt(uint256 _sessionId, uint256 _proposalsCount)
    public override onlyExistingSession(_sessionId) view returns (uint256)
  {
    Session storage session_ = sessions[_sessionId];
    bool baseThreshold = (
      sessionRule_.maxProposals <= sessionRule_.openProposals
      || _proposalsCount <= sessionRule_.openProposals
      || session_.totalSupply <= sessionRule_.newProposalThreshold);

    return (baseThreshold) ? sessionRule_.newProposalThreshold : sessionRule_.newProposalThreshold.add(
      (session_.totalSupply.div(2)).sub(sessionRule_.newProposalThreshold).mul(
        (_proposalsCount - sessionRule_.openProposals) ** 2).div((sessionRule_.maxProposals - sessionRule_.openProposals) ** 2));
  }

  /**
   * @dev proposalApproval
   */
  function proposalApproval(uint256 _sessionId, uint8 _proposalId)
    public override view onlyExistingProposal(_sessionId, _proposalId) returns (bool isApproved)
  {
    Session storage session_ = sessions[_sessionId];
    Proposal storage proposal_ = session_.proposals[_proposalId];

    uint256 participation = session_.participation;
    uint256 participationPercent = 0;
    if (participation != 0) {
      participationPercent = participation.mul(PERCENT).div(session_.votingSupply);
      isApproved = (
        (proposal_.approvals.mul(PERCENT).div(participation) >= proposal_.requirement.majority) &&
        (participationPercent >= proposal_.requirement.quorum)
      );
    }

    /**
     * @notice when the proposal has fulfiled its own requirements,
     * @notice its approvals must be also compared to alternative proposals if they exist
     * @notice if more than one proposal have the same approval, the first submitted wins
     */
    if (isApproved &&
      (proposal_.alternativeOf != 0 || proposal_.alternativesMask != 0))
    {
      uint256 baseProposalId = (proposal_.alternativeOf == 0) ? _proposalId : proposal_.alternativeOf;
      Proposal storage baseProposal = session_.proposals[baseProposalId];

      uint256 remainingProposals = baseProposal.alternativesMask >> (baseProposalId - 1);

      for (uint256 i = baseProposalId; remainingProposals != 0; i++) {
        if (((remainingProposals & 1) == 1) && (i != _proposalId)) {
          Proposal storage alternative = session_.proposals[i];
          if ((alternative.approvals >= proposal_.approvals &&
            (alternative.approvals != proposal_.approvals || i < _proposalId)) &&
            (alternative.approvals.mul(PERCENT).div(participation) >= alternative.requirement.majority) &&
            (participationPercent >= alternative.requirement.quorum))
          {
            isApproved = false;
            break;
          }
        }
        remainingProposals = remainingProposals >> 1;
      }
    }
  }

  /**
   * @dev proposalStateAt
   */
  function proposalStateAt(uint256 _sessionId, uint8 _proposalId, uint256 _time)
    public override view returns (ProposalState)
  {
    Session storage session_ = sessions[_sessionId];
    SessionState sessionState = sessionStateAt(_sessionId, _time);

    if (sessionState == SessionState.ARCHIVED) {
      return ProposalState.ARCHIVED;
    }

    if (sessionState == SessionState.UNDEFINED
      || _proposalId == 0 || _proposalId > session_.proposalsCount) {
      return ProposalState.UNDEFINED;
    }

    Proposal storage proposal_ = session_.proposals[_proposalId];

    if (proposal_.cancelled) {
      return ProposalState.CANCELLED;
    }

    if (sessionState < SessionState.CAMPAIGN) {
      return ProposalState.DEFINED;
    }

    if (sessionState < SessionState.EXECUTION) {
      return ProposalState.LOCKED;
    }

    if (proposal_.resolutionExecuted) {
      return ProposalState.RESOLVED;
    }

    if (sessionState == SessionState.CLOSED) {
      return ProposalState.CLOSED;
    }

    return proposalApproval(_sessionId, _proposalId) ? ProposalState.APPROVED : ProposalState.REJECTED;
  }

  /**
   * @dev updateSessionRule
   * @notice the campaign period may be 0 and therefore not exists
   * @notice the grace period must be greater than the campaign period and greater
   *         than the minimal period.
   */
  function updateSessionRule(
    uint64 _campaignPeriod,
    uint64 _votingPeriod,
    uint64 _executionPeriod,
    uint64 _gracePeriod,
    uint64 _periodOffset,
    uint8 _openProposals,
    uint8 _maxProposals,
    uint8 _maxProposalsOperator,
    uint256 _newProposalThreshold,
    address[] memory _nonVotingAddresses
  )  public override returns (bool) {
    require(_campaignPeriod <= MAX_PERIOD_LENGTH, "VD03");
    require(_votingPeriod >= MIN_PERIOD_LENGTH && _votingPeriod <= MAX_PERIOD_LENGTH, "VD04");
    require(_executionPeriod >= MIN_PERIOD_LENGTH && _executionPeriod <= MAX_PERIOD_LENGTH, "VD05");
    require(_gracePeriod >= MIN_PERIOD_LENGTH && _gracePeriod <= MAX_PERIOD_LENGTH, "VD06");
    require(_periodOffset <= MAX_PERIOD_LENGTH, "VD07");

    require(_openProposals <= _maxProposals, "VD08");
    require(_maxProposalsOperator !=0, "VD09");
    require(_newProposalThreshold != 0, "VD10");

    if (currentSessionId_ != 0) {
      SessionState state = sessionStateAt(currentSessionId_, currentTime());
      require(state == SessionState.GRACE ||
        state == SessionState.CLOSED || state == SessionState.ARCHIVED, "VD11");
    }

    uint256 currentTime_ = currentTime();
    for (uint256 i=0; i < sessionRule_.nonVotingAddresses.length; i++) {
      lastVotes[sessionRule_.nonVotingAddresses[i]] = uint64(currentTime_);
    }

    for (uint256 i=0; i < _nonVotingAddresses.length; i++) {
      lastVotes[_nonVotingAddresses[i]] = ~uint64(0);

      for (uint256 j=i+1; j < _nonVotingAddresses.length; j++) {
        require(_nonVotingAddresses[i] != _nonVotingAddresses[j], "VD12");
      }
    }

    sessionRule_ = SessionRule(
      _campaignPeriod,
      _votingPeriod,
      _executionPeriod,
      _gracePeriod,
      _periodOffset,
      _openProposals,
      _maxProposals,
      _maxProposalsOperator,
      _newProposalThreshold,
      _nonVotingAddresses);

    emit SessionRuleUpdated(
      _campaignPeriod,
      _votingPeriod,
      _executionPeriod,
      _gracePeriod,
      _periodOffset,
      _openProposals,
      _maxProposals,
      _maxProposalsOperator,
      _newProposalThreshold,
      _nonVotingAddresses);
    return true;
  }

  /**
   * @dev updateResolutionRequirements
   */
  function updateResolutionRequirements(
    address[] memory _targets,
    bytes4[] memory _methodSignatures,
    uint128[] memory _majorities,
    uint128[] memory _quorums,
    uint256[] memory _executionThresholds
  ) public override returns (bool)
  {
    require(_targets.length == _methodSignatures.length, "VD13");
    require(_methodSignatures.length == _majorities.length, "VD14");
    require(_methodSignatures.length == _quorums.length, "VD15");
    require(_methodSignatures.length == _executionThresholds.length, "VD16");

    if (currentSessionId_ != 0) {
      SessionState state = sessionStateAt(currentSessionId_, currentTime());
      require(state == SessionState.GRACE ||
        state == SessionState.CLOSED || state == SessionState.ARCHIVED, "VD11");
    }

    for (uint256 i=0; i < _methodSignatures.length; i++) {
      // Majority can only be 0 if it is not the global default, allowing the deletion of the requirement
      require(_majorities[i] != 0 || !(_targets[i] == ANY_TARGET && _methodSignatures[i] == ANY_METHOD), "VD17");
      require(_executionThresholds[i] != 0 || _majorities[i] == 0, "VD18");

      resolutionRequirements[_targets[i]][_methodSignatures[i]] =
        ResolutionRequirement(_majorities[i], _quorums[i], _executionThresholds[i]);
      emit ResolutionRequirementUpdated(
         _targets[i], _methodSignatures[i], _majorities[i], _quorums[i], _executionThresholds[i]);
    }
    return true;
  }

  /**
   * @dev defineProposal
   */
  function defineProposal(
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf) public override returns (bool)
  {
    Session storage session_ = loadSessionInternal();

    if (core_.hasProxyPrivilege(msg.sender, address(this), msg.sig)) {
      require(session_.proposalsCount < sessionRule_.maxProposalsOperator, "VD19");
    } else {
      require(session_.proposalsCount < sessionRule_.maxProposals, "VD20");
      require(token_.balanceOf(msg.sender) >=
        newProposalThresholdAt(currentSessionId_, session_.proposalsCount), "VD21");
    }

    uint8 proposalId = ++session_.proposalsCount;
    updateProposalInternal(proposalId,
      _name, _url, _proposalHash, _resolutionTarget, _resolutionAction, _dependsOn, _alternativeOf);
    session_.proposals[proposalId].proposedBy = msg.sender;

    emit ProposalDefined(currentSessionId_, proposalId);
    return true;
  }

  /**
   * @dev updateProposal
   */
  function updateProposal(
    uint8 _proposalId,
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf
  ) public override onlyExistingProposal(currentSessionId_, _proposalId) returns (bool)
  {
    uint256 sessionId = currentSessionId_;
    require(sessionStateAt(sessionId, currentTime()) == SessionState.PLANNED, "VD22");
    require(msg.sender == sessions[sessionId].proposals[_proposalId].proposedBy, "VD23");

    updateProposalInternal(_proposalId,
      _name, _url, _proposalHash, _resolutionTarget, _resolutionAction, _dependsOn, _alternativeOf);

    emit ProposalUpdated(sessionId, _proposalId);
    return true;
  }

  /**
   * @dev cancelProposal
   */
  function cancelProposal(uint8 _proposalId)
    public override onlyExistingProposal(currentSessionId_, _proposalId) returns (bool)
  {
    uint256 sessionId = currentSessionId_;
    require(sessionStateAt(sessionId, currentTime()) == SessionState.PLANNED, "VD22");
    Proposal storage proposal_ = sessions[sessionId].proposals[_proposalId];

    require(msg.sender == proposal_.proposedBy, "VD23");
    require(!proposal_.cancelled, "VD24");

    proposal_.cancelled = true;
    emit ProposalCancelled(sessionId, _proposalId);
    return true;
  }

  /**
   * @dev submitVote
   */
  function submitVote(uint256 _votes) public override returns (bool)
  {
    address[] memory voters = new address[](1);
    voters[0] = msg.sender;
    submitVoteInternal(voters, _votes);
    return true;
  }

  /**
   * @dev submitVotesOnBehalf
   */
  function submitVotesOnBehalf(
    address[] memory _voters,
    uint256 _votes
  ) public override returns (bool)
  {
    submitVoteInternal(_voters, _votes);
    return true;
  }

  /**
   * @dev execute resolutions
   */
  function executeResolutions(uint8[] memory _proposalIds) public override returns (bool)
  {
    uint256 balance;
    if (core_.hasProxyPrivilege(msg.sender, address(this), msg.sig)) {
      balance = ~uint256(0);
    } else {
      balance = token_.balanceOf(msg.sender);
    }

    uint256 currentTime_ = currentTime();
    uint256 sessionId = currentSessionId_;
    SessionState sessionState = sessionStateAt(sessionId, currentTime_);

    if (sessionState != SessionState.EXECUTION && sessionState != SessionState.GRACE) {
      sessionState = sessionStateAt(--sessionId, currentTime_);
      require(sessionState == SessionState.GRACE, "VD25");
    }

    Session storage session_ = sessions[sessionId];
    for (uint256 i=0; i < _proposalIds.length; i++) {
      uint8 proposalId = _proposalIds[i];
      Proposal storage proposal_ = session_.proposals[proposalId];

      require(balance >= proposal_.requirement.executionThreshold, "VD26");
      if (sessionState == SessionState.EXECUTION) {
        require(proposal_.resolutionTarget != address(this), "VD27");
      } else {
        require(proposal_.resolutionTarget == address(this), "VD28");
      }

      require(proposalStateAt(sessionId, proposalId, currentTime_) == ProposalState.APPROVED, "VD29");
      if (proposal_.dependsOn != 0) {
        ProposalState dependsOnState = proposalStateAt(sessionId, proposal_.dependsOn, currentTime_);
        require(dependsOnState != ProposalState.APPROVED, "VD30");
      }

      proposal_.resolutionExecuted = true;
      if (proposal_.resolutionTarget != ANY_TARGET) {
        // solhint-disable-next-line avoid-call-value, avoid-low-level-calls
        (bool success, ) = proposal_.resolutionTarget.call(proposal_.resolutionAction);
        require(success, "VD31");
      }

      emit ResolutionExecuted(sessionId, proposalId);
    }
    return true;
  }

  /**
   * @dev archiveSession
   **/
  function archiveSession() public override onlyExistingSession(oldestSessionId_) returns (bool) {
    Session storage session_ = sessions[oldestSessionId_];
    require((currentSessionId_ >= (oldestSessionId_ + SESSION_RETENTION_COUNT)) ||
      (currentTime() > (SESSION_RETENTION_PERIOD + session_.voteAt)), "VD32");
    for (uint256 i=0; i < session_.proposalsCount; i++) {
      delete session_.proposals[i];
    }
    delete sessions[oldestSessionId_];
    emit SessionArchived(oldestSessionId_++);
  }

  /**
   * @dev read signature
   * @param _data contains the selector
   */
  function readSignatureInternal(bytes memory _data) internal pure returns (bytes4 signature) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      signature := mload(add(_data, 0x20))
    }
  }

  /**
   * @dev load session internal
   */
  function loadSessionInternal() internal returns (Session storage session_) {
    uint256 currentTime_ = currentTime();

    SessionState state = SessionState.CLOSED;
    if (currentSessionId_ != 0) {
      state = sessionStateAt(currentSessionId_, currentTime_);
    }

    if (state != SessionState.PLANNED) {
      // Creation of a new session
      require(state == SessionState.GRACE ||
        state == SessionState.CLOSED || state == SessionState.ARCHIVED, "VD11");
      uint256 nextStartAt = nextSessionAt(currentTime_);
      session_ = sessions[++currentSessionId_];
      session_.campaignAt = uint64(nextStartAt.sub(sessionRule_.campaignPeriod));
      session_.voteAt = uint64(nextStartAt);

      uint256 at = nextStartAt.add(sessionRule_.votingPeriod);
      session_.executionAt = uint64(at);
      at = at.add(sessionRule_.executionPeriod);
      session_.graceAt = uint64(at);
      at = at.add(sessionRule_.gracePeriod);
      session_.closedAt = uint64(at);
      session_.totalSupply = token_.totalSupply();

      require(core_.defineLock(
        address(this),
        ANY_ADDRESSES,
        ANY_ADDRESSES,
        session_.voteAt,
        session_.executionAt), "VD33");

      emit SessionScheduled(currentSessionId_, session_.voteAt);

      if (currentSessionId_ >= (oldestSessionId_ + SESSION_RETENTION_COUNT)) {
        // Archiving of the oldest session
        archiveSession();
      }
    } else {
      session_ = sessions[currentSessionId_];
    }
  }

  /**
   * @dev updateProposalInternal
   */
  function updateProposalInternal(
    uint8 _proposalId,
    string memory _name,
    string memory _url,
    bytes32 _proposalHash,
    address _resolutionTarget,
    bytes memory _resolutionAction,
    uint8 _dependsOn,
    uint8 _alternativeOf) internal
  {
    Session storage session_ = sessions[currentSessionId_];

    require(_dependsOn <= session_.proposalsCount && _dependsOn != _proposalId, "VD34");
    require(_alternativeOf < _proposalId, "VD35");

    Proposal storage proposal_ = session_.proposals[_proposalId];
    proposal_.name = _name;
    proposal_.url = _url;
    proposal_.proposalHash = _proposalHash;
    proposal_.resolutionTarget = _resolutionTarget;
    proposal_.resolutionAction = _resolutionAction;
    proposal_.dependsOn = _dependsOn;

    if (proposal_.alternativeOf != _alternativeOf) {
      uint256 proposalBit = 1 << uint256(_proposalId-1);

      Proposal storage baseProposal;
      if (proposal_.alternativeOf != 0) {
        baseProposal = session_.proposals[proposal_.alternativeOf];
        baseProposal.alternativesMask ^= proposalBit;
      }
      if (_alternativeOf != 0) {
        baseProposal = session_.proposals[_alternativeOf];
        baseProposal.alternativesMask |= (1 << uint256(_alternativeOf-1)) | proposalBit;
      }
      proposal_.alternativeOf = _alternativeOf;
    }

    bytes4 actionSignature = readSignatureInternal(proposal_.resolutionAction);
    ResolutionRequirement storage requirement =
      resolutionRequirements[proposal_.resolutionTarget][actionSignature];

    if (requirement.majority == 0) {
      requirement = resolutionRequirements[proposal_.resolutionTarget][bytes4(ANY_METHOD)];
    }

    if (requirement.majority == 0) {
      requirement = resolutionRequirements[ANY_TARGET][actionSignature];
    }

    if (requirement.majority == 0) {
      requirement = resolutionRequirements[ANY_TARGET][bytes4(ANY_METHOD)];
    }
    proposal_.requirement =
      ResolutionRequirement(
        requirement.majority,
        requirement.quorum,
        requirement.executionThreshold);
  }

  function updateVotingSupply() internal {
    Session storage session_ = sessions[currentSessionId_];
    session_.votingSupply = session_.totalSupply;
    for (uint256 i=0; i < sessionRule_.nonVotingAddresses.length; i++) {
      session_.votingSupply =
        session_.votingSupply.sub(token_.balanceOf(sessionRule_.nonVotingAddresses[i]));
    }
  }


  /**
   * @dev submit vote for proposals internal
   */
  function submitVoteInternal(
    address[] memory _voters,
    uint256 _votes) internal
  {
    require(sessionStateAt(currentSessionId_, currentTime()) == SessionState.VOTING, "VD36");
    Session storage session_ = sessions[currentSessionId_];
    require(_voters.length > 0, "VD37");

    if(session_.participation == 0) {
      // The token is now locked and supply should not change anymore
      updateVotingSupply();
    }

    uint256 weight = 0;
    uint64 currentTime_ = uint64(currentTime());

    for (uint256 i=0; i < _voters.length; i++) {
      address voter = _voters[i];

      require(voter == msg.sender ||
        (core_.hasProxyPrivilege(msg.sender, address(this), msg.sig) && !core_.isSelfManaged(voter)) ||
        (sponsors[voter].address_ == msg.sender && sponsors[voter].until  >= currentTime_), "VD38");
      require(lastVotes[voter] < session_.voteAt, "VD39");
      uint256 balance = token_.balanceOf(voter);
      weight += balance;
      lastVotes[voter] = currentTime_;
      emit Vote(currentSessionId_, voter, balance);
    }

    uint256 remainingVotes = _votes;
    for (uint256 i=1; i <= session_.proposalsCount && remainingVotes != 0; i++) {
      if ((remainingVotes & 1) == 1) {
        Proposal storage proposal_ = session_.proposals[i];

        require(!proposal_.cancelled, "VD40");
        if (proposal_.alternativeOf != 0) {
          Proposal storage baseProposal = session_.proposals[proposal_.alternativeOf];
          require (baseProposal.alternativesMask & _votes == (1 << (i-1)), "VD41");
        }

        proposal_.approvals += weight;
      }
      remainingVotes = remainingVotes >> 1;
    }
    require(remainingVotes == 0, "VD42");
    session_.participation += weight;
  }
}