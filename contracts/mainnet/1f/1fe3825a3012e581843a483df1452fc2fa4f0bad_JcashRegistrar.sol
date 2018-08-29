/* Author: Aleksey Selikhov  <span class="__cf_email__" data-cfemail="03626f666870667a2d70666f6a686b6c7543646e626a6f2d606c6e">[email&#160;protected]</span> */

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
 * @title CrydrViewERC20Interface
 * @dev ERC20 interface to use in applications
 */
contract CrydrViewERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address _to, uint256 _value) external returns (bool);
  function totalSupply() external constant returns (uint256);
  function balanceOf(address _owner) external constant returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint256);
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
 * @title JNTPayableService interface
 * @dev Interface of a contract that charge JNT for actions
 */
contract JNTPayableServiceInterface {

  /* Events */

  event JNTControllerChangedEvent(address jntcontroller);
  event JNTBeneficiaryChangedEvent(address jntbeneficiary);
  event JNTChargedEvent(address indexed payer, address indexed to, uint256 value, bytes32 actionname);


  /* Configuration */

  function setJntController(address _jntController) external;
  function getJntController() public constant returns (address);

  function setJntBeneficiary(address _jntBeneficiary) external;
  function getJntBeneficiary() public constant returns (address);

  function setActionPrice(string _actionName, uint256 _jntPriceWei) external;
  function getActionPrice(string _actionName) public constant returns (uint256);


  /* Actions */

  function initChargeJNT(address _payer, string _actionName) internal;
}


