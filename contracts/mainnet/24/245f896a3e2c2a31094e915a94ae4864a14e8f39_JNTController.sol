/* Author: Victor Mezrin  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e5938c86918a97a588809f978c8bcb868a88">[email&#160;protected]</a> */

pragma solidity ^0.4.24;


/**
 * @title CommonModifiersInterface
 * @dev Base contract which contains common checks.
 */
contract CommonModifiersInterface {

  /**
   * @dev Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
   */
  function isContract(address _targetAddress) internal constant returns (bool);

  /**
   * @dev modifier to allow actions only when the _targetAddress is a contract.
   */
  modifier onlyContractAddress(address _targetAddress) {
    require(isContract(_targetAddress) == true);
    _;
  }
}


/**
 * @title CommonModifiers
 * @dev Base contract which contains common checks.
 */
contract CommonModifiers is CommonModifiersInterface {

  /**
   * @dev Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
   */
  function isContract(address _targetAddress) internal constant returns (bool) {
    require (_targetAddress != address(0x0));

    uint256 length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_targetAddress)
    }
    return (length > 0);
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


contract CrydrViewBaseInterface {

  /* Events */

  event CrydrControllerChangedEvent(address indexed crydrcontroller);


  /* Configuration */

  function setCrydrController(address _crydrController) external;
  function getCrydrController() public constant returns (address);

  function getCrydrViewStandardName() public constant returns (string);
  function getCrydrViewStandardNameHash() public constant returns (bytes32);
}


/**
 * @title CrydrViewERC20MintableInterface
 * @dev Contract is able to create Mint/Burn events with the cal from controller
 */
contract CrydrViewERC20MintableInterface {
  event MintEvent(address indexed owner, uint256 value);
  event BurnEvent(address indexed owner, uint256 value);

  function emitMintEvent(address _owner, uint256 _value) external;
  function emitBurnEvent(address _owner, uint256 _value) external;
}


/**
 * @title CrydrViewERC20LoggableInterface
 * @dev Contract is able to create Transfer/Approval events with the cal from controller
 */
contract CrydrViewERC20LoggableInterface {

  function emitTransferEvent(address _from, address _to, uint256 _value) external;
  function emitApprovalEvent(address _owner, address _spender, uint256 _value) external;
}


/**
 * @title CrydrStorageBalanceInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageBalanceInterface {

  /* Events */

  event AccountBalanceIncreasedEvent(address indexed account, uint256 value);
  event AccountBalanceDecreasedEvent(address indexed account, uint256 value);


  /* Low-level change of balance. Implied that totalSupply kept in sync. */

  function increaseBalance(address _account, uint256 _value) public;
  function decreaseBalance(address _account, uint256 _value) public;
  function getBalance(address _account) public constant returns (uint256);
  function getTotalSupply() public constant returns (uint256);
}


/**
 * @title CrydrStorageBlocksInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageBlocksInterface {

  /* Events */

  event AccountBlockedEvent(address indexed account);
  event AccountUnblockedEvent(address indexed account);
  event AccountFundsBlockedEvent(address indexed account, uint256 value);
  event AccountFundsUnblockedEvent(address indexed account, uint256 value);


  /* Low-level change of blocks and getters */

  function blockAccount(address _account) public;
  function unblockAccount(address _account) public;
  function getAccountBlocks(address _account) public constant returns (uint256);

  function blockAccountFunds(address _account, uint256 _value) public;
  function unblockAccountFunds(address _account, uint256 _value) public;
  function getAccountBlockedFunds(address _account) public constant returns (uint256);
}


/**
 * @title CrydrStorageAllowanceInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageAllowanceInterface {

  /* Events */

  event AccountAllowanceIncreasedEvent(address indexed owner, address indexed spender, uint256 value);
  event AccountAllowanceDecreasedEvent(address indexed owner, address indexed spender, uint256 value);


  /* Low-level change of allowance */

  function increaseAllowance(address _owner, address _spender, uint256 _value) public;
  function decreaseAllowance(address _owner, address _spender, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}


/**
 * @title CrydrStorageERC20Interface interface
 * @dev Interface of a contract that manages balance of an CryDR and have optimization for ERC20 controllers
 */
contract CrydrStorageERC20Interface {

  /* Events */

  event CrydrTransferredEvent(address indexed from, address indexed to, uint256 value);
  event CrydrTransferredFromEvent(address indexed spender, address indexed from, address indexed to, uint256 value);
  event CrydrSpendingApprovedEvent(address indexed owner, address indexed spender, uint256 value);


  /* ERC20 optimization. _msgsender - account that invoked CrydrView */

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function approve(address _msgsender, address _spender, uint256 _value) public;
}



