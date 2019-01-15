/* Author: Victor Mezrin  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a5d3ccc6d1cad7e5c8c0dfd7cccb8bc6cac8">[email&#160;protected]</a> */

pragma solidity ^0.4.24;



/**
 * @title OwnableInterface
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableInterface {

  /**
   * @dev The getter for "owner" contract variable
   */
  function getOwner() public constant returns (address);

  /**
   * @dev Throws if called by any account other than the current owner.
   */
  modifier onlyOwner() {
    require (msg.sender == getOwner());
    _;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is OwnableInterface {

  /* Storage */

  address owner = address(0x0);
  address proposedOwner = address(0x0);


  /* Events */

  event OwnerAssignedEvent(address indexed newowner);
  event OwnershipOfferCreatedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferAcceptedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferCancelledEvent(address indexed currentowner, address indexed proposedowner);


  /**
   * @dev The constructor sets the initial `owner` to the passed account.
   */
  constructor () public {
    owner = msg.sender;

    emit OwnerAssignedEvent(owner);
  }


  /**
   * @dev Old owner requests transfer ownership to the new owner.
   * @param _proposedOwner The address to transfer ownership to.
   */
  function createOwnershipOffer(address _proposedOwner) external onlyOwner {
    require (proposedOwner == address(0x0));
    require (_proposedOwner != address(0x0));
    require (_proposedOwner != address(this));

    proposedOwner = _proposedOwner;

    emit OwnershipOfferCreatedEvent(owner, _proposedOwner);
  }


  /**
   * @dev Allows the new owner to accept an ownership offer to contract control.
   */
  //noinspection UnprotectedFunction
  function acceptOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == proposedOwner);

    address _oldOwner = owner;
    owner = proposedOwner;
    proposedOwner = address(0x0);

    emit OwnerAssignedEvent(owner);
    emit OwnershipOfferAcceptedEvent(_oldOwner, owner);
  }


  /**
   * @dev Old owner cancels transfer ownership to the new owner.
   */
  function cancelOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == owner || msg.sender == proposedOwner);

    address _oldProposedOwner = proposedOwner;
    proposedOwner = address(0x0);

    emit OwnershipOfferCancelledEvent(owner, _oldProposedOwner);
  }


  /**
   * @dev The getter for "owner" contract variable
   */
  function getOwner() public constant returns (address) {
    return owner;
  }

  /**
   * @dev The getter for "proposedOwner" contract variable
   */
  function getProposedOwner() public constant returns (address) {
    return proposedOwner;
  }
}



/**
 * @title ManageableInterface
 * @dev Contract that allows to grant permissions to any address
 * @dev In real life we are no able to perform all actions with just one Ethereum address
 * @dev because risks are too high.
 * @dev Instead owner delegates rights to manage an contract to the different addresses and
 * @dev stay able to revoke permissions at any time.
 */
contract ManageableInterface {

  /**
   * @dev Function to check if the manager can perform the action or not
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager is enabled and has been granted needed permission
   */
  function isManagerAllowed(address _manager, string _permissionName) public constant returns (bool);

  /**
   * @dev Modifier to use in derived contracts
   */
  modifier onlyAllowedManager(string _permissionName) {
    require(isManagerAllowed(msg.sender, _permissionName) == true);
    _;
  }
}