contract JNTPayableService is CommonModifiersInterface,
                              ManageableInterface,
                              PausableInterface,
                              JNTPayableServiceInterface {

  /* Storage */

  JNTPaymentGateway jntController;
  address jntBeneficiary;
  mapping (string => uint256) actionPrice;


  /* Configuration */

  function setJntController(
    address _jntController
  )
    external
    onlyContractAddress(_jntController)
    onlyAllowedManager(&#39;set_jnt_controller&#39;)
    whenContractPaused
  {
    require(_jntController != address(jntController));

    jntController = JNTPaymentGateway(_jntController);

    emit JNTControllerChangedEvent(_jntController);
  }

  function getJntController() public constant returns (address) {
    return address(jntController);
  }


  function setJntBeneficiary(
    address _jntBeneficiary
  )
    external
    onlyValidJntBeneficiary(_jntBeneficiary)
    onlyAllowedManager(&#39;set_jnt_beneficiary&#39;)
    whenContractPaused
  {
    require(_jntBeneficiary != jntBeneficiary);
    require(_jntBeneficiary != address(this));

    jntBeneficiary = _jntBeneficiary;

    emit JNTBeneficiaryChangedEvent(jntBeneficiary);
  }

  function getJntBeneficiary() public constant returns (address) {
    return jntBeneficiary;
  }


  function setActionPrice(
    string _actionName,
    uint256 _jntPriceWei
  )
    external
    onlyAllowedManager(&#39;set_action_price&#39;)
    onlyValidActionName(_actionName)
    whenContractPaused
  {
    require (_jntPriceWei > 0);

    actionPrice[_actionName] = _jntPriceWei;
  }

  function getActionPrice(
    string _actionName
  )
    public
    constant
    onlyValidActionName(_actionName)
    returns (uint256)
  {
    return actionPrice[_actionName];
  }


  /* Actions */

  function initChargeJNT(
    address _from,
    string _actionName
  )
    internal
    onlyValidActionName(_actionName)
    whenContractNotPaused
  {
    require(_from != address(0x0));
    require(_from != jntBeneficiary);

    uint256 _actionPrice = getActionPrice(_actionName);
    require (_actionPrice > 0);

    jntController.chargeJNT(_from, jntBeneficiary, _actionPrice);

    emit JNTChargedEvent(_from, jntBeneficiary, _actionPrice, keccak256(_actionName));
  }


  /* Pausable */

  /**
   * @dev Override method to ensure that contract properly configured before it is unpaused
   */
  function unpauseContract()
    public
    onlyContractAddress(jntController)
    onlyValidJntBeneficiary(jntBeneficiary)
  {
    super.unpauseContract();
  }


  /* Modifiers */

  modifier onlyValidJntBeneficiary(address _jntBeneficiary) {
    require(_jntBeneficiary != address(0x0));
    _;
  }

  /**
   * @dev Modifier to check name of manager permission
   */
  modifier onlyValidActionName(string _actionName) {
    require(bytes(_actionName).length != 0);
    _;
  }
}


/**
 * @title JcashRegistrarInterface
 * @dev Interface of a contract that can receives ETH&ERC20, refunds ETH&ERC20 and logs these operations
 */
contract JcashRegistrarInterface {

  /* Events */

  event ReceiveEthEvent(address indexed from, uint256 value);
  event RefundEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event TransferEthEvent(bytes32 txhash, address indexed to, uint256 value);

  event RefundTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);
  event TransferTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);

  event ReplenishEthEvent(address indexed from, uint256 value);
  event WithdrawEthEvent(address indexed to, uint256 value);
  event WithdrawTokenEvent(address indexed tokenaddress, address indexed to, uint256 value);

  event PauseEvent();
  event UnpauseEvent();


  /* Replenisher actions */

  /**
   * @dev Allows to withdraw ETH by Replenisher.
   */
  function withdrawEth(uint256 _weivalue) external;

  /**
   * @dev Allows to withdraw tokens by Replenisher.
   */
  function withdrawToken(address _tokenAddress, uint256 _weivalue) external;


  /* Processing of exchange operations */

  /**
   * @dev Allows to perform refund ETH.
   */
  function refundEth(bytes32 _txHash, address _to, uint256 _weivalue) external;

  /**
   * @dev Allows to perform refund ERC20 tokens.
   */
  function refundToken(bytes32 _txHash, address _tokenAddress, address _to, uint256 _weivalue) external;

  /**
   * @dev Allows to perform transfer ETH.
   *
   */
  function transferEth(bytes32 _txHash, address _to, uint256 _weivalue) external;

  /**
   * @dev Allows to perform transfer ERC20 tokens.
   */
  function transferToken(bytes32 _txHash, address _tokenAddress, address _to, uint256 _weivalue) external;


  /* Getters */

  /**
   * @dev The getter returns true if tx hash is processed
   */
  function isProcessedTx(bytes32 _txHash) public view returns (bool);
}


/**
 * @title JcashRegistrar
 * @dev Implementation of a contract that can receives ETH&ERC20, refunds ETH&ERC20 and logs these operations
 */
contract JcashRegistrar is CommonModifiers,
                           Ownable,
                           Manageable,
                           Pausable,
                           JNTPayableService,
                           JcashRegistrarInterface {

  /* Storage */

  mapping (bytes32 => bool) processedTxs;


  /* Events */

  event ReceiveEthEvent(address indexed from, uint256 value);
  event RefundEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event TransferEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event RefundTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);
  event TransferTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);

  event ReplenishEthEvent(address indexed from, uint256 value);
  event WithdrawEthEvent(address indexed to, uint256 value);
  event WithdrawTokenEvent(address indexed tokenaddress, address indexed to, uint256 value);

  event PauseEvent();
  event UnpauseEvent();


  /* Modifiers */

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length == (size + 4));

    _;
  }

  /**
   * @dev Fallback function allowing the contract to receive funds, if contract haven&#39;t already been paused.
   */
  function () external payable {
    if (isManagerAllowed(msg.sender, &#39;replenish_eth&#39;)==true) {
      emit ReplenishEthEvent(msg.sender, msg.value);
    } else {
      require (getPaused() == false);
      emit ReceiveEthEvent(msg.sender, msg.value);
    }
  }


  /* Replenisher actions */

  /**
   * @dev Allows to withdraw ETH by Replenisher.
   */
  function withdrawEth(
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;replenish_eth&#39;)
    onlyPayloadSize(1 * 32)
  {
    require (_weivalue > 0);

    address(msg.sender).transfer(_weivalue);
    emit WithdrawEthEvent(msg.sender, _weivalue);
  }

  /**
   * @dev Allows to withdraw tokens by Replenisher.
   */
  function withdrawToken(
    address _tokenAddress,
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;replenish_token&#39;)
    onlyPayloadSize(2 * 32)
  {
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_weivalue > 0);

    CrydrViewERC20Interface(_tokenAddress).transfer(msg.sender, _weivalue);
    emit WithdrawTokenEvent(_tokenAddress, msg.sender, _weivalue);
  }


  /* Processing of exchange operations */

  /**
   * @dev Allows to perform refund ETH.
   */
  function refundEth(
    bytes32 _txHash,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;refund_eth&#39;)
    whenContractNotPaused
    onlyPayloadSize(3 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    _to.transfer(_weivalue);

    emit RefundEthEvent(_txHash, _to, _weivalue);
  }

  /**
   * @dev Allows to perform refund ERC20 tokens.
   */
  function refundToken(
    bytes32 _txHash,
    address _tokenAddress,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;refund_token&#39;)
    whenContractNotPaused
    onlyPayloadSize(4 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    CrydrViewERC20Interface(_tokenAddress).transfer(_to, _weivalue);

    emit RefundTokenEvent(_txHash, _tokenAddress, _to, _weivalue);
  }

  /**
   * @dev Allows to perform transfer ETH.
   *
   */
  function transferEth(
    bytes32 _txHash,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;transfer_eth&#39;)
    whenContractNotPaused
    onlyPayloadSize(3 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    _to.transfer(_weivalue);

    if (getActionPrice(&#39;transfer_eth&#39;) > 0) {
      initChargeJNT(_to, &#39;transfer_eth&#39;);
    }

    emit TransferEthEvent(_txHash, _to, _weivalue);
  }

  /**
   * @dev Allows to perform transfer ERC20 tokens.
   */
  function transferToken(
    bytes32 _txHash,
    address _tokenAddress,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager(&#39;transfer_token&#39;)
    whenContractNotPaused
    onlyPayloadSize(4 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_to != address(0x0));
    require (_to != address(this));

    processedTxs[_txHash] = true;
    CrydrViewERC20Interface(_tokenAddress).transfer(_to, _weivalue);

    if (getActionPrice(&#39;transfer_token&#39;) > 0) {
      initChargeJNT(_to, &#39;transfer_token&#39;);
    }

    emit TransferTokenEvent(_txHash, _tokenAddress, _to, _weivalue);
  }


  /* Getters */

  /**
   * @dev The getter returns true if tx hash is processed
   */
  function isProcessedTx(
    bytes32 _txHash
  )
    public
    view
    onlyPayloadSize(1 * 32)
    returns (bool)
  {
    require (_txHash != bytes32(0));
    return processedTxs[_txHash];
  }
}