/**
 * @title CrydrControllerBaseInterface interface
 * @dev Interface of a contract that implement business-logic of an CryDR, mediates CryDR views and storage
 */
contract CrydrControllerBaseInterface {

  /* Events */

  event CrydrStorageChangedEvent(address indexed crydrstorage);
  event CrydrViewAddedEvent(address indexed crydrview, bytes32 standardname);
  event CrydrViewRemovedEvent(address indexed crydrview, bytes32 standardname);


  /* Configuration */

  function setCrydrStorage(address _newStorage) external;
  function getCrydrStorageAddress() public constant returns (address);

  function setCrydrView(address _newCrydrView, string _viewApiStandardName) external;
  function removeCrydrView(string _viewApiStandardName) external;
  function getCrydrViewAddress(string _viewApiStandardName) public constant returns (address);

  function isCrydrViewAddress(address _crydrViewAddress) public constant returns (bool);
  function isCrydrViewRegistered(string _viewApiStandardName) public constant returns (bool);


  /* Helpers */

  modifier onlyValidCrydrViewStandardName(string _viewApiStandard) {
    require(bytes(_viewApiStandard).length > 0);
    _;
  }

  modifier onlyCrydrView() {
    require(isCrydrViewAddress(msg.sender) == true);
    _;
  }
}


/**
 * @title CrydrControllerBase
 * @dev Implementation of a contract with business-logic of an CryDR, mediates CryDR views and storage
 */
contract CrydrControllerBase is CommonModifiersInterface,
                                ManageableInterface,
                                PausableInterface,
                                CrydrControllerBaseInterface {

  /* Storage */

  address crydrStorage = address(0x0);
  mapping (string => address) crydrViewsAddresses;
  mapping (address => bool) isRegisteredView;


  /* CrydrControllerBaseInterface */

  function setCrydrStorage(
    address _crydrStorage
  )
    external
    onlyContractAddress(_crydrStorage)
    onlyAllowedManager(&#39;set_crydr_storage&#39;)
    whenContractPaused
  {
    require(_crydrStorage != address(this));
    require(_crydrStorage != address(crydrStorage));

    crydrStorage = _crydrStorage;

    emit CrydrStorageChangedEvent(_crydrStorage);
  }

  function getCrydrStorageAddress() public constant returns (address) {
    return address(crydrStorage);
  }


  function setCrydrView(
    address _newCrydrView, string _viewApiStandardName
  )
    external
    onlyContractAddress(_newCrydrView)
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    onlyAllowedManager(&#39;set_crydr_view&#39;)
    whenContractPaused
  {
    require(_newCrydrView != address(this));
    require(crydrViewsAddresses[_viewApiStandardName] == address(0x0));

    CrydrViewBaseInterface crydrViewInstance = CrydrViewBaseInterface(_newCrydrView);
    bytes32 standardNameHash = crydrViewInstance.getCrydrViewStandardNameHash();
    require(standardNameHash == keccak256(_viewApiStandardName));

    crydrViewsAddresses[_viewApiStandardName] = _newCrydrView;
    isRegisteredView[_newCrydrView] = true;

    emit CrydrViewAddedEvent(_newCrydrView, keccak256(_viewApiStandardName));
  }

  function removeCrydrView(
    string _viewApiStandardName
  )
    external
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    onlyAllowedManager(&#39;remove_crydr_view&#39;)
    whenContractPaused
  {
    require(crydrViewsAddresses[_viewApiStandardName] != address(0x0));

    address removedView = crydrViewsAddresses[_viewApiStandardName];

    // make changes to the storage
    crydrViewsAddresses[_viewApiStandardName] == address(0x0);
    isRegisteredView[removedView] = false;

    emit CrydrViewRemovedEvent(removedView, keccak256(_viewApiStandardName));
  }

  function getCrydrViewAddress(
    string _viewApiStandardName
  )
    public
    constant
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    returns (address)
  {
    require(crydrViewsAddresses[_viewApiStandardName] != address(0x0));

    return crydrViewsAddresses[_viewApiStandardName];
  }

  function isCrydrViewAddress(
    address _crydrViewAddress
  )
    public
    constant
    returns (bool)
  {
    require(_crydrViewAddress != address(0x0));

    return isRegisteredView[_crydrViewAddress];
  }

  function isCrydrViewRegistered(
    string _viewApiStandardName
  )
    public
    constant
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    returns (bool)
  {
    return (crydrViewsAddresses[_viewApiStandardName] != address(0x0));
  }
}


/**
 * @title CrydrControllerBlockableInterface interface
 * @dev Interface of a contract that allows block/unlock accounts
 */
contract CrydrControllerBlockableInterface {

  /* blocking/unlocking */

  function blockAccount(address _account) public;
  function unblockAccount(address _account) public;

  function blockAccountFunds(address _account, uint256 _value) public;
  function unblockAccountFunds(address _account, uint256 _value) public;
}


/**
 * @title CrydrControllerBlockable interface
 * @dev Implementation of a contract that allows blocking/unlocking accounts
 */
contract CrydrControllerBlockable is ManageableInterface,
                                     CrydrControllerBaseInterface,
                                     CrydrControllerBlockableInterface {


  /* blocking/unlocking */

  function blockAccount(
    address _account
  )
    public
    onlyAllowedManager(&#39;block_account&#39;)
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).blockAccount(_account);
  }

  function unblockAccount(
    address _account
  )
    public
    onlyAllowedManager(&#39;unblock_account&#39;)
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).unblockAccount(_account);
  }

  function blockAccountFunds(
    address _account,
    uint256 _value
  )
    public
    onlyAllowedManager(&#39;block_account_funds&#39;)
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).blockAccountFunds(_account, _value);
  }

  function unblockAccountFunds(
    address _account,
    uint256 _value
  )
    public
    onlyAllowedManager(&#39;unblock_account_funds&#39;)
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).unblockAccountFunds(_account, _value);
  }
}


