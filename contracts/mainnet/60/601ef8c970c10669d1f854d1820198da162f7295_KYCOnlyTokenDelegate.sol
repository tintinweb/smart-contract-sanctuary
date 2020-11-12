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
 * Flatten Contract: TokenCore
 *
 * Git Commit:
 * https://github.com/c-layer/contracts/commit/9993912325afde36151b04d0247ac9ea9ffa2a93
 *
 **************************************************************************/


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

// File: @c-layer/common/contracts/core/Storage.sol

pragma solidity ^0.6.0;


/**
 * @title Storage
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 **/
contract Storage {
  mapping(address => uint256) internal proxyDelegateIds;
  mapping(uint256 => address) internal delegates;
}

// File: @c-layer/common/contracts/core/OperableStorage.sol

pragma solidity ^0.6.0;





/**
 * @title OperableStorage
 * @dev The Operable contract enable the restrictions of operations to a set of operators
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
contract OperableStorage is IOperableStorage, Ownable, Storage {

  struct RoleData {
    mapping(bytes4 => bool) privileges;
  }

  struct OperatorData {
    bytes32 coreRole;
    mapping(address => bytes32) proxyRoles;
  }

  // Mapping address => role
  // Mapping role => bytes4 => bool
  mapping (address => OperatorData) internal operators;
  mapping (bytes32 => RoleData) internal roles;

  /**
   * @dev proxyDelegateId
   */
  function proxyDelegateId(address _proxy) override public view returns (uint256) {
    return proxyDelegateIds[_proxy];
  }

  /**
   * @dev delegate
   */
  function delegate(uint256 _delegateId) override public view returns (address) {
    return delegates[_delegateId];
  }

  /**
   * @dev core role
   * @param _address operator address
   */
  function coreRole(address _address) override public view returns (bytes32) {
    return operators[_address].coreRole;
  }

  /**
   * @dev proxy role
   * @param _address operator address
   */
  function proxyRole(address _proxy, address _address)
    override public view returns (bytes32)
  {
    return operators[_address].proxyRoles[_proxy];
  }

  /**
   * @dev has role privilege
   * @dev low level access to role privilege
   * @dev ignores ALL_PRIVILEGES role
   */
  function rolePrivilege(bytes32 _role, bytes4 _privilege)
    override public view returns (bool)
  {
    return roles[_role].privileges[_privilege];
  }

  /**
   * @dev roleHasPrivilege
   */
  function roleHasPrivilege(bytes32 _role, bytes4 _privilege) override public view returns (bool) {
    return (_role == ALL_PRIVILEGES) || roles[_role].privileges[_privilege];
  }

  /**
   * @dev hasCorePrivilege
   * @param _address operator address
   */
  function hasCorePrivilege(address _address, bytes4 _privilege) override public view returns (bool) {
    bytes32 role = operators[_address].coreRole;
    return (role == ALL_PRIVILEGES) || roles[role].privileges[_privilege];
  }

  /**
   * @dev hasProxyPrivilege
   * @dev the default proxy role can be set with proxy address(0)
   * @param _address operator address
   */
  function hasProxyPrivilege(address _address, address _proxy, bytes4 _privilege) override public view returns (bool) {
    OperatorData storage data = operators[_address];
    bytes32 role = (data.proxyRoles[_proxy] != bytes32(0)) ?
      data.proxyRoles[_proxy] : data.proxyRoles[ALL_PROXIES];
    return (role == ALL_PRIVILEGES) || roles[role].privileges[_privilege];
  }
}

// File: contracts/interface/IRule.sol

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

// File: contracts/interface/ITokenStorage.sol

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

// File: contracts/TokenStorage.sol

pragma solidity ^0.6.0;






/**
 * @title Token storage
 * @dev Token storage
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
contract TokenStorage is ITokenStorage, OperableStorage {
  using SafeMath for uint256;

  struct LockData {
    uint64 startAt;
    uint64 endAt;
  }

  struct TokenData {
    string name;
    string symbol;
    uint256 decimals;

    uint256 totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    bool mintingFinished;

    uint256 allTimeMinted;
    uint256 allTimeBurned;
    uint256 allTimeSeized;

    mapping (address => uint256) frozenUntils;
    address[] locks;
    IRule[] rules;
  }

  struct AuditData {
    uint64 createdAt;
    uint64 lastTransactionAt;
    uint256 cumulatedEmission;
    uint256 cumulatedReception;
  }

  struct AuditStorage {
    address currency;

    AuditData sharedData;
    mapping(uint256 => AuditData) userData;
    mapping(address => AuditData) addressData;
  }

  struct AuditConfiguration {
    uint256 scopeId;

    uint256[] senderKeys;
    uint256[] receiverKeys;
    IRatesProvider ratesProvider;

    mapping (address => mapping(address => AuditTriggerMode)) triggers;
  }

  // AuditConfigurationId => AuditConfiguration
  mapping (uint256 => AuditConfiguration) internal auditConfigurations;
  // DelegateId => AuditConfigurationId[]
  mapping (uint256 => uint256[]) internal delegatesConfigurations_;
  mapping (address => TokenData) internal tokens;

  // Scope x ScopeId => AuditStorage
  mapping (address => mapping (uint256 => AuditStorage)) internal audits;

  // Prevents operator to act on behalf
  mapping (address => bool) internal selfManaged;

  // Proxy x Sender x Receiver x LockData
  mapping (address => mapping (address => mapping(address => LockData))) internal locks;

  IUserRegistry internal userRegistry_;
  IRatesProvider internal ratesProvider_;
  address internal currency_;
  string internal name_;

  /**
   * @dev currentTime()
   */
  function currentTime() internal view returns (uint64) {
    // solhint-disable-next-line not-rely-on-time
    return uint64(now);
  }
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

// File: @c-layer/common/contracts/core/Core.sol

pragma solidity ^0.6.0;





/**
 * @title Core
 * @dev Solidity version 0.5.x prevents to mark as view
 * @dev functions using delegate call.
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   CO01: Only Proxy may access the function
 *   CO02: Address 0 is an invalid delegate address
 *   CO03: Delegatecall should be successful
 *   CO04: DelegateId must be greater than 0
 *   CO05: Proxy must exist
 *   CO06: Proxy must be already defined
 *   CO07: Proxy update must be successful
 **/