contract Manageable is OwnableInterface,
                       ManageableInterface {

  /* Storage */

  mapping (address => bool) managerEnabled;  // hard switch for a manager - on/off
  mapping (address => mapping (string => bool)) managerPermissions;  // detailed info about manager`s permissions


  /* Events */

  event ManagerEnabledEvent(address indexed manager);
  event ManagerDisabledEvent(address indexed manager);
  event ManagerPermissionGrantedEvent(address indexed manager, bytes32 permission);
  event ManagerPermissionRevokedEvent(address indexed manager, bytes32 permission);


  /* Configure contract */

  /**
   * @dev Function to add new manager
   * @param _manager address New manager
   */
  function enableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;

    emit ManagerEnabledEvent(_manager);
  }

  /**
   * @dev Function to remove existing manager
   * @param _manager address Existing manager
   */
  function disableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;

    emit ManagerDisabledEvent(_manager);
  }

  /**
   * @dev Function to grant new permission to the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Granted permission name
   */
  function grantManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == false);

    managerPermissions[_manager][_permissionName] = true;

    emit ManagerPermissionGrantedEvent(_manager, keccak256(_permissionName));
  }

  /**
   * @dev Function to revoke permission of the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Revoked permission name
   */
  function revokeManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == true);

    managerPermissions[_manager][_permissionName] = false;

    emit ManagerPermissionRevokedEvent(_manager, keccak256(_permissionName));
  }


  /* Getters */

  /**
   * @dev Function to check manager status
   * @param _manager address Manager`s address
   * @return True if manager is enabled
   */
  function isManagerEnabled(
    address _manager
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    returns (bool)
  {
    return managerEnabled[_manager];
  }

  /**
   * @dev Function to check permissions of a manager
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager has been granted needed permission
   */
  function isPermissionGranted(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return managerPermissions[_manager][_permissionName];
  }

  /**
   * @dev Function to check if the manager can perform the action or not
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager is enabled and has been granted needed permission
   */
  function isManagerAllowed(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return (managerEnabled[_manager] && managerPermissions[_manager][_permissionName]);
  }


  /* Helpers */

  /**
   * @dev Modifier to check manager address
   */
  modifier onlyValidManagerAddress(address _manager) {
    require(_manager != address(0x0));
    _;
  }

  /**
   * @dev Modifier to check name of manager permission
   */
  modifier onlyValidPermissionName(string _permissionName) {
    require(bytes(_permissionName).length != 0);
    _;
  }
}



/**
 * @title PausableInterface
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Based on zeppelin&#39;s Pausable, but integrated with Manageable
 * @dev Contract is in paused state by default and should be explicitly unlocked
 */