/**
 * @title CrydrControllerMintableInterface interface
 * @dev Interface of a contract that allows minting/burning of tokens
 */
contract CrydrControllerMintableInterface {

  /* Events */

  event MintEvent(address indexed owner, uint256 value);
  event BurnEvent(address indexed owner, uint256 value);

  /* minting/burning */

  function mint(address _account, uint256 _value) public;
  function burn(address _account, uint256 _value) public;
}


/**
 * @title CrydrControllerMintable interface
 * @dev Implementation of a contract that allows minting/burning of tokens
 * @dev We do not use events Transfer(0x0, owner, amount) for minting as described in the EIP20
 * @dev because that are not transfers
 */
contract CrydrControllerMintable is ManageableInterface,
                                    PausableInterface,
                                    CrydrControllerBaseInterface,
                                    CrydrControllerMintableInterface {

  /* minting/burning */

  function mint(
    address _account, uint256 _value
  )
    public
    whenContractNotPaused
    onlyAllowedManager(&#39;mint_crydr&#39;)
  {
    // input parameters checked by the storage

    CrydrStorageBalanceInterface(getCrydrStorageAddress()).increaseBalance(_account, _value);

    emit MintEvent(_account, _value);
    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20MintableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitMintEvent(_account, _value);
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(address(0x0), _account, _value);
    }
  }

  function burn(
    address _account, uint256 _value
  )
    public
    whenContractNotPaused
    onlyAllowedManager(&#39;burn_crydr&#39;)
  {
    // input parameters checked by the storage

    CrydrStorageBalanceInterface(getCrydrStorageAddress()).decreaseBalance(_account, _value);

    emit BurnEvent(_account, _value);
    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20MintableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitBurnEvent(_account, _value);
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_account, address(0x0), _value);
    }
  }
}


/**
 * @title CrydrControllerERC20Interface interface
 * @dev Interface of a contract that implement business-logic of an ERC20 CryDR
 */
contract CrydrControllerERC20Interface {

  /* ERC20 support. _msgsender - account that invoked CrydrView */

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function getTotalSupply() public constant returns (uint256);
  function getBalance(address _owner) public constant returns (uint256);

  function approve(address _msgsender, address _spender, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}


/**
 * @title CrydrControllerERC20Interface interface
 * @dev Interface of a contract that implement business-logic of an ERC20 CryDR
 */
contract CrydrControllerERC20 is PausableInterface,
                                 CrydrControllerBaseInterface,
                                 CrydrControllerERC20Interface {

  /* ERC20 support. _msgsender - account that invoked CrydrView */

  function transfer(
    address _msgsender,
    address _to,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
    CrydrStorageERC20Interface(getCrydrStorageAddress()).transfer(_msgsender, _to, _value);

    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_msgsender, _to, _value);
    }
  }

  function getTotalSupply() public constant returns (uint256) {
    return CrydrStorageBalanceInterface(getCrydrStorageAddress()).getTotalSupply();
  }

  function getBalance(address _owner) public constant returns (uint256) {
    return CrydrStorageBalanceInterface(getCrydrStorageAddress()).getBalance(_owner);
  }

  function approve(
    address _msgsender,
    address _spender,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    // We decided to enforce users to set 0 before set new value
    uint256 allowance = CrydrStorageAllowanceInterface(getCrydrStorageAddress()).getAllowance(_msgsender, _spender);
    require((allowance > 0 && _value == 0) || (allowance == 0 && _value > 0));

    CrydrStorageERC20Interface(getCrydrStorageAddress()).approve(_msgsender, _spender, _value);

    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitApprovalEvent(_msgsender, _spender, _value);
    }
  }

  function transferFrom(
    address _msgsender,
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
    CrydrStorageERC20Interface(getCrydrStorageAddress()).transferFrom(_msgsender, _from, _to, _value);

    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_from, _to, _value);
    }
  }

  function getAllowance(address _owner, address _spender) public constant returns (uint256 ) {
    return CrydrStorageAllowanceInterface(getCrydrStorageAddress()).getAllowance(_owner, _spender);
  }
}