contract Core is Storage {
  using DelegateCall for address;

  modifier onlyProxy {
    require(delegates[proxyDelegateIds[msg.sender]] != address(0), "CO01");
    _;
  }

  function validProxyDelegate(address _proxy) internal view returns (address delegate) {
    uint256 delegateId = proxyDelegateIds[_proxy];
    delegate = delegates[delegateId];
    require(delegate != address(0), "CO02");
  }

  function delegateCall(address _proxy) internal returns (bool status)
  {
    return validProxyDelegate(_proxy)._delegateCall();
  }

  function delegateCallBool(address _proxy)
    internal returns (bool)
  {
    return validProxyDelegate(_proxy)._delegateCallBool();
  }

  function delegateCallUint256(address _proxy)
    internal returns (uint256)
  {
    return validProxyDelegate(_proxy)._delegateCallUint256();
  }

  function delegateCallBytes(address _proxy)
    internal returns (bytes memory result)
  {
    return validProxyDelegate(_proxy)._delegateCallBytes();
  }

  function defineDelegateInternal(uint256 _delegateId, address _delegate) internal returns (bool) {
    require(_delegateId != 0, "CO04");
    delegates[_delegateId] = _delegate;
    return true;
  }

  function defineProxyInternal(address _proxy, uint256 _delegateId)
    virtual internal returns (bool)
  {
    require(delegates[_delegateId] != address(0), "CO02");
    require(_proxy != address(0), "CO05");

    proxyDelegateIds[_proxy] = _delegateId;
    return true;
  }

  function migrateProxyInternal(address _proxy, address _newCore)
    internal returns (bool)
  {
    require(proxyDelegateIds[_proxy] != 0, "CO06");
    require(Proxy(_proxy).updateCore(_newCore), "CO07");
    return true;
  }

  function removeProxyInternal(address _proxy)
    internal virtual returns (bool)
  {
    require(proxyDelegateIds[_proxy] != 0, "CO06");
    delete proxyDelegateIds[_proxy];
    return true;
  }
}

// File: @c-layer/common/contracts/core/OperableCore.sol

pragma solidity ^0.6.0;





/**
 * @title OperableCore
 * @dev The Operable contract enable the restrictions of operations to a set of operators
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   OC01: Sender is not a system operator
 *   OC02: Sender is not a core operator
 *   OC03: Sender is not a proxy operator
 *   OC04: Role must not be null
 *   OC05: AllPrivileges is a reserved role
 *   OC06: AllProxies is not a valid proxy address
 *   OC07: Proxy must be valid
 *   OC08: Operator has no role
 */
contract OperableCore is IOperableCore, Core, OperableStorage {

  constructor(address[] memory _sysOperators) public {
    assignOperators(ALL_PRIVILEGES, _sysOperators);
    assignProxyOperators(ALL_PROXIES, ALL_PRIVILEGES, _sysOperators);
  }

  /**
   * @dev onlySysOp modifier
   * @dev for safety reason, core owner
   * @dev can always define roles and assign or revoke operatos
   */
  modifier onlySysOp() {
    require(msg.sender == owner || hasCorePrivilege(msg.sender, msg.sig), "OC01");
    _;
  }

  /**
   * @dev onlyCoreOp modifier
   */
  modifier onlyCoreOp() {
    require(hasCorePrivilege(msg.sender, msg.sig), "OC02");
    _;
  }

  /**
   * @dev onlyProxyOp modifier
   */
  modifier onlyProxyOp(address _proxy) {
    require(hasProxyPrivilege(msg.sender, _proxy, msg.sig), "OC03");
    _;
  }

  /**
   * @dev defineRoles
   * @param _role operator role
   * @param _privileges as 4 bytes of the method
   */
  function defineRole(bytes32 _role, bytes4[] memory _privileges)
    override public onlySysOp returns (bool)
  {
    require(_role != bytes32(0), "OC04");
    require(_role != ALL_PRIVILEGES, "OC05");

    delete roles[_role];
    for (uint256 i=0; i < _privileges.length; i++) {
      roles[_role].privileges[_privileges[i]] = true;
    }
    emit RoleDefined(_role);
    return true;
  }

  /**
   * @dev assignOperators
   * @param _role operator role. May be a role not defined yet.
   * @param _operators addresses
   */
  function assignOperators(bytes32 _role, address[] memory _operators)
    override public onlySysOp returns (bool)
  {
    require(_role != bytes32(0), "OC04");

    for (uint256 i=0; i < _operators.length; i++) {
      operators[_operators[i]].coreRole = _role;
      emit OperatorAssigned(_role, _operators[i]);
    }
    return true;
  }

  /**
   * @dev assignProxyOperators
   * @param _role operator role. May be a role not defined yet.
   * @param _operators addresses
   */
  function assignProxyOperators(
    address _proxy, bytes32 _role, address[] memory _operators)
    override public onlySysOp returns (bool)
  {
    require(_proxy == ALL_PROXIES ||
      delegates[proxyDelegateIds[_proxy]] != address(0), "OC07");
    require(_role != bytes32(0), "OC04");

    for (uint256 i=0; i < _operators.length; i++) {
      operators[_operators[i]].proxyRoles[_proxy] = _role;
      emit ProxyOperatorAssigned(_proxy, _role, _operators[i]);
    }
    return true;
  }

  /**
   * @dev revokeOperator
   * @param _operators addresses
   */
  function revokeOperators(address[] memory _operators)
    override public onlySysOp returns (bool)
  {
    for (uint256 i=0; i < _operators.length; i++) {
      OperatorData storage operator = operators[_operators[i]];
      require(operator.coreRole != bytes32(0), "OC08");
      operator.coreRole = bytes32(0);

      emit OperatorRevoked(_operators[i]);
    }
    return true;
  }

  /**
   * @dev revokeProxyOperator
   * @param _operators addresses
   */
  function revokeProxyOperators(address _proxy, address[] memory _operators)
    override public onlySysOp returns (bool)
  {
    for (uint256 i=0; i < _operators.length; i++) {
      OperatorData storage operator = operators[_operators[i]];
      require(operator.proxyRoles[_proxy] != bytes32(0), "OC08");
      operator.proxyRoles[_proxy] = bytes32(0);

      emit ProxyOperatorRevoked(_proxy, _operators[i]);
    }
    return true;
  }

  function defineProxy(address _proxy, uint256 _delegateId)
    override public onlyCoreOp returns (bool)
  {
    require(_proxy != ALL_PROXIES, "OC06");
    defineProxyInternal(_proxy, _delegateId);
    emit ProxyDefined(_proxy, _delegateId);
    return true;
  }

  function migrateProxy(address _proxy, address _newCore)
    override public onlyCoreOp returns (bool)
  {
    migrateProxyInternal(_proxy, _newCore);
    emit ProxyMigrated(_proxy, _newCore);
    return true;
  }

  function removeProxy(address _proxy)
    override public onlyCoreOp returns (bool)
  {
    removeProxyInternal(_proxy);
    emit ProxyRemoved(_proxy);
    return true;
  }
}