contract PausableInterface {

  /**
   * Events
   */

  event PauseEvent();
  event UnpauseEvent();


  /**
   * @dev called by the manager to pause, triggers stopped state
   */
  function pauseContract() public;

  /**
   * @dev called by the manager to unpause, returns to normal state
   */
  function unpauseContract() public;

  /**
   * @dev The getter for "paused" contract variable
   */
  function getPaused() public constant returns (bool);


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenContractNotPaused() {
    require(getPaused() == false);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenContractPaused {
    require(getPaused() == true);
    _;
  }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Based on zeppelin&#39;s Pausable, but integrated with Manageable
 * @dev Contract is in paused state by default and should be explicitly unlocked
 */
contract Pausable is ManageableInterface,
                     PausableInterface {

  /**
   * Storage
   */

  bool paused = true;


  /**
   * @dev called by the manager to pause, triggers stopped state
   */
  function pauseContract() public onlyAllowedManager(&#39;pause_contract&#39;) whenContractNotPaused {
    paused = true;
    emit PauseEvent();
  }

  /**
   * @dev called by the manager to unpause, returns to normal state
   */
  function unpauseContract() public onlyAllowedManager(&#39;unpause_contract&#39;) whenContractPaused {
    paused = false;
    emit UnpauseEvent();
  }

  /**
   * @dev The getter for "paused" contract variable
   */
  function getPaused() public constant returns (bool) {
    return paused;
  }
}



/**
 * @title BytecodeExecutorInterface interface
 * @dev Implementation of a contract that execute any bytecode on behalf of the contract
 * @dev Last resort for the immutable and not-replaceable contract :)
 */
contract BytecodeExecutorInterface {

  /* Events */

  event CallExecutedEvent(address indexed target,
                          uint256 suppliedGas,
                          uint256 ethValue,
                          bytes32 transactionBytecodeHash);
  event DelegatecallExecutedEvent(address indexed target,
                                  uint256 suppliedGas,
                                  bytes32 transactionBytecodeHash);


  /* Functions */

  function executeCall(address _target, uint256 _suppliedGas, uint256 _ethValue, bytes _transactionBytecode) external;
  function executeDelegatecall(address _target, uint256 _suppliedGas, bytes _transactionBytecode) external;
}



/**
 * @title BytecodeExecutor
 * @dev Implementation of a contract that execute any bytecode on behalf of the contract
 * @dev Last resort for the immutable and not-replaceable contract :)
 */
contract BytecodeExecutor is ManageableInterface,
                             BytecodeExecutorInterface {

  /* Storage */

  bool underExecution = false;


  /* BytecodeExecutorInterface */

  function executeCall(
    address _target,
    uint256 _suppliedGas,
    uint256 _ethValue,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager(&#39;execute_call&#39;)
  {
    require(underExecution == false);

    underExecution = true; // Avoid recursive calling
    _target.call.gas(_suppliedGas).value(_ethValue)(_transactionBytecode);
    underExecution = false;

    emit CallExecutedEvent(_target, _suppliedGas, _ethValue, keccak256(_transactionBytecode));
  }

  function executeDelegatecall(
    address _target,
    uint256 _suppliedGas,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager(&#39;execute_delegatecall&#39;)
  {
    require(underExecution == false);

    underExecution = true; // Avoid recursive calling
    _target.delegatecall.gas(_suppliedGas)(_transactionBytecode);
    underExecution = false;

    emit DelegatecallExecutedEvent(_target, _suppliedGas, keccak256(_transactionBytecode));
  }
}



/**
 * @title AssetIDInterface
 * @dev Interface of a contract that assigned to an asset (JNT, JUSD etc.)
 * @dev Contracts for the same asset (like JNT, JUSD etc.) will have the same AssetID.
 * @dev This will help to avoid misconfiguration of contracts
 */
contract AssetIDInterface {
  function getAssetID() public constant returns (string);
  function getAssetIDHash() public constant returns (bytes32);
}



/**
 * @title AssetID
 * @dev Base contract implementing AssetIDInterface
 */
contract AssetID is AssetIDInterface {

  /* Storage */

  string assetID;


  /* Constructor */

  constructor (string _assetID) public {
    require(bytes(_assetID).length > 0);

    assetID = _assetID;
  }


  /* Getters */

  function getAssetID() public constant returns (string) {
    return assetID;
  }

  function getAssetIDHash() public constant returns (bytes32) {
    return keccak256(assetID);
  }
}



/**
 * @title CrydrLicenseRegistryInterface
 * @dev Interface of the contract that stores licenses
 */
contract CrydrLicenseRegistryInterface {

  /**
   * @dev Function to check licenses of investor
   * @param _userAddress address User`s address
   * @param _licenseName string  License name
   * @return True if investor is admitted and has required license
   */
  function isUserAllowed(address _userAddress, string _licenseName) public constant returns (bool);
}



/**
 * @title CrydrLicenseRegistryManagementInterface
 * @dev Interface of the contract that stores licenses
 */
contract CrydrLicenseRegistryManagementInterface {

  /* Events */

  event UserAdmittedEvent(address indexed useraddress);
  event UserDeniedEvent(address indexed useraddress);
  event UserLicenseGrantedEvent(address indexed useraddress, bytes32 licensename);
  event UserLicenseRenewedEvent(address indexed useraddress, bytes32 licensename);
  event UserLicenseRevokedEvent(address indexed useraddress, bytes32 licensename);


  /* Configuration */

  /**
   * @dev Function to admit user
   * @param _userAddress address User`s address
   */
  function admitUser(address _userAddress) external;

  /**
   * @dev Function to deny user
   * @param _userAddress address User`s address
   */
  function denyUser(address _userAddress) external;

  /**
   * @dev Function to check admittance of an user
   * @param _userAddress address User`s address
   * @return True if investor is in the registry and admitted
   */
  function isUserAdmitted(address _userAddress) public constant returns (bool);


  /**
   * @dev Function to grant license to an user
   * @param _userAddress         address User`s address
   * @param _licenseName         string  name of the license
   */
  function grantUserLicense(address _userAddress, string _licenseName) external;

  /**
   * @dev Function to revoke license from the user
   * @param _userAddress address User`s address
   * @param _licenseName string  name of the license
   */
  function revokeUserLicense(address _userAddress, string _licenseName) external;

  /**
   * @dev Function to check license of an investor
   * @param _userAddress address User`s address
   * @param _licenseName string  License name
   * @return True if investor has been granted needed license
   */
  function isUserGranted(address _userAddress, string _licenseName) public constant returns (bool);
}



/**
 * @title CrydrLicenseRegistry
 * @dev Contract that stores licenses
 */
contract CrydrLicenseRegistry is ManageableInterface,
                                 CrydrLicenseRegistryInterface,
                                 CrydrLicenseRegistryManagementInterface {

  /* Storage */

  mapping (address => bool) userAdmittance;
  mapping (address => mapping (string => bool)) userLicenses;


  /* CrydrLicenseRegistryInterface */

  function isUserAllowed(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userAdmittance[_userAddress] &&
           userLicenses[_userAddress][_licenseName];
  }


  /* CrydrLicenseRegistryManagementInterface */

  function admitUser(
    address _userAddress
  )
    external
    onlyValidAddress(_userAddress)
    onlyAllowedManager(&#39;admit_user&#39;)
  {
    require(userAdmittance[_userAddress] == false);

    userAdmittance[_userAddress] = true;

    emit UserAdmittedEvent(_userAddress);
  }

  function denyUser(
    address _userAddress
  )
    external
    onlyValidAddress(_userAddress)
    onlyAllowedManager(&#39;deny_user&#39;)
  {
    require(userAdmittance[_userAddress] == true);

    userAdmittance[_userAddress] = false;

    emit UserDeniedEvent(_userAddress);
  }

  function isUserAdmitted(
    address _userAddress
  )
    public
    constant
    onlyValidAddress(_userAddress)
    returns (bool)
  {
    return userAdmittance[_userAddress];
  }


  function grantUserLicense(
    address _userAddress, string _licenseName
  )
    external
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    onlyAllowedManager(&#39;grant_license&#39;)
  {
    require(userLicenses[_userAddress][_licenseName] == false);

    userLicenses[_userAddress][_licenseName] = true;

    emit UserLicenseGrantedEvent(_userAddress, keccak256(_licenseName));
  }

  function revokeUserLicense(
    address _userAddress, string _licenseName
  )
    external
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    onlyAllowedManager(&#39;revoke_license&#39;)
  {
    require(userLicenses[_userAddress][_licenseName] == true);

    userLicenses[_userAddress][_licenseName] = false;

    emit UserLicenseRevokedEvent(_userAddress, keccak256(_licenseName));
  }

  function isUserGranted(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userLicenses[_userAddress][_licenseName];
  }

  function isUserLicenseValid(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userLicenses[_userAddress][_licenseName];
  }


  /* Helpers */

  modifier onlyValidAddress(address _userAddress) {
    require(_userAddress != address(0x0));
    _;
  }

  modifier onlyValidLicenseName(string _licenseName) {
    require(bytes(_licenseName).length > 0);
    _;
  }
}



/**
 * @title JCashLicenseRegistry
 * @dev Contract that stores licenses
 */
contract JCashLicenseRegistry is AssetID,
                                 Ownable,
                                 Manageable,
                                 Pausable,
                                 BytecodeExecutor,
                                 CrydrLicenseRegistry {

  /* Constructor */

  constructor (string _assetID) AssetID(_assetID) public { }
}



contract JUSDLicenseRegistry is JCashLicenseRegistry {
  constructor () public JCashLicenseRegistry(&#39;JUSD&#39;) {}
}