/**
 * @title CrydrControllerForcedTransferInterface interface
 * @dev Interface of a contract that allows manager to transfer funds from one account to another
 */
contract CrydrControllerForcedTransferInterface {

  /* Events */

  event ForcedTransferEvent(address indexed from, address indexed to, uint256 value);


  /* Methods */

  function forcedTransfer(address _from, address _to, uint256 _value) public;
  function forcedTransferAll(address _from, address _to) public;

}


/**
 * @title CrydrControllerForcedTransfer
 * @dev Implementation of a contract that allows manager to transfer funds from one account to another
 */
contract CrydrControllerForcedTransfer is ManageableInterface,
                                          PausableInterface,
                                          CrydrControllerBaseInterface,
                                          CrydrControllerForcedTransferInterface {

  /* minting/burning */

  function forcedTransfer(
    address _from, address _to, uint256 _value
  )
    public
    whenContractNotPaused
    onlyAllowedManager(&#39;forced_transfer&#39;)
  {
    // input parameters checked by the storage

    CrydrStorageBalanceInterface(getCrydrStorageAddress()).decreaseBalance(_from, _value);
    CrydrStorageBalanceInterface(getCrydrStorageAddress()).increaseBalance(_to, _value);

    emit ForcedTransferEvent(_from, _to, _value);
    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_from, _to, _value);
    }
  }

  function forcedTransferAll(
    address _from, address _to
  )
    public
    whenContractNotPaused
    onlyAllowedManager(&#39;forced_transfer&#39;)
  {
    // input parameters checked by the storage

    uint256 value = CrydrStorageBalanceInterface(getCrydrStorageAddress()).getBalance(_from);
    CrydrStorageBalanceInterface(getCrydrStorageAddress()).decreaseBalance(_from, value);
    CrydrStorageBalanceInterface(getCrydrStorageAddress()).increaseBalance(_to, value);

    emit ForcedTransferEvent(_from, _to, value);
    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_from, _to, value);
    }
  }
}


/**
 * @title JNTPaymentGatewayInterface
 * @dev Allows to charge users by JNT
 */
contract JNTPaymentGatewayInterface {

  /* Events */

  event JNTChargedEvent(address indexed payableservice, address indexed from, address indexed to, uint256 value);


  /* Actions */

  function chargeJNT(address _from, address _to, uint256 _value) public;
}


/**
 * @title JNTPaymentGateway
 * @dev Allows to charge users by JNT
 */
contract JNTPaymentGateway is ManageableInterface,
                              CrydrControllerBaseInterface,
                              JNTPaymentGatewayInterface {

  function chargeJNT(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyAllowedManager(&#39;jnt_payable_service&#39;)
  {
    CrydrStorageERC20Interface(getCrydrStorageAddress()).transfer(_from, _to, _value);

    emit JNTChargedEvent(msg.sender, _from, _to, _value);
    if (isCrydrViewRegistered(&#39;erc20&#39;) == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress(&#39;erc20&#39;)).emitTransferEvent(_from, _to, _value);
    }
  }
}


/**
 * @title JNTController
 * @dev Mediates views and storage of JNT, provides additional methods for Jibrel contracts
 */
contract JNTController is CommonModifiers,
                          AssetID,
                          Ownable,
                          Manageable,
                          Pausable,
                          BytecodeExecutor,
                          CrydrControllerBase,
                          CrydrControllerBlockable,
                          CrydrControllerMintable,
                          CrydrControllerERC20,
                          CrydrControllerForcedTransfer,
                          JNTPaymentGateway {

  /* Constructor */

  constructor () AssetID(&#39;JNT&#39;) public {}
}