// File: @c-layer/common/contracts/core/OperableProxy.sol

pragma solidity ^0.6.0;




/**
 * @title OperableProxy
 * @dev The OperableAs contract enable the restrictions of operations to a set of operators
 * @dev It relies on another Operable contract and reuse the same list of operators
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * OP01: Message sender must be authorized
 */
contract OperableProxy is Proxy {

  // solhint-disable-next-line no-empty-blocks
  constructor(address _core) public Proxy(_core) { }

  /**
   * @dev Throws if called by any account other than the operator
   */
  modifier onlyOperator {
    require(OperableCore(core).hasProxyPrivilege(
      msg.sender, address(this), msg.sig), "OP01");
    _;
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

// File: contracts/interface/ITokenProxy.sol

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

// File: contracts/interface/ITokenCore.sol

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

// File: contracts/interface/ITokenDelegate.sol

pragma solidity ^0.6.0;



/**
 * @title Token Delegate Interface
 * @dev Token Delegate Interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
abstract contract ITokenDelegate is ITokenStorage {

  function decimals() virtual public view returns (uint256);
  function totalSupply() virtual public view returns (uint256);
  function balanceOf(address _owner) virtual public view returns (uint256);
  function allowance(address _owner, address _spender)
    virtual public view returns (uint256);
  function transfer(address _sender, address _receiver, uint256 _value)
    virtual public returns (bool);
  function transferFrom(
    address _caller, address _sender, address _receiver, uint256 _value)
    virtual public returns (bool);
  function canTransfer(
    address _sender,
    address _receiver,
    uint256 _value) virtual public view returns (TransferCode);
  function approve(address _sender, address _spender, uint256 _value)
    virtual public returns (bool);
  function increaseApproval(address _sender, address _spender, uint _addedValue)
    virtual public returns (bool);
  function decreaseApproval(address _sender, address _spender, uint _subtractedValue)
    virtual public returns (bool);
  function checkConfigurations(uint256[] memory _auditConfigurationIds)
    virtual public returns (bool);
}

// File: contracts/TokenCore.sol

pragma solidity ^0.6.0;






/**
 * @title TokenCore
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 *   TC01: Token cannot be equivalent to AllProxies
 *   TC02: Currency stored values must remain consistent
 *   TC03: Delegate has invalid audit configurations values
 *   TC04: Mismatched between the configuration and the audit storage currency
 *   TC05: The audit triggers definition requires the same number of addresses and values
 **/
contract TokenCore is ITokenCore, OperableCore, TokenStorage {

  /**
   * @dev constructor
   */
  constructor(string memory _name, address[] memory _sysOperators)
    public OperableCore(_sysOperators)
  {
    name_ = _name;
  }

  function name() override public view returns (string memory) {
    return name_;
  }

  function oracle() override public view returns (
    IUserRegistry userRegistry,
    IRatesProvider ratesProvider,
    address currency)
  {
    return (userRegistry_, ratesProvider_, currency_);
  }

  function auditConfiguration(uint256 _configurationId)
    override public view returns (
      uint256 scopeId,
      AuditTriggerMode mode,
      uint256[] memory senderKeys,
      uint256[] memory receiverKeys,
      IRatesProvider ratesProvider,
      address currency)
  {
    AuditConfiguration storage auditConfiguration_ = auditConfigurations[_configurationId];
    return (
      auditConfiguration_.scopeId,
      auditConfiguration_.triggers[ANY_ADDRESSES][ANY_ADDRESSES],
      auditConfiguration_.senderKeys,
      auditConfiguration_.receiverKeys,
      auditConfiguration_.ratesProvider,
      audits[address(this)][auditConfiguration_.scopeId].currency
    );
  }

  function auditTrigger(uint256 _configurationId, address _sender, address _receiver)
    override public view returns (AuditTriggerMode)
  {
    return auditConfigurations[_configurationId].triggers[_sender][_receiver];
  }

  function delegatesConfigurations(uint256 _delegateId)
    override public view returns (uint256[] memory)
  {
    return delegatesConfigurations_[_delegateId];
  }

  function auditCurrency(
    address _scope,
    uint256 _scopeId
  ) override external view returns (address currency) {
    return audits[_scope][_scopeId].currency;
  }

  function audit(
    address _scope,
    uint256 _scopeId,
    AuditStorageMode _storageMode,
    bytes32 _storageId) override external view returns (
    uint64 createdAt,
    uint64 lastTransactionAt,
    uint256 cumulatedEmission,
    uint256 cumulatedReception)
  {
    AuditData memory auditData;
    if (_storageMode == AuditStorageMode.SHARED) {
      auditData = audits[_scope][_scopeId].sharedData;
    }
    if (_storageMode == AuditStorageMode.ADDRESS) {
      auditData = audits[_scope][_scopeId].addressData[address(bytes20(_storageId))];
    }
    if (_storageMode == AuditStorageMode.USER_ID) {
      auditData = audits[_scope][_scopeId].userData[uint256(_storageId)];
    }

    createdAt = auditData.createdAt;
    lastTransactionAt = auditData.lastTransactionAt;
    cumulatedEmission = auditData.cumulatedEmission;
    cumulatedReception = auditData.cumulatedReception;
  }

  /**************  ERC20  **************/
  function tokenName() override external view returns (string memory) {
    return tokens[msg.sender].name;
  }

  function tokenSymbol() override external view returns (string memory) {
    return tokens[msg.sender].symbol;
  }

  function decimals() override external onlyProxy returns (uint256) {
    return delegateCallUint256(msg.sender);
  }

  function totalSupply() override external onlyProxy returns (uint256) {
    return delegateCallUint256(msg.sender);
  }

  function balanceOf(address) external onlyProxy override returns (uint256) {
    return delegateCallUint256(msg.sender);
  }

  function allowance(address, address)
    override external onlyProxy returns (uint256)
  {
    return delegateCallUint256(msg.sender);
  }

  function transfer(address, address, uint256)
    override external onlyProxy returns (bool status)
  {
    return delegateCall(msg.sender);
  }

  function transferFrom(address, address, address, uint256)
    override external onlyProxy returns (bool status)
  {
    return delegateCall(msg.sender);
  }

  function approve(address, address, uint256)
    override external onlyProxy returns (bool status)
  {
    return delegateCall(msg.sender);
  }

  function increaseApproval(address, address, uint256)
    override external onlyProxy returns (bool status)
  {
    return delegateCall(msg.sender);
  }

  function decreaseApproval(address, address, uint256)
    override external onlyProxy returns (bool status)
  {
    return delegateCall(msg.sender);
  }

  /***********  TOKEN DATA   ***********/
  function token(address _token) override external view returns (
    bool mintingFinished,
    uint256 allTimeMinted,
    uint256 allTimeBurned,
    uint256 allTimeSeized,
    address[] memory locks,
    uint256 frozenUntil,
    IRule[] memory rules) {
    TokenData storage tokenData = tokens[_token];

    mintingFinished = tokenData.mintingFinished;
    allTimeMinted = tokenData.allTimeMinted;
    allTimeBurned = tokenData.allTimeBurned;
    allTimeSeized = tokenData.allTimeSeized;
    locks = tokenData.locks;
    frozenUntil = tokenData.frozenUntils[_token];
    rules = tokenData.rules;
  }

  function lock(address _lock, address _sender, address _receiver) override external view returns (
    uint64 startAt, uint64 endAt)
  {
    LockData storage lockData_ = locks[_lock][_sender][_receiver];
    return (lockData_.startAt, lockData_.endAt);
  }

  function canTransfer(address, address, uint256)
    override external onlyProxy returns (uint256)
  {
    return delegateCallUint256(msg.sender);
  }

  /***********  TOKEN ADMIN  ***********/
  function mint(address _token, address[] calldata, uint256[] calldata)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function finishMinting(address _token)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function burn(address _token, uint256)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function seize(address _token, address, uint256)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function freezeManyAddresses(
    address _token,
    address[] calldata,
    uint256) override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function defineLock(address _lock, address, address, uint64, uint64)
    override external onlyProxyOp(_lock) returns (bool)
  {
    return delegateCall(_lock);
  }

  function defineTokenLocks(address _token, address[] calldata)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  function defineRules(address _token, IRule[] calldata)
    override external onlyProxyOp(_token) returns (bool)
  {
    return delegateCall(_token);
  }

  /************  CORE ADMIN  ************/
  function removeProxyInternal(address _token)
    internal override returns (bool)
  {
    super.removeProxyInternal(_token);
    delete tokens[_token];
    return true;
  }

  function defineToken(
    address _token,
    uint256 _delegateId,
    string calldata _name,
    string calldata _symbol,
    uint256 _decimals)
    override external onlyCoreOp returns (bool)
  {
    require(_token != ALL_PROXIES, "TC01");
    defineProxy(_token, _delegateId);
    TokenData storage tokenData = tokens[_token];
    tokenData.name = _name;
    tokenData.symbol = _symbol;
    tokenData.decimals = _decimals;

    emit TokenDefined(_token, _name, _symbol, _decimals);
    return true;
  }

  function defineOracle(
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    address _currency)
    override external onlyCoreOp returns (bool)
  {
    userRegistry_ = _userRegistry;
    ratesProvider_ = _ratesProvider;
    currency_ = _currency;

    emit OracleDefined(userRegistry_, _ratesProvider, _currency);
    return true;
  }

  function defineTokenDelegate(
    uint256 _delegateId,
    address _delegate,
    uint256[] calldata _auditConfigurations) override external onlyCoreOp returns (bool)
  {
    require(_delegate == address(0) ||
      ITokenDelegate(_delegate).checkConfigurations(_auditConfigurations), "TC03");

    defineDelegateInternal(_delegateId, _delegate);
    if(_delegate != address(0)) {
      delegatesConfigurations_[_delegateId] = _auditConfigurations;
      emit TokenDelegateDefined(_delegateId, _delegate, _auditConfigurations);
    } else {
      delete delegatesConfigurations_[_delegateId];
      emit TokenDelegateRemoved(_delegateId);
    }
    return true;
  }

  function defineAuditConfiguration(
    uint256 _configurationId,
    uint256 _scopeId,
    AuditTriggerMode _mode,
    uint256[] calldata _senderKeys,
    uint256[] calldata _receiverKeys,
    IRatesProvider _ratesProvider,
    address _currency) override external onlyCoreOp returns (bool)
  {
    // Mark permanently the core audit storage with the currency to be used with
    AuditStorage storage auditStorage = audits[address(this)][_scopeId];
    if(auditStorage.currency == address(0)) {
      auditStorage.currency = _currency;
    } else {
      require(auditStorage.currency == _currency, "TC04");
    }

    AuditConfiguration storage auditConfiguration_ = auditConfigurations[_configurationId];
    auditConfiguration_.scopeId = _scopeId;
    auditConfiguration_.senderKeys = _senderKeys;
    auditConfiguration_.receiverKeys = _receiverKeys;
    auditConfiguration_.ratesProvider = _ratesProvider;
    auditConfiguration_.triggers[ANY_ADDRESSES][ANY_ADDRESSES] = _mode;

    emit AuditConfigurationDefined(
      _configurationId,
      _scopeId,
      _mode,
      _senderKeys,
      _receiverKeys,
      _ratesProvider,
      _currency);
    return true;
  }

  function removeAudits(address _scope, uint256 _scopeId)
    override external onlyCoreOp returns (bool)
  {
    delete audits[_scope][_scopeId];
    emit AuditsRemoved(_scope, _scopeId);
    return true;
  }

  function defineAuditTriggers(
    uint256 _configurationId,
    address[] calldata _senders,
    address[] calldata _receivers,
    AuditTriggerMode[] calldata _modes) override external onlyCoreOp returns (bool)
  {
    require(_senders.length == _receivers.length && _senders.length == _modes.length, "TC05");

    AuditConfiguration storage auditConfiguration_ = auditConfigurations[_configurationId];
    for(uint256 i=0; i < _senders.length; i++) {
      auditConfiguration_.triggers[_senders[i]][_receivers[i]] = _modes[i];
    }

    emit AuditTriggersDefined(_configurationId, _senders, _receivers, _modes);
    return true;
  }

  function isSelfManaged(address _owner)
    override external view returns (bool)
  {
    return selfManaged[_owner];
  }

  function manageSelf(bool _active)
    override external returns (bool)
  {
    selfManaged[msg.sender] = _active;
    emit SelfManaged(msg.sender, _active);
  }
}

// File: contracts/TokenProxy.sol

pragma solidity ^0.6.0;





/**
 * @title Token proxy
 * @dev Token proxy default implementation
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
contract TokenProxy is ITokenProxy, OperableProxy {

  // solhint-disable-next-line no-empty-blocks
  constructor(address _core) public OperableProxy(_core) { }

  function name() override public view returns (string memory) {
    return TokenCore(core).tokenName();
  }

  function symbol() override public view returns (string memory) {
    return TokenCore(core).tokenSymbol();
  }

  function decimals() override public view returns (uint256) {
    return staticCallUint256();
  }

  function totalSupply() override public view returns (uint256) {
    return staticCallUint256();
  }

  function balanceOf(address) override public view returns (uint256) {
    return staticCallUint256();
  }

  function allowance(address, address)
    override public view returns (uint256)
  {
    return staticCallUint256();
  }

  function transfer(address _to, uint256 _value) override public returns (bool status)
  {
    return TokenCore(core).transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value)
    override public returns (bool status)
  {
    return TokenCore(core).transferFrom(msg.sender, _from, _to, _value);
  }

  function approve(address _spender, uint256 _value)
    override public returns (bool status)
  {
    return TokenCore(core).approve(msg.sender, _spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue)
    override public returns (bool status)
  {
    return TokenCore(core).increaseApproval(msg.sender, _spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    override public returns (bool status)
  {
    return TokenCore(core).decreaseApproval(msg.sender, _spender, _subtractedValue);
  }

  function canTransfer(address, address, uint256)
    override public view returns (uint256)
  {
    return staticCallUint256();
  }

  function emitTransfer(address _from, address _to, uint256 _value)
    override public onlyCore returns (bool)
  {
    emit Transfer(_from, _to, _value);
    return true;
  }

  function emitApproval(address _owner, address _spender, uint256 _value)
    override public onlyCore returns (bool)
  {
    emit Approval(_owner, _spender, _value);
    return true;
  }
}

// File: contracts/delegate/MintableDelegate.sol

pragma solidity ^0.6.0;




/**
 * @title MintableDelegate
 * @dev MintableDelegate contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * MT01: Transfer events must be generated
 * MT02: Token is already minted
 * MT03: Parameters must be same length
 */
abstract contract MintableDelegate is TokenStorage {

  modifier canMint(address _token) {
    require(!tokens[_token].mintingFinished, "MT02");
    _;
  }

  /**
   * @dev Function to burn tokens
   * @param _amount The amount of tokens to burn.
   * @return A boolean that indicates if the operation was successful.
   */
  function burn(address _token, uint256 _amount)
    public returns (bool)
  {
    TokenData storage token = tokens[_token];
    token.totalSupply = token.totalSupply.sub(_amount);
    token.balances[msg.sender] = token.balances[msg.sender].sub(_amount);
    token.allTimeBurned = token.allTimeBurned.add(_amount);

    require(
      TokenProxy(_token).emitTransfer(msg.sender, address(0), _amount),
      "MT01");
    emit Burned(_token, _amount);
    return true;
  }

  /**
   * @dev Function to mint all tokens at once
   * @param _recipients The addresses that will receive the minted tokens.
   * @param _amounts The amounts of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _token, address[] memory _recipients, uint256[] memory _amounts)
    public canMint(_token) returns (bool)
  {
    require(_recipients.length == _amounts.length, "MT03");

    bool result = true;
    for (uint256 i=0; i < _recipients.length; i++) {
      result = result && mintInternal(_token, _recipients[i], _amounts[i]);
    }
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting(address _token)
    public canMint(_token) returns (bool)
  {
    tokens[_token].mintingFinished = true;
    emit MintFinished(_token);
    return true;
  }

  /**
   * @dev Function to mint tokens internal
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mintInternal(address _token, address _to, uint256 _amount)
    virtual internal canMint(_token) returns (bool)
  {
    TokenData storage token = tokens[_token];
    token.totalSupply = token.totalSupply.add(_amount);
    token.balances[_to] = token.balances[_to].add(_amount);
    token.allTimeMinted = token.allTimeMinted.add(_amount);

    require(
      TokenProxy(_token).emitTransfer(address(0), _to, _amount),
      "MT01");
    emit Minted(_token, _amount);
    return true;
  }
}

// File: contracts/delegate/STransferData.sol

pragma solidity ^0.6.0;

/**
 * @title STransferData
 * @dev STransferData structure
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
**/

struct STransferData {
  address token;
  address caller;
  address sender;
  address receiver;

  uint256 senderId;
  uint256[] senderKeys;
  bool senderFetched;

  uint256 receiverId;
  uint256[] receiverKeys;
  bool receiverFetched;

  uint256 value;
  uint256 convertedValue;
}

// File: contracts/delegate/BaseTokenDelegate.sol

pragma solidity ^0.6.0;






/**
 * @title Base Token Delegate
 * @dev Base Token Delegate
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * TD01: Recipient must not be null or be a reserved address
 * TD02: Not enougth tokens
 * TD03: Transfer event must be generated
 * TD04: Allowance limit reached
 */
contract BaseTokenDelegate is ITokenDelegate, TokenStorage {

  function decimals() virtual override public view returns (uint256) {
    return tokens[msg.sender].decimals;
  }

  function totalSupply() virtual override public view returns (uint256) {
    return tokens[msg.sender].totalSupply;
  }

  function balanceOf(address _owner) virtual override public view returns (uint256) {
    return tokens[msg.sender].balances[_owner];
  }

  function allowance(address _owner, address _spender)
    virtual override public view returns (uint256)
  {
    return tokens[msg.sender].allowances[_owner][_spender];
  }

  /**
   * @dev Overriden transfer function
   */
  function transfer(address _sender, address _receiver, uint256 _value)
    virtual override public returns (bool)
  {
    return transferInternal(
      transferData(msg.sender, address(0), _sender, _receiver, _value));
  }

  /**
   * @dev Overriden transferFrom function
   */
  function transferFrom(
    address _caller, address _sender, address _receiver, uint256 _value)
    virtual override public returns (bool)
  {
    return transferInternal(
      transferData(msg.sender, _caller, _sender, _receiver, _value));
  }

  /**
   * @dev can transfer
   */
  function canTransfer(
    address _sender,
    address _receiver,
    uint256 _value) virtual override public view returns (TransferCode)
  {
    return canTransferInternal(
      transferData(msg.sender, address(0), _sender, _receiver, _value));
  }

  /**
   * @dev approve
   */
  function approve(address _sender, address _spender, uint256 _value)
    virtual override public returns (bool)
  {
    TokenData storage token = tokens[msg.sender];
    token.allowances[_sender][_spender] = _value;
    require(
      TokenProxy(msg.sender).emitApproval(_sender, _spender, _value),
      "TD03");
    return true;
  }

  /**
   * @dev increase approval
   */
  function increaseApproval(address _sender, address _spender, uint _addedValue)
    virtual override public returns (bool)
  {
    TokenData storage token = tokens[msg.sender];
    token.allowances[_sender][_spender] = (
      token.allowances[_sender][_spender].add(_addedValue));
    require(
      TokenProxy(msg.sender).emitApproval(_sender, _spender, token.allowances[_sender][_spender]),
      "TD03");
    return true;
  }

  /**
   * @dev decrease approval
   */
  function decreaseApproval(address _sender, address _spender, uint _subtractedValue)
    virtual override public returns (bool)
  {
    TokenData storage token = tokens[msg.sender];
    uint oldValue = token.allowances[_sender][_spender];
    if (_subtractedValue > oldValue) {
      token.allowances[_sender][_spender] = 0;
    } else {
      token.allowances[_sender][_spender] = oldValue.sub(_subtractedValue);
    }
    require(
      TokenProxy(msg.sender).emitApproval(_sender, _spender, token.allowances[_sender][_spender]),
      "TD03");
    return true;
  }

  /**
   * @dev check configuration
   **/
  function checkConfigurations(uint256[] memory) virtual override public returns (bool) {
    return true;
  }

  /**
   * @dev transfer
   */
  function transferInternal(STransferData memory _transferData)
    virtual internal returns (bool)
  {
    TokenData storage token = tokens[_transferData.token];
    address caller = _transferData.caller;
    address sender = _transferData.sender;
    address receiver = _transferData.receiver;
    uint256 value = _transferData.value;

    require(receiver != address(0) || receiver != ANY_ADDRESSES, "TD01");
    require(value <= token.balances[sender], "TD02");

    if (caller != address(0)
      && (selfManaged[sender]
        || !hasProxyPrivilege(caller, _transferData.token, msg.sig)))
    {
      require(value <= token.allowances[sender][caller], "TD04");
      token.allowances[sender][caller] = token.allowances[sender][caller].sub(value);
    }

    token.balances[sender] = token.balances[sender].sub(value);
    token.balances[receiver] = token.balances[receiver].add(value);
    require(
      TokenProxy(msg.sender).emitTransfer(sender, receiver, value),
      "TD03");
    return true;
  }

  /**
   * @dev can transfer
   */
  function canTransferInternal(STransferData memory _transferData)
    virtual internal view returns (TransferCode)
  {
    TokenData storage token = tokens[_transferData.token];
    address sender = _transferData.sender;
    address receiver = _transferData.receiver;
    uint256 value = _transferData.value;

    if (sender == address(0)) {
      return TransferCode.INVALID_SENDER;
    }

    if (receiver == address(0)) {
      return TransferCode.NO_RECIPIENT;
    }

    if (value > token.balances[sender]) {
      return TransferCode.INSUFFICIENT_TOKENS;
    }

    return TransferCode.OK;
  }

  /**
   * @dev transferData
   */
  function transferData(
    address _token, address _caller,
    address _sender, address _receiver, uint256 _value)
    internal pure returns (STransferData memory)
  {
    uint256[] memory emptyArray = new uint256[](1);
    return STransferData(
        _token,
        _caller,
        _sender,
        _receiver,
        0,
        emptyArray,
        false,
        0,
        emptyArray,
        false,
        _value,
        0
    );
  }
}

// File: contracts/delegate/RuleEngineDelegate.sol

pragma solidity ^0.6.0;





/**
 * @title RuleEngineDelegate
 * @dev RuleEngineDelegate contract
 * TokenRuleEngine is a token that will apply
 * rules restricting transferability
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 **/
abstract contract RuleEngineDelegate is TokenStorage {

  /**
   * @dev Define rules to the token
   */
  function defineRules(address _token, IRule[] memory _rules)
    public returns (bool)
  {
    tokens[_token].rules = _rules;
    emit RulesDefined(_token, _rules);
    return true;
  }

  /**
   * @dev Check if the rules are valid
   */
  function areTransferRulesValid(STransferData memory _transferData)
    internal view returns (bool)
  {
    IRule[] memory rules_ = tokens[_transferData.token].rules;
    for (uint256 i = 0; i < rules_.length; i++) {
      if (!rules_[i].isTransferValid(_transferData.sender, _transferData.receiver, _transferData.value)) {
        return false;
      }
    }
    return true;
  }
}

// File: contracts/delegate/MintableTokenDelegate.sol

pragma solidity ^0.6.0;





/**
 * @title Token Delegate
 * @dev Token Delegate
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 */
contract MintableTokenDelegate is RuleEngineDelegate, MintableDelegate, BaseTokenDelegate {
}

// File: contracts/delegate/SeizableDelegate.sol

pragma solidity ^0.6.0;




/**
 * @title SeizableDelegate
 * @dev Token which allows owner to seize accounts
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * ST01: Transfer events must be generated
 * ST02: Operator cannot seize itself
*/
abstract contract SeizableDelegate is TokenStorage {

  /**
   * @dev called by the owner to seize value from the account
   */
  function seize(
    address _token,
    address _account,
    uint256 _amount) public returns (bool)
  {
    require(_account != msg.sender, "ST02");
    TokenData storage token = tokens[_token];

    token.balances[_account] = token.balances[_account].sub(_amount);
    token.balances[msg.sender] = token.balances[msg.sender].add(_amount);
    token.allTimeSeized = token.allTimeSeized.add(_amount);

    require(
      TokenProxy(_token).emitTransfer(_account, msg.sender, _amount),
      "ST01");
    emit Seize(_token, _account, _amount);
    return true;
  }
}

// File: contracts/delegate/FreezableDelegate.sol

pragma solidity ^0.6.0;




/**
 * @title FreezableDelegate
 * @dev FreezableDelegate contract
 * This rule allow a legal authority to enforce a freeze of assets.
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * FTD01: The address is frozen
 */
abstract contract FreezableDelegate is TokenStorage {

  /**
   * @dev allow owner to freeze several addresses
   * @param _until allows to auto unlock if the frozen time is known initially.
   * otherwise infinity can be used
   */
  function freezeManyAddresses(
    address _token,
    address[] memory _addresses,
    uint256 _until) public returns (bool)
  {
    mapping(address => uint256) storage frozenUntils = tokens[_token].frozenUntils;
    for (uint256 i = 0; i < _addresses.length; i++) {
      frozenUntils[_addresses[i]] = _until;
      emit Freeze(_addresses[i], _until);
    }
    return true;
  }

  /**
   * @dev isFrozen
   */
  function isFrozen(STransferData memory _transferData) internal view returns (bool) {
    mapping(address => uint256) storage frozenUntils = tokens[_transferData.token].frozenUntils;
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = now;
    return currentTime < frozenUntils[_transferData.caller]
      || currentTime < frozenUntils[_transferData.sender]
      || currentTime < frozenUntils[_transferData.receiver];
  }
}

// File: contracts/delegate/LockableDelegate.sol

pragma solidity ^0.6.0;




/**
 * @title LockableDelegate
 * @dev LockableDelegate contract
 * This rule allows to lock assets for a period of time
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * LD01: locks must be valid proxies
 * LD02: startAt must be before or equal to endAt
 */
abstract contract LockableDelegate is TokenStorage {

  /**
   * @dev define token lock
   */
  function defineTokenLocks(address _token, address[] memory _locks) public returns (bool)
  {
    for(uint256 i=0; i < _locks.length; i++) {
      require(delegates[proxyDelegateIds[_locks[i]]] != address(0), "LD01");
    }

    tokens[_token].locks = _locks;
    emit TokenLocksDefined(_token, _locks);
  }

  /**
   * @dev define lock
   */
  function defineLock(
    address _lock,
    address _sender,
    address _receiver,
    uint64 _startAt,
    uint64 _endAt) public returns (bool)
  {
    require(_startAt <= _endAt, "LD02");
    locks[_lock][_sender][_receiver] = LockData(_startAt, _endAt);
    emit LockDefined(_lock, _sender, _receiver, _startAt, _endAt);
    return true;
  }

  /**
   * @dev isLocked
   */
  function isLocked(STransferData memory _transferData)
    internal view returns (bool isLocked_)
  {
    address[] storage lockAddresses = tokens[_transferData.token].locks;

    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = now;

    for (uint256 i=0; i < lockAddresses.length && !isLocked_; i++) {
      address lockAddress = lockAddresses[i];
      LockData storage lockData = locks[lockAddress][_transferData.sender][_transferData.receiver];

      if (lockData.endAt < currentTime) {
        LockData storage senderLockData = locks[lockAddress][_transferData.sender][ANY_ADDRESSES];
        LockData storage receiverLockData = locks[lockAddress][ANY_ADDRESSES][_transferData.receiver];

        if (senderLockData.endAt >= currentTime && receiverLockData.endAt >= currentTime) {
          isLocked_ =
            (currentTime < senderLockData.endAt && currentTime >= senderLockData.startAt) ||
            (currentTime < receiverLockData.endAt && currentTime >= receiverLockData.startAt);
          continue;
        }

        lockData = senderLockData;
        if (lockData.endAt < currentTime) {
          lockData = receiverLockData;
        }
      }

      if (lockData.endAt < currentTime) {
        lockData = locks[lockAddress][ANY_ADDRESSES][ANY_ADDRESSES];
      }

      isLocked_ =
        (currentTime < lockData.endAt && currentTime >= lockData.startAt);
    }
  }
}

// File: contracts/delegate/STransferAuditData.sol

pragma solidity ^0.6.0;



/**
 * @title STransferAuditData
 * @dev SAuditData structure
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
**/

struct STransferAuditData {
  uint256 auditConfigurationId;
  uint256 scopeId;
  address currency;
  IRatesProvider ratesProvider;

  bool senderAuditRequired;
  bool receiverAuditRequired;
}

// File: contracts/delegate/OracleEnrichedDelegate.sol

pragma solidity ^0.6.0;





/**
 * @title OracleEnrichedDelegate
 * @dev OracleEnrichedDelegate contract
 * @dev Enriched the transfer with oracle's informations
 * @dev needed for the delegate processing
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 */
contract OracleEnrichedDelegate is TokenStorage {

  uint256 internal constant SENDER_LIMIT_ID = 0;
  uint256 internal constant RECEIVER_LIMIT_ID = 0;

  /**
   * @dev fetchSenderUserId
   */
  function fetchSenderUserId(STransferData memory _transferData) internal view
  {
    if (!_transferData.senderFetched) {
      _transferData.senderId = userRegistry_.validUserId(_transferData.sender);
      _transferData.senderFetched = true;
    }
  }

  /**
   * @dev fetchSenderUser
   */
  function fetchSenderUser(STransferData memory _transferData,
     STransferAuditData memory _transferAuditData) internal view
  {
    if (!_transferData.senderFetched) {
      (_transferData.senderId, _transferData.senderKeys) =
        userRegistry_.validUser(_transferData.sender,
        auditConfigurations[_transferAuditData.auditConfigurationId].senderKeys);
      _transferData.senderFetched = true;
    }
  }

  /**
   * @dev fetchReceiverUserId
   */
  function fetchReceiverUserId(STransferData memory _transferData) internal view
  {
    if (!_transferData.receiverFetched) {
      _transferData.receiverId = userRegistry_.validUserId(_transferData.receiver);
      _transferData.receiverFetched = true;
    }
  }

  /**
   * @dev fetchReceiverUser
   */
  function fetchReceiverUser(STransferData memory _transferData,
    STransferAuditData memory _transferAuditData) internal view
  {
    if (!_transferData.receiverFetched) {
      (_transferData.receiverId, _transferData.receiverKeys) =
        userRegistry_.validUser(_transferData.receiver,
        auditConfigurations[_transferAuditData.auditConfigurationId].receiverKeys);
      _transferData.receiverFetched = true;
    }
  }

  /**
   * @dev fetchConvertedValue
   * @dev warning: a converted value of 0 should be considered invalid
   * @dev it is left to the code calling this function to handle this case
   */
  function fetchConvertedValue(STransferData memory _transferData,
    STransferAuditData memory _transferAuditData) internal view
  {
    if (_transferData.convertedValue == 0 && _transferData.value != 0) {
      address currencyFrom = _transferData.token;
      _transferData.convertedValue = (
         _transferAuditData.currency != address(0) && currencyFrom != _transferAuditData.currency
      ) ? _transferAuditData.ratesProvider.convert(_transferData.value,
            bytes32(bytes20(currencyFrom)), bytes32(bytes20(_transferAuditData.currency))
          ) : _transferData.value;
    }
  }
}

// File: contracts/delegate/AuditableDelegate.sol

pragma solidity ^0.6.0;



/**
 * @title AuditableDelegate
 * @dev Auditable delegate contract
 * Auditable provides transaction data which can be used
 * in other smart contracts
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * AT01: Configuration and User Registry must have the same currency
 **/
contract AuditableDelegate is OracleEnrichedDelegate {

  uint256 internal constant AUDIT_CONFIGURATION_LIMITABLE_TRANSFERABILITY = 0;

  /**
   * @dev prepareAuditInternal
   */
  function prepareAuditInternal(STransferData memory _transferData)
    internal view returns (STransferAuditData memory)
  {
    uint256 configurationId = delegatesConfigurations_[proxyDelegateIds[_transferData.token]
      ][AUDIT_CONFIGURATION_LIMITABLE_TRANSFERABILITY];
    AuditConfiguration storage configuration = auditConfigurations[configurationId];

    AuditTriggerMode mode = configuration.triggers[_transferData.sender][_transferData.receiver];
    if (mode == AuditTriggerMode.UNDEFINED) {
      mode = configuration.triggers[_transferData.sender][ANY_ADDRESSES];
    }
    if (mode == AuditTriggerMode.UNDEFINED) {
      mode = configuration.triggers[ANY_ADDRESSES][_transferData.receiver];
    }
    if (mode == AuditTriggerMode.UNDEFINED) {
      mode = configuration.triggers[ANY_ADDRESSES][ANY_ADDRESSES];
    }

    return STransferAuditData(
      configurationId,
      configuration.scopeId,
      audits[address(this)][configuration.scopeId].currency,
      configuration.ratesProvider,
      (mode == AuditTriggerMode.BOTH || mode == AuditTriggerMode.SENDER_ONLY),
      (mode == AuditTriggerMode.BOTH || mode == AuditTriggerMode.RECEIVER_ONLY)
    );
  }

  /**
   * @dev Update audit data
   */
  function updateAllAuditsInternal(STransferData memory _transferData,
    STransferAuditData memory _transferAuditData) internal returns (bool)
  {
    uint64 transactionAt = currentTime();
    audits[_transferData.token][uint256(Scope.DEFAULT)
      ].addressData[_transferData.sender].lastTransactionAt = transactionAt;
    audits[_transferData.token][uint256(Scope.DEFAULT)
      ].addressData[_transferData.sender].lastTransactionAt = transactionAt;

    if (_transferAuditData.senderAuditRequired || _transferAuditData.receiverAuditRequired) {
      fetchConvertedValue(_transferData, _transferAuditData);

      if (_transferAuditData.senderAuditRequired) {
        fetchSenderUser(_transferData, _transferAuditData);
        if (_transferData.senderId != 0) {
          AuditData storage senderAudit =
            audits[address(this)][_transferAuditData.scopeId].userData[_transferData.senderId];
          if (senderAudit.createdAt == 0) {
            senderAudit.createdAt = transactionAt;
          }

          senderAudit.cumulatedEmission =
            senderAudit.cumulatedEmission.add(_transferData.convertedValue);
        }
      }

      if (_transferAuditData.receiverAuditRequired) {
        fetchReceiverUser(_transferData, _transferAuditData);
        if (_transferData.receiverId != 0) {
          AuditData storage receiverAudit =
            audits[address(this)][_transferAuditData.scopeId].userData[_transferData.receiverId];
          if (receiverAudit.createdAt == 0) {
            receiverAudit.createdAt = transactionAt;
          }
          receiverAudit.cumulatedReception =
            receiverAudit.cumulatedReception.add(_transferData.convertedValue);
        }
      }
    }
    return true;
  }
}

// File: contracts/delegate/KYCOnlyTransferabilityDelegate.sol

pragma solidity ^0.6.0;



/**
 * @title KYCOnlyTransferabilityDelegate
 * @dev KYCOnlyTransferabilityDelegate contract
 * This rule allow a legal authority to limite the transferability.
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messages
 * LR01: The transfer constraints must remain valid
*/
contract KYCOnlyTransferabilityDelegate is AuditableDelegate {

  /**
   * @dev hasTransferValidUsers
   */
  function hasTransferValidUsers(STransferData memory _transferData,
    STransferAuditData memory _transferAuditData) internal view returns (TransferCode code)
  {
    if (_transferAuditData.senderAuditRequired) {
      fetchSenderUserId(_transferData);
      if (_transferData.senderId == 0) {
        return TransferCode.NON_REGISTRED_SENDER;
      }
    }

    if (_transferAuditData.receiverAuditRequired) {
      fetchReceiverUserId(_transferData);
      if (_transferData.receiverId == 0) {
        return TransferCode.NON_REGISTRED_RECEIVER;
      }
    }
    return TransferCode.OK;
  }
}

// File: contracts/delegate/KYCOnlyTokenDelegate.sol

pragma solidity ^0.6.0;








/**
 * @title KYCOnly Token Delegate
 * @dev KYCOnly Token Delegate
 *
 * @author Cyril Lapinte - <cyril.lapinte@openfiz.com>
 *
 * Error messagesa
 * KOT01: The token must not be locked
 * KOT02: The addresses must not be frozen
 * KOT03: The transfer rules must be valid
 * KOT04: The sender or receiver are not valid
 */
contract KYCOnlyTokenDelegate is
  KYCOnlyTransferabilityDelegate,
  RuleEngineDelegate,
  SeizableDelegate,
  FreezableDelegate,
  LockableDelegate,
  MintableTokenDelegate
{

  uint256 internal constant AUDIT_CONFIG_REQUIREMENTS = 1; // 1- Transfer Limits

  /**
   * @dev check config requirements
   **/
  function checkConfigurations(uint256[] memory _auditConfigurationIds)
    override public returns (bool)
  {
    return (_auditConfigurationIds.length >= AUDIT_CONFIG_REQUIREMENTS);
  }

 /**
   * @dev transfer
   */
  function transferInternal(STransferData memory _transferData)
    override internal returns (bool)
  {
    require(!isLocked(_transferData), "KOT01");
    require(!isFrozen(_transferData), "KOT02");
    require(areTransferRulesValid(_transferData), "KOT03");

    STransferAuditData memory _transferAuditData =
      prepareAuditInternal(_transferData);
    require(hasTransferValidUsers(_transferData, _transferAuditData) == TransferCode.OK, "KOT04");

    return super.transferInternal(_transferData);
  }

  /**
   * @dev can transfer
   */
  function canTransferInternal(STransferData memory _transferData)
    override internal view returns (TransferCode code)
  {
    if (isLocked(_transferData)) {
      return TransferCode.LOCKED;
    }
    if (isFrozen(_transferData)) {
      return TransferCode.FROZEN;
    }
    if (!areTransferRulesValid(_transferData)) {
      return TransferCode.RULE;
    }

    STransferAuditData memory _transferAuditData =
      prepareAuditInternal(_transferData);
    code = hasTransferValidUsers(_transferData, _transferAuditData);

    return (code == TransferCode.OK) ?
      super.canTransferInternal(_transferData) : code;
  }
}