pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns (address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */



contract ERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(bytes32 => bool) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/) // Comments to avoid compilation warnings for unused variables.
    external
    view
    returns(bytes32)
  {
    if(_interfaceHashes[interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _setInterface(string memory interfaceLabel) internal {
    _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title IERC1400 security token standard
 * @dev See https://github.com/SecurityTokenStandard/EIP-Spec/blob/master/eip/eip-1400.md
 */
interface IERC1400 /*is IERC20*/ { // Interfaces can currently not inherit interfaces, but IERC1400 shall include IERC20

  // ****************** Document Management *******************
  function getDocument(bytes32 name) external view returns (string memory, bytes32);
  function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external;

  // ******************* Token Information ********************
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256);
  function partitionsOf(address tokenHolder) external view returns (bytes32[] memory);

  // *********************** Transfers ************************
  function transferWithData(address to, uint256 value, bytes calldata data) external;
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external;

  // *************** Partition Token Transfers ****************
  function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external returns (bytes32);
  function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32);

  // ****************** Controller Operation ******************
  function isControllable() external view returns (bool);
  // function controllerTransfer(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorTransferByPartition"
  // function controllerRedeem(address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorRedeemByPartition"

  // ****************** Operator Management *******************
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function authorizeOperatorByPartition(bytes32 partition, address operator) external;
  function revokeOperatorByPartition(bytes32 partition, address operator) external;

  // ****************** Operator Information ******************
  function isOperator(address operator, address tokenHolder) external view returns (bool);
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool);

  // ********************* Token Issuance *********************
  function isIssuable() external view returns (bool);
  function issue(address tokenHolder, uint256 value, bytes calldata data) external;
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external;

  // ******************** Token Redemption ********************
  function redeem(uint256 value, bytes calldata data) external;
  function redeemFrom(address tokenHolder, uint256 value, bytes calldata data) external;
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external;
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData) external;

  // ******************* Transfer Validity ********************
  // We use different transfer validity functions because those described in the interface don't allow to verify the certificate's validity.
  // Indeed, verifying the ecrtificate's validity requires to keeps the function's arguments in the exact same order as the transfer function.
  //
  // function canTransfer(address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferFrom(address from, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferByPartition(address from, address to, bytes32 partition, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32);    

  // ******************* Controller Events ********************
  // We don't use this event as we don't use "controllerTransfer"
  //   event ControllerTransfer(
  //       address controller,
  //       address indexed from,
  //       address indexed to,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );
  //
  // We don't use this event as we don't use "controllerRedeem"
  //   event ControllerRedemption(
  //       address controller,
  //       address indexed tokenHolder,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );

  // ******************** Document Events *********************
  event Document(bytes32 indexed name, string uri, bytes32 documentHash);

  // ******************** Transfer Events *********************
  event TransferByPartition(
      bytes32 indexed fromPartition,
      address operator,
      address indexed from,
      address indexed to,
      uint256 value,
      bytes data,
      bytes operatorData
  );

  event ChangedPartition(
      bytes32 indexed fromPartition,
      bytes32 indexed toPartition,
      uint256 value
  );

  // ******************** Operator Events *********************
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
  event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
  event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

  // ************** Issuance / Redemption Events **************
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
  event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes operatorData);

}

/**
 * Reason codes - ERC-1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the ERC-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 * 
 * Code	Reason
 * 0x50	transfer failure
 * 0x51	transfer success
 * 0x52	insufficient balance
 * 0x53	insufficient allowance
 * 0x54	transfers halted (contract paused)
 * 0x55	funds locked (lockup period)
 * 0x56	invalid sender
 * 0x57	invalid receiver
 * 0x58	invalid operator (transfer agent)
 * 0x59	
 * 0x5a	
 * 0x5b	
 * 0x5a	
 * 0x5b	
 * 0x5c	
 * 0x5d	
 * 0x5e	
 * 0x5f	token meta or info
 *
 * These codes are being discussed at: https://ethereum-magicians.org/t/erc-1066-ethereum-status-codes-esc/283/24
 */

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title IERC1400TokensValidator
 * @dev ERC1400TokensValidator interface
 */
interface IERC1400TokensValidator {

  function canValidate(
    address token,
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensToValidate(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title IERC1400TokensChecker
 * @dev IERC1400TokensChecker interface
 */
interface IERC1400TokensChecker {

  // function canTransfer(
  //   bytes4 functionSig,
  //   address operator,
  //   address from,
  //   address to,
  //   uint256 value,
  //   bytes calldata data,
  //   bytes calldata operatorData
  // ) external view returns (byte, bytes32);

  function canTransferByPartition(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes calldata data,
    bytes calldata operatorData
    ) external view returns (byte, bytes32, bytes32);

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title IERC1400TokensSender
 * @dev ERC1400TokensSender interface
 */
interface IERC1400TokensSender {

  function canTransfer(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensToTransfer(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title IERC1400TokensRecipient
 * @dev ERC1400TokensRecipient interface
 */
interface IERC1400TokensRecipient {

  function canReceive(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensReceived(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */












// Extensions (hooks triggered by the contract)






/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400 is IERC20, IERC1400, Ownable, ERC1820Client, ERC1820Implementer, MinterRole {
  using SafeMath for uint256;

  // Token
  string constant internal ERC1400_INTERFACE_NAME = "ERC1400Token";
  string constant internal ERC20_INTERFACE_NAME = "ERC20Token";

  // Token extensions (hooks triggered by the contract)
  string constant internal ERC1400_TOKENS_CHECKER = "ERC1400TokensChecker";
  string constant internal ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";

  // User extensions (hooks triggered by the contract)
  string constant internal ERC1400_TOKENS_SENDER = "ERC1400TokensSender";
  string constant internal ERC1400_TOKENS_RECIPIENT = "ERC1400TokensRecipient";

  /************************************* Token description ****************************************/
  string internal _name;
  string internal _symbol;
  uint256 internal _granularity;
  uint256 internal _totalSupply;
  bool internal _migrated;
  /************************************************************************************************/


  /**************************************** Token behaviours **************************************/
  // Indicate whether the token can still be controlled by operators or not anymore.
  bool internal _isControllable;

  // Indicate whether the token can still be issued by the issuer or not anymore.
  bool internal _isIssuable;
  /************************************************************************************************/


  /********************************** ERC20 Token mappings ****************************************/
  // Mapping from tokenHolder to balance.
  mapping(address => uint256) internal _balances;

  // Mapping from (tokenHolder, spender) to allowed value.
  mapping (address => mapping (address => uint256)) internal _allowed;
  /************************************************************************************************/


  /**************************************** Documents *********************************************/
  struct Doc {
    string docURI;
    bytes32 docHash;
  }
  // Mapping for token URIs.
  mapping(bytes32 => Doc) internal _documents;
  /************************************************************************************************/


  /*********************************** Partitions  mappings ***************************************/
  // List of partitions.
  bytes32[] internal _totalPartitions;

  // Mapping from partition to their index.
  mapping (bytes32 => uint256) internal _indexOfTotalPartitions;

  // Mapping from partition to global balance of corresponding partition.
  mapping (bytes32 => uint256) internal _totalSupplyByPartition;

  // Mapping from tokenHolder to their partitions.
  mapping (address => bytes32[]) internal _partitionsOf;

  // Mapping from (tokenHolder, partition) to their index.
  mapping (address => mapping (bytes32 => uint256)) internal _indexOfPartitionsOf;

  // Mapping from (tokenHolder, partition) to balance of corresponding partition.
  mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByPartition;

  // List of token default partitions (for ERC20 compatibility).
  bytes32[] internal _defaultPartitions;
  /************************************************************************************************/


  /********************************* Global operators mappings ************************************/
  // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
  mapping(address => mapping(address => bool)) internal _authorizedOperator;

  // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  address[] internal _controllers;

  // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  mapping(address => bool) internal _isController;
  /************************************************************************************************/


  /******************************** Partition operators mappings **********************************/
  // Mapping from (partition, tokenHolder, spender) to allowed value. [TOKEN-HOLDER-SPECIFIC]
  mapping(bytes32 => mapping (address => mapping (address => uint256))) internal _allowedByPartition;

  // Mapping from (tokenHolder, partition, operator) to 'approved for partition' status. [TOKEN-HOLDER-SPECIFIC]
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;

  // Mapping from partition to controllers for the partition. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => address[]) internal _controllersByPartition;

  // Mapping from (partition, operator) to PartitionController status. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;
  /************************************************************************************************/


  /***************************************** Modifiers ********************************************/
  /**
   * @dev Modifier to verify if token is issuable.
   */
  modifier isIssuableToken() {
    require(_isIssuable, "55"); // 0x55	funds locked (lockup period)
    _;
  }
  /**
   * @dev Modifier to make a function callable only when the contract is not migrated.
   */
  modifier isNotMigratedToken() {
      require(!_migrated, "54"); // 0x54	transfers halted (contract paused)
      _;
  }
  /************************************************************************************************/


  /**************************** Events (additional - not mandatory) *******************************/
  event ApprovalByPartition(bytes32 indexed partition, address indexed owner, address indexed spender, uint256 value);
  /************************************************************************************************/


  /**
   * @dev Initialize ERC1400 + register the contract implementation in ERC1820Registry.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param defaultPartitions Partitions chosen by default, when partition is
   * not specified, like the case ERC20 tranfers.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    bytes32[] memory defaultPartitions
  )
    public
  {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1); // Constructor Blocked - Token granularity can not be lower than 1
    _granularity = granularity;

    _setControllers(controllers);

    _defaultPartitions = defaultPartitions;

    _isControllable = true;
    _isIssuable = true;

    // Register contract in ERC1820 registry
    ERC1820Client.setInterfaceImplementation(ERC1400_INTERFACE_NAME, address(this));
    ERC1820Client.setInterfaceImplementation(ERC20_INTERFACE_NAME, address(this));

    // Indicate token verifies ERC1400 and ERC20 interfaces
    ERC1820Implementer._setInterface(ERC1400_INTERFACE_NAME); // For migration
    ERC1820Implementer._setInterface(ERC20_INTERFACE_NAME); // For migration
  }


  /************************************************************************************************/
  /****************************** EXTERNAL FUNCTIONS (ERC20 INTERFACE) ****************************/
  /************************************************************************************************/


  /**
   * @dev Get the total number of issued tokens.
   * @return Total supply of tokens currently in circulation.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }
  /**
   * @dev Get the balance of the account with address 'tokenHolder'.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token held by 'tokenHolder' in the token contract.
   */
  function balanceOf(address tokenHolder) external view returns (uint256) {
    return _balances[tokenHolder];
  }
  /**
   * @dev Transfer token for a specified address.
   * @param to The address to transfer to.
   * @param value The value to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transfer(address to, uint256 value) external returns (bool) {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, "");
    return true;
  }
  /**
   * @dev Check the value of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the value of tokens still available for the spender.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowed[owner][spender];
  }
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @return A boolean that indicates if the operation was successful.
   */
  function approve(address spender, uint256 value) external returns (bool) {
    require(spender != address(0), "56"); // 0x56	invalid sender
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  /**
   * @dev Transfer tokens from one address to another.
   * @param from The address which you want to transfer tokens from.
   * @param to The address which you want to transfer to.
   * @param value The amount of tokens to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    require( _isOperator(msg.sender, from)
      || (value <= _allowed[from][msg.sender]), "53"); // 0x53	insufficient allowance

    if(_allowed[from][msg.sender] >= value) {
      _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    } else {
      _allowed[from][msg.sender] = 0;
    }

    _transferByDefaultPartitions(msg.sender, from, to, value, "");
    return true;
  }


  /************************************************************************************************/
  /****************************** EXTERNAL FUNCTIONS (ERC1400 INTERFACE) **************************/
  /************************************************************************************************/


  /************************************* Document Management **************************************/
  /**
   * @dev Access a document associated with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @return Requested document + document hash.
   */
  function getDocument(bytes32 name) external view returns (string memory, bytes32) {
    require(bytes(_documents[name].docURI).length != 0); // Action Blocked - Empty document
    return (
      _documents[name].docURI,
      _documents[name].docHash
    );
  }
  /**
   * @dev Associate a document with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @param uri Document content.
   * @param documentHash Hash of the document [optional parameter].
   */
  function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external {
    require(_isController[msg.sender]);
    _documents[name] = Doc({
      docURI: uri,
      docHash: documentHash
    });
    emit Document(name, uri, documentHash);
  }
  /************************************************************************************************/


  /************************************** Token Information ***************************************/
  /**
   * @dev Get balance of a tokenholder for a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
   */
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256) {
    return _balanceOfByPartition[tokenHolder][partition];
  }
  /**
   * @dev Get partitions index of a tokenholder.
   * @param tokenHolder Address for which the partitions index are returned.
   * @return Array of partitions index of 'tokenHolder'.
   */
  function partitionsOf(address tokenHolder) external view returns (bytes32[] memory) {
    return _partitionsOf[tokenHolder];
  }
  /************************************************************************************************/


  /****************************************** Transfers *******************************************/
  /**
   * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder.
   */
  function transferWithData(address to, uint256 value, bytes calldata data) external {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, data);
  }
  /**
   * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
   * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder ('from').
   */
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external {
    require(_isOperator(msg.sender, from), "58"); // 0x58	invalid operator (transfer agent)

    _transferByDefaultPartitions(msg.sender, from, to, value, data);
  }
  /************************************************************************************************/


  /********************************** Partition Token Transfers ***********************************/
  /**
   * @dev Transfer tokens from a specific partition.
   * @param partition Name of the partition.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder.
   * @return Destination partition.
   */
  function transferByPartition(
    bytes32 partition,
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (bytes32)
  {
    return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "");
  }
  /**
   * @dev Transfer tokens from a specific partition through an operator.
   * @param partition Name of the partition.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator.
   * @return Destination partition.
   */
  function operatorTransferByPartition(
    bytes32 partition,
    address from,
    address to,
    uint256 value,
    bytes calldata data,
    bytes calldata operatorData
  )
    external
    returns (bytes32)
  {
    require(_isOperatorForPartition(partition, msg.sender, from)
      || (value <= _allowedByPartition[partition][from][msg.sender]), "53"); // 0x53	insufficient allowance

    if(_allowedByPartition[partition][from][msg.sender] >= value) {
      _allowedByPartition[partition][from][msg.sender] = _allowedByPartition[partition][from][msg.sender].sub(value);
    } else {
      _allowedByPartition[partition][from][msg.sender] = 0;
    }

    return _transferByPartition(partition, msg.sender, from, to, value, data, operatorData);
  }
  /************************************************************************************************/


  /************************************* Controller Operation *************************************/
  /**
   * @dev Know if the token can be controlled by operators.
   * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
   * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
   */
  function isControllable() external view returns (bool) {
    return _isControllable;
  }
  /************************************************************************************************/


  /************************************* Operator Management **************************************/
  /**
   * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
   * and redeem tokens on its behalf.
   * @param operator Address to set as an operator for 'msg.sender'.
   */
  function authorizeOperator(address operator) external {
    require(operator != msg.sender);
    _authorizedOperator[operator][msg.sender] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }
  /**
   * @dev Remove the right of the operator address to be an operator for 'msg.sender'
   * and to transfer and redeem tokens on its behalf.
   * @param operator Address to rescind as an operator for 'msg.sender'.
   */
  function revokeOperator(address operator) external {
    require(operator != msg.sender);
    _authorizedOperator[operator][msg.sender] = false;
    emit RevokedOperator(operator, msg.sender);
  }
  /**
   * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
   * @param partition Name of the partition.
   * @param operator Address to set as an operator for 'msg.sender'.
   */
  function authorizeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = true;
    emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
  }
  /**
   * @dev Remove the right of the operator address to be an operator on a given
   * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
   * @param partition Name of the partition.
   * @param operator Address to rescind as an operator on given partition for 'msg.sender'.
   */
  function revokeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = false;
    emit RevokedOperatorByPartition(partition, operator, msg.sender);
  }
  /************************************************************************************************/


  /************************************* Operator Information *************************************/
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
   */
  function isOperator(address operator, address tokenHolder) external view returns (bool) {
    return _isOperator(operator, tokenHolder);
  }
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
   */
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorForPartition(partition, operator, tokenHolder);
  }
  /************************************************************************************************/


  /**************************************** Token Issuance ****************************************/
  /**
   * @dev Know if new tokens can be issued in the future.
   * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
   */
  function isIssuable() external view returns (bool) {
    return _isIssuable;
  }
  /**
   * @dev Issue tokens from default partition.
   * @param tokenHolder Address for which we want to issue tokens.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, by the issuer.
   */
  function issue(address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    isIssuableToken
  {
    require(_defaultPartitions.length != 0, "55"); // 0x55	funds locked (lockup period)

    _issueByPartition(_defaultPartitions[0], msg.sender, tokenHolder, value, data);
  }
  /**
   * @dev Issue tokens from a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to issue tokens.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, by the issuer.
   */
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    isIssuableToken
  {
    _issueByPartition(partition, msg.sender, tokenHolder, value, data);
  }
  /************************************************************************************************/
  

  /*************************************** Token Redemption ***************************************/
  /**
   * @dev Redeem the amount of tokens from the address 'msg.sender'.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption, by the token holder.
   */
  function redeem(uint256 value, bytes calldata data)
    external
  {
    _redeemByDefaultPartitions(msg.sender, msg.sender, value, data);
  }
  /**
   * @dev Redeem the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function redeemFrom(address from, uint256 value, bytes calldata data)
    external
  {
    require(_isOperator(msg.sender, from), "58"); // 0x58	invalid operator (transfer agent)

    _redeemByDefaultPartitions(msg.sender, from, value, data);
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param value Number of tokens redeemed.
   * @param data Information attached to the redemption, by the redeemer.
   */
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data)
    external
  {
    _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to redeem tokens.
   * @param value Number of tokens redeemed
   * @param operatorData Information attached to the redemption, by the operator.
   */
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData)
    external
  {
    require(_isOperatorForPartition(partition, msg.sender, tokenHolder), "58"); // 0x58	invalid operator (transfer agent)

    _redeemByPartition(partition, msg.sender, tokenHolder, value, "", operatorData);
  }
  /************************************************************************************************/


  /************************************************************************************************/
  /************************ EXTERNAL FUNCTIONS (ADDITIONAL - NOT MANDATORY) ***********************/
  /************************************************************************************************/


  /************************************ Token description *****************************************/
  /**
   * @dev Get the name of the token, e.g., "MyToken".
   * @return Name of the token.
   */
  function name() external view returns(string memory) {
    return _name;
  }
  /**
   * @dev Get the symbol of the token, e.g., "MYT".
   * @return Symbol of the token.
   */
  function symbol() external view returns(string memory) {
    return _symbol;
  }
  /**
   * @dev Get the number of decimals of the token.
   * @return The number of decimals of the token. For retrocompatibility, decimals are forced to 18 in ERC1400.
   */
  function decimals() external pure returns(uint8) {
    return uint8(18);
  }
  /**
   * @dev Get the smallest part of the token that’s not divisible.
   * @return The smallest non-divisible part of the token.
   */
  function granularity() external view returns(uint256) {
    return _granularity;
  }
  /**
   * @dev Get list of existing partitions.
   * @return Array of all exisiting partitions.
   */
  function totalPartitions() external view returns (bytes32[] memory) {
    return _totalPartitions;
  }
  /**
   * @dev Get the total number of issued tokens for a given partition.
   * @param partition Name of the partition.
   * @return Total supply of tokens currently in circulation, for a given partition.
   */
  function totalSupplyByPartition(bytes32 partition) external view returns (uint256) {
    return _totalSupplyByPartition[partition];
  }
  /************************************************************************************************/


  /**************************************** Token behaviours **************************************/
  /**
   * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
   * Once set to false, '_isControllable' can never be set to 'true' again.
   */
  function renounceControl() external onlyOwner {
    _isControllable = false;
  }
  /**
   * @dev Definitely renounce the possibility to issue new tokens.
   * Once set to false, '_isIssuable' can never be set to 'true' again.
   */
  function renounceIssuance() external onlyOwner {
    _isIssuable = false;
  }
  /************************************************************************************************/


  /************************************ Token controllers *****************************************/
  /**
   * @dev Get the list of controllers as defined by the token contract.
   * @return List of addresses of all the controllers.
   */
  function controllers() external view returns (address[] memory) {
    return _controllers;
  }
  /**
   * @dev Get controllers for a given partition.
   * @param partition Name of the partition.
   * @return Array of controllers for partition.
   */
  function controllersByPartition(bytes32 partition) external view returns (address[] memory) {
    return _controllersByPartition[partition];
  }
  /**
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function setControllers(address[] calldata operators) external onlyOwner {
    _setControllers(operators);
  }
  /**
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function setPartitionControllers(bytes32 partition, address[] calldata operators) external onlyOwner {
     _setPartitionControllers(partition, operators);
   }
  /************************************************************************************************/


  /********************************* Token default partitions *************************************/
  /**
   * @dev Get default partitions to transfer from.
   * Function used for ERC20 retrocompatibility.
   * For example, a security token may return the bytes32("unrestricted").
   * @return Array of default partitions.
   */
  function getDefaultPartitions() external view returns (bytes32[] memory) {
    return _defaultPartitions;
  }
  /**
   * @dev Set default partitions to transfer from.
   * Function used for ERC20 retrocompatibility.
   * @param partitions partitions to use by default when not specified.
   */
  function setDefaultPartitions(bytes32[] calldata partitions) external onlyOwner {
    _defaultPartitions = partitions;
  }
  /************************************************************************************************/


  /******************************** Partition Token Allowances ************************************/
  /**
   * @dev Check the value of tokens that an owner allowed to a spender.
   * @param partition Name of the partition.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the value of tokens still available for the spender.
   */
  function allowanceByPartition(bytes32 partition, address owner, address spender) external view returns (uint256) {
    return _allowedByPartition[partition][owner][spender];
  }
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
   * @param partition Name of the partition.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @return A boolean that indicates if the operation was successful.
   */
  function approveByPartition(bytes32 partition, address spender, uint256 value) external returns (bool) {
    require(spender != address(0), "56"); // 0x56	invalid sender
    _allowedByPartition[partition][msg.sender][spender] = value;
    emit ApprovalByPartition(partition, msg.sender, spender, value);
    return true;
  }
  /************************************************************************************************/

  
  /******************* Token extension (hooks triggered by the contract) **************************/
  /**
   * @dev Set validator contract address.
   * The validator contract needs to verify "ERC1400TokensValidator" interface.
   * Once setup, the validator will be called everytime a transfer is executed.
   * @param validatorAddress Address of the validator contract.
   * @param interfaceLabel Interface label of hook contract.
   */
  function setHookContract(address validatorAddress, string calldata interfaceLabel) external onlyOwner {
    _setHookContract(validatorAddress, interfaceLabel);
  }
  /************************************************************************************************/

  /************************************* Token migration ******************************************/
  /**
   * @dev Migrate contract.
   *
   * ===> CAUTION: DEFINITIVE ACTION
   * 
   * This function shall be called once a new version of the smart contract has been created.
   * Once this function is called:
   *  - The address of the new smart contract is set in ERC1820 registry
   *  - If the choice is definitive, the current smart contract is turned off and can never be used again
   *
   * @param newContractAddress Address of the new version of the smart contract.
   * @param definitive If set to 'true' the contract is turned off definitely.
   */
  function migrate(address newContractAddress, bool definitive) external onlyOwner {
    _migrate(newContractAddress, definitive);
  }
  /************************************************************************************************/


  /************************************************************************************************/
  /************************************* INTERNAL FUNCTIONS ***************************************/
  /************************************************************************************************/


  /**************************************** Token Transfers ***************************************/
  /**
   * @dev Perform the transfer of tokens.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   */
  function _transferWithData(
    address from,
    address to,
    uint256 value
  )
    internal
    isNotMigratedToken
  {
    require(_isMultiple(value), "50"); // 0x50	transfer failure
    require(to != address(0), "57"); // 0x57	invalid receiver
    require(_balances[from] >= value, "52"); // 0x52	insufficient balance
  
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value); // ERC20 retrocompatibility 
  }
  /**
   * @dev Transfer tokens from a specific partition.
   * @param fromPartition Partition of the tokens to transfer.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator (if any).
   * @return Destination partition.
   */
  function _transferByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
    returns (bytes32)
  {
    require(_balanceOfByPartition[from][fromPartition] >= value, "52"); // 0x52	insufficient balance

    bytes32 toPartition = fromPartition;

    if(operatorData.length != 0 && data.length >= 64) {
      toPartition = _getDestinationPartition(fromPartition, data);
    }

    _callPreTransferHooks(fromPartition, operator, from, to, value, data, operatorData);

    _removeTokenFromPartition(from, fromPartition, value);
    _transferWithData(from, to, value);
    _addTokenToPartition(to, toPartition, value);

    _callPostTransferHooks(toPartition, operator, from, to, value, data, operatorData);

    emit TransferByPartition(fromPartition, operator, from, to, value, data, operatorData);

    if(toPartition != fromPartition) {
      emit ChangedPartition(fromPartition, toPartition, value);
    }

    return toPartition;
  }
  /**
   * @dev Transfer tokens from default partitions.
   * Function used for ERC20 retrocompatibility.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder ('from') [CAN CONTAIN THE DESTINATION PARTITION].
   */
  function _transferByDefaultPartitions(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data
  )
    internal
  {
    require(_defaultPartitions.length != 0, "55"); // // 0x55	funds locked (lockup period)

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultPartitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]];
      if(_remainingValue <= _localBalance) {
        _transferByPartition(_defaultPartitions[i], operator, from, to, _remainingValue, data, "");
        _remainingValue = 0;
        break;
      } else if (_localBalance != 0) {
        _transferByPartition(_defaultPartitions[i], operator, from, to, _localBalance, data, "");
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "52"); // 0x52	insufficient balance
  }
  /**
   * @dev Retrieve the destination partition from the 'data' field.
   * By convention, a partition change is requested ONLY when 'data' starts
   * with the flag: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
   * When the flag is detected, the destination tranche is extracted from the
   * 32 bytes following the flag.
   * @param fromPartition Partition of the tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @return Destination partition.
   */
  function _getDestinationPartition(bytes32 fromPartition, bytes memory data) internal pure returns(bytes32 toPartition) {
    bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bytes32 flag;
    assembly {
      flag := mload(add(data, 32))
    }
    if(flag == changePartitionFlag) {
      assembly {
        toPartition := mload(add(data, 64))
      }
    } else {
      toPartition = fromPartition;
    }
  }
  /**
   * @dev Remove a token from a specific partition.
   * @param from Token holder.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _removeTokenFromPartition(address from, bytes32 partition, uint256 value) internal {
    _balanceOfByPartition[from][partition] = _balanceOfByPartition[from][partition].sub(value);
    _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].sub(value);

    // If the total supply is zero, finds and deletes the partition.
    if(_totalSupplyByPartition[partition] == 0) {
      uint256 index1 = _indexOfTotalPartitions[partition];
      require(index1 > 0, "50"); // 0x50	transfer failure

      // move the last item into the index being vacated
      bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];
      _totalPartitions[index1 - 1] = lastValue; // adjust for 1-based indexing
      _indexOfTotalPartitions[lastValue] = index1;

      _totalPartitions.length -= 1;
      _indexOfTotalPartitions[partition] = 0;
    }

    // If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
    if(_balanceOfByPartition[from][partition] == 0) {
      uint256 index2 = _indexOfPartitionsOf[from][partition];
      require(index2 > 0, "50"); // 0x50	transfer failure

      // move the last item into the index being vacated
      bytes32 lastValue = _partitionsOf[from][_partitionsOf[from].length - 1];
      _partitionsOf[from][index2 - 1] = lastValue;  // adjust for 1-based indexing
      _indexOfPartitionsOf[from][lastValue] = index2;

      _partitionsOf[from].length -= 1;
      _indexOfPartitionsOf[from][partition] = 0;
    }
  }
  /**
   * @dev Add a token to a specific partition.
   * @param to Token recipient.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _addTokenToPartition(address to, bytes32 partition, uint256 value) internal {
    if(value != 0) {
      if (_indexOfPartitionsOf[to][partition] == 0) {
        _partitionsOf[to].push(partition);
        _indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;
      }
      _balanceOfByPartition[to][partition] = _balanceOfByPartition[to][partition].add(value);

      if (_indexOfTotalPartitions[partition] == 0) {
        _totalPartitions.push(partition);
        _indexOfTotalPartitions[partition] = _totalPartitions.length;
      }
      _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].add(value);
    }
  }
  /**
   * @dev Check if 'value' is multiple of the granularity.
   * @param value The quantity that want's to be checked.
   * @return 'true' if 'value' is a multiple of the granularity.
   */
  function _isMultiple(uint256 value) internal view returns(bool) {
    return(value.div(_granularity).mul(_granularity) == value);
  }
  /************************************************************************************************/


  /****************************************** Hooks ***********************************************/
  /**
   * @dev Check for 'ERC1400TokensSender' hook on the sender + check for 'ERC1400TokensValidator' on the token
   * contract address and call them.
   * @param partition Name of the partition (bytes32 to be left empty for transfers where partition is not specified).
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   */
  function _callPreTransferHooks(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    address senderImplementation;
    senderImplementation = interfaceAddr(from, ERC1400_TOKENS_SENDER);
    if (senderImplementation != address(0)) {
      IERC1400TokensSender(senderImplementation).tokensToTransfer(msg.sig, partition, operator, from, to, value, data, operatorData);
    }

    address validatorImplementation;
    validatorImplementation = interfaceAddr(address(this), ERC1400_TOKENS_VALIDATOR);
    if (validatorImplementation != address(0)) {
      IERC1400TokensValidator(validatorImplementation).tokensToValidate(msg.sig, partition, operator, from, to, value, data, operatorData);
    }
  }
  /**
   * @dev Check for 'ERC1400TokensRecipient' hook on the recipient and call it.
   * @param partition Name of the partition (bytes32 to be left empty for transfers where partition is not specified).
   * @param operator Address which triggered the balance increase (through transfer or issuance).
   * @param from Token holder for a transfer and 0x for an issuance.
   * @param to Token recipient.
   * @param value Number of tokens the recipient balance is increased by.
   * @param data Extra information, intended for the token holder ('from').
   * @param operatorData Extra information attached by the operator (if any).
   */
  function _callPostTransferHooks(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    address recipientImplementation;
    recipientImplementation = interfaceAddr(to, ERC1400_TOKENS_RECIPIENT);

    if (recipientImplementation != address(0)) {
      IERC1400TokensRecipient(recipientImplementation).tokensReceived(msg.sig, partition, operator, from, to, value, data, operatorData);
    }
  }
  /************************************************************************************************/


  /************************************* Operator Information *************************************/
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of 'tokenHolder'.
   * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
   */
  function _isOperator(address operator, address tokenHolder) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorizedOperator[operator][tokenHolder]
      || (_isControllable && _isController[operator])
    );
  }
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
   */
   function _isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) internal view returns (bool) {
     return (_isOperator(operator, tokenHolder)
       || _authorizedOperatorByPartition[tokenHolder][partition][operator]
       || (_isControllable && _isControllerByPartition[partition][operator])
     );
   }
  /************************************************************************************************/


  /**************************************** Token Issuance ****************************************/
  /**
   * @dev Perform the issuance of tokens.
   * @param operator Address which triggered the issuance.
   * @param to Token recipient.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, and intended for the recipient (to).
   */
  function _issue(address operator, address to, uint256 value, bytes memory data)
    internal
    isNotMigratedToken  
  {
    require(_isMultiple(value), "50"); // 0x50	transfer failure
    require(to != address(0), "57"); // 0x57	invalid receiver

    _totalSupply = _totalSupply.add(value);
    _balances[to] = _balances[to].add(value);

    emit Issued(operator, to, value, data);
    emit Transfer(address(0), to, value); // ERC20 retrocompatibility
  }
  /**
   * @dev Issue tokens from a specific partition.
   * @param toPartition Name of the partition.
   * @param operator The address performing the issuance.
   * @param to Token recipient.
   * @param value Number of tokens to issue.
   * @param data Information attached to the issuance.
   */
  function _issueByPartition(
    bytes32 toPartition,
    address operator,
    address to,
    uint256 value,
    bytes memory data
  )
    internal
  {
    _issue(operator, to, value, data);
    _addTokenToPartition(to, toPartition, value);

    _callPostTransferHooks(toPartition, operator, address(0), to, value, data, "");

    emit IssuedByPartition(toPartition, operator, to, value, data, "");
  }
  /************************************************************************************************/


  /*************************************** Token Redemption ***************************************/
  /**
   * @dev Perform the token redemption.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function _redeem(address operator, address from, uint256 value, bytes memory data)
    internal
    isNotMigratedToken
  {
    require(_isMultiple(value), "50"); // 0x50	transfer failure
    require(from != address(0), "56"); // 0x56	invalid sender
    require(_balances[from] >= value, "52"); // 0x52	insufficient balance

    _balances[from] = _balances[from].sub(value);
    _totalSupply = _totalSupply.sub(value);

    emit Redeemed(operator, from, value, data);
    emit Transfer(from, address(0), value);  // ERC20 retrocompatibility
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param fromPartition Name of the partition.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator (if any).
   */
  function _redeemByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    require(_balanceOfByPartition[from][fromPartition] >= value, "52"); // 0x52	insufficient balance

    _callPreTransferHooks(fromPartition, operator, from, address(0), value, data, operatorData);

    _removeTokenFromPartition(from, fromPartition, value);
    _redeem(operator, from, value, data);

    emit RedeemedByPartition(fromPartition, operator, from, value, operatorData);
  }
  /**
   * @dev Redeem tokens from a default partitions.
   * @param operator The address performing the redeem.
   * @param from Token holder.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function _redeemByDefaultPartitions(
    address operator,
    address from,
    uint256 value,
    bytes memory data
  )
    internal
  {
    require(_defaultPartitions.length != 0, "55"); // 0x55	funds locked (lockup period)

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultPartitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]];
      if(_remainingValue <= _localBalance) {
        _redeemByPartition(_defaultPartitions[i], operator, from, _remainingValue, data, "");
        _remainingValue = 0;
        break;
      } else {
        _redeemByPartition(_defaultPartitions[i], operator, from, _localBalance, data, "");
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "52"); // 0x52	insufficient balance
  }
  /************************************************************************************************/


  /************************************** Transfer Validity ***************************************/
  /**
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param functionSig ID of the function that needs to be called.
   * @param partition Name of the partition.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator (if any).
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
  function _canTransfer(bytes4 functionSig, bytes32 partition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData)
    internal
    view
    returns (byte, bytes32, bytes32)
  {
    address checksImplementation = interfaceAddr(address(this), ERC1400_TOKENS_CHECKER);

    if((checksImplementation != address(0))) {
      return IERC1400TokensChecker(checksImplementation).canTransferByPartition(functionSig, partition, operator, from, to, value, data, operatorData);
    }
    else {
      return(hex"00", "", partition);
    }
  }
  /************************************************************************************************/


  /************************************************************************************************/
  /************************ INTERNAL FUNCTIONS (ADDITIONAL - NOT MANDATORY) ***********************/
  /************************************************************************************************/


  /************************************ Token controllers *****************************************/
  /**
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function _setControllers(address[] memory operators) internal {
    for (uint i = 0; i<_controllers.length; i++){
      _isController[_controllers[i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isController[operators[j]] = true;
    }
    _controllers = operators;
  }
  /**
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function _setPartitionControllers(bytes32 partition, address[] memory operators) internal {
     for (uint i = 0; i<_controllersByPartition[partition].length; i++){
       _isControllerByPartition[partition][_controllersByPartition[partition][i]] = false;
     }
     for (uint j = 0; j<operators.length; j++){
       _isControllerByPartition[partition][operators[j]] = true;
     }
     _controllersByPartition[partition] = operators;
   }
  /************************************************************************************************/


  /******************* Token extension (hooks triggered by the contract) **************************/
  /**
   * @dev Set validator contract address.
   * The validator contract needs to verify "ERC1400TokensValidator" interface.
   * Once setup, the validator will be called everytime a transfer is executed.
   * @param validatorAddress Address of the validator contract.
   * @param interfaceLabel Interface label of hook contract.
   */
  function _setHookContract(address validatorAddress, string memory interfaceLabel) internal {
    address oldValidatorAddress = interfaceAddr(address(this), interfaceLabel);

    if (oldValidatorAddress != address(0)) {
      if(isMinter(oldValidatorAddress)) {
        _removeMinter(oldValidatorAddress);
      }
      _isController[oldValidatorAddress] = false;
    }

    ERC1820Client.setInterfaceImplementation(interfaceLabel, validatorAddress);
    if(!isMinter(validatorAddress)) {
      _addMinter(validatorAddress);
    }
    _isController[validatorAddress] = true;
  }
  /************************************************************************************************/


  /************************************* Token migration ******************************************/
  /**
   * @dev Migrate contract.
   *
   * ===> CAUTION: DEFINITIVE ACTION
   * 
   * This function shall be called once a new version of the smart contract has been created.
   * Once this function is called:
   *  - The address of the new smart contract is set in ERC1820 registry
   *  - If the choice is definitive, the current smart contract is turned off and can never be used again
   *
   * @param newContractAddress Address of the new version of the smart contract.
   * @param definitive If set to 'true' the contract is turned off definitely.
   */
  function _migrate(address newContractAddress, bool definitive) internal {
    ERC1820Client.setInterfaceImplementation(ERC20_INTERFACE_NAME, newContractAddress);
    ERC1820Client.setInterfaceImplementation(ERC1400_INTERFACE_NAME, newContractAddress);
    if(definitive) {
      _migrated = true;
    }
  }
  /************************************************************************************************/

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */



// CertificateController comment...
contract CertificateController {

  // If set to 'true', the certificate control is activated
  bool _certificateControllerActivated;

  // Address used by off-chain controller service to sign certificate
  mapping(address => bool) internal _certificateSigners;

  // A nonce used to ensure a certificate can be used only once
  /* mapping(address => uint256) internal _checkCount; */

  // A nonce used to ensure a certificate can be used only once
  mapping(bytes32 => bool) internal _usedCertificate;

  event Used(address sender);

  constructor(address _certificateSigner, bool activated) public {
    _setCertificateSigner(_certificateSigner, true);
    _certificateControllerActivated = activated;
  }

  /**
   * @dev Modifier to protect methods with certificate control
   */
  modifier isValidCertificate(bytes memory data) {

    if(_certificateControllerActivated) {
      require(_certificateSigners[msg.sender] || _checkCertificate(data, 0, 0x00000000), "54"); // 0x54	transfers halted (contract paused)

      bytes32 salt;
      assembly {
        salt := mload(add(data, 0x20))
      }

      _usedCertificate[salt] = true; // Use certificate

      emit Used(msg.sender);
    }
    
    _;
  }

  /**
   * @dev Modifier to protect methods with certificate control
   */
  /* modifier isValidPayableCertificate(bytes memory data) {

    require(_certificateSigners[msg.sender] || _checkCertificate(data, msg.value, 0x00000000), "54"); // 0x54	transfers halted (contract paused)

    bytes32 salt;
    assembly {
      salt := mload(add(data, 0x20))
    }

    _usedCertificate[salt] = true; // Use certificate

    emit Used(msg.sender);
    _;
  } */

  /**
   * @dev Get state of certificate (used or not).
   * @param salt First 32 bytes of certificate whose validity is being checked.
   * @return bool 'true' if certificate is already used, 'false' if not.
   */
  function isUsedCertificate(bytes32 salt) external view returns (bool) {
    return _usedCertificate[salt];
  }

  /**
   * @dev Set signer authorization for operator.
   * @param operator Address to add/remove as a certificate signer.
   * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
   */
  function _setCertificateSigner(address operator, bool authorized) internal {
    require(operator != address(0)); // Action Blocked - Not a valid address
    _certificateSigners[operator] = authorized;
  }

  /**
   * @dev Get activation status of certificate controller.
   */
  function certificateControllerActivated() external view returns (bool) {
    return _certificateControllerActivated;
  }

  /**
   * @dev Activate/disactivate certificate controller.
   * @param activated 'true', if the certificate control shall be activated, 'false' if not.
   */
  function _setCertificateControllerActivated(bool activated) internal {
    _certificateControllerActivated = activated;
  }

  /**
   * @dev Checks if a certificate is correct
   * @param data Certificate to control
   */
  function _checkCertificate(
    bytes memory data,
    uint256 amount,
    bytes4 functionID
  )
    internal
    view
    returns(bool)
  {
    bytes32 salt;
    uint256 e;
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Certificate should be 129 bytes long
    if (data.length != 129) {
      return false;
    }

    // Extract certificate information and expiration time from payload
    assembly {
      // Retrieve expirationTime & ECDSA elements from certificate which is a 97 long bytes
      // Certificate encoding format is: <salt (32 bytes)>@<expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
      salt := mload(add(data, 0x20))
      e := mload(add(data, 0x40))
      r := mload(add(data, 0x60))
      s := mload(add(data, 0x80))
      v := byte(0, mload(add(data, 0xa0)))
    }

    // Certificate should not be expired
    if (e < now) {
      return false;
    }

    if (v < 27) {
      v += 27;
    }

    // Perform ecrecover to ensure message information corresponds to certificate
    if (v == 27 || v == 28) {
      // Extract payload and remove data argument
      bytes memory payload;

      assembly {
        let payloadsize := sub(calldatasize, 192)
        payload := mload(0x40) // allocate new memory
        mstore(0x40, add(payload, and(add(add(payloadsize, 0x20), 0x1f), not(0x1f)))) // boolean trick for padding to 0x40
        mstore(payload, payloadsize) // set length
        calldatacopy(add(add(payload, 0x20), 4), 4, sub(payloadsize, 4))
      }

      if(functionID == 0x00000000) {
        assembly {
          calldatacopy(add(payload, 0x20), 0, 4)
        }
      } else {
        for (uint i = 0; i < 4; i++) { // replace 4 bytes corresponding to function selector
          payload[i] = functionID[i];
        }
      }

      // Pack and hash
      bytes memory pack = abi.encodePacked(
        msg.sender,
        this,
        amount,
        payload,
        e,
        salt
      );
      bytes32 hash = keccak256(pack);

      // Check if certificate match expected transactions parameters
      if (_certificateSigners[ecrecover(hash, v, r, s)] && !_usedCertificate[salt]) {
        return true;
      }
    }
    return false;
  }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */





/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400CertificateSalt is ERC1400, CertificateController {

  /**
   * @dev Initialize ERC1400 + initialize certificate controller.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param certificateSigner Address of the off-chain service which signs the
   * conditional ownership certificates required for token transfers, issuance,
   * redemption (Cf. CertificateController.sol).
   * @param certificateActivated If set to 'true', the certificate controller
   * is activated at contract creation.
   * @param defaultPartitions Partitions chosen by default, when partition is
   * not specified, like the case ERC20 tranfers.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    address certificateSigner,
    bool certificateActivated,
    bytes32[] memory defaultPartitions
  )
    public
    ERC1400(name, symbol, granularity, controllers, defaultPartitions)
    CertificateController(certificateSigner, certificateActivated)
  {}


  /************************************ Certificate control ***************************************/
  /**
   * @dev Add a certificate signer for the token.
   * @param operator Address to set as a certificate signer.
   * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
   */
  function setCertificateSigner(address operator, bool authorized) external onlyOwner {
    _setCertificateSigner(operator, authorized);
  }
  /**
   * @dev Activate/disactivate certificate controller.
   * @param activated 'true', if the certificate control shall be activated, 'false' if not.
   */
  function setCertificateControllerActivated(bool activated) external onlyOwner {
   _setCertificateControllerActivated(activated);
  }
  /************************************************************************************************/


  /********************** ERC1400 functions to control with certificate ***************************/
  function transferWithData(address to, uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
  {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, data);
  }

  function transferFromWithData(address from, address to, uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
  {
    require(_isOperator(msg.sender, from), "58"); // 0x58	invalid operator (transfer agent)

    _transferByDefaultPartitions(msg.sender, from, to, value, data);
  }

  function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
    returns (bytes32)
  {
    return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "");
  }

  function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    isValidCertificate(operatorData)
    returns (bytes32)
  {
    require(_isOperatorForPartition(partition, msg.sender, from)
      || (value <= _allowedByPartition[partition][from][msg.sender]), "53"); // 0x53	insufficient allowance

    if(_allowedByPartition[partition][from][msg.sender] >= value) {
      _allowedByPartition[partition][from][msg.sender] = _allowedByPartition[partition][from][msg.sender].sub(value);
    } else {
      _allowedByPartition[partition][from][msg.sender] = 0;
    }

    return _transferByPartition(partition, msg.sender, from, to, value, data, operatorData);
  }

  function issue(address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    isIssuableToken
    isValidCertificate(data)
  {
    require(_defaultPartitions.length != 0, "55"); // 0x55	funds locked (lockup period)

    _issueByPartition(_defaultPartitions[0], msg.sender, tokenHolder, value, data);
  }

  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    isIssuableToken
    isValidCertificate(data)
  {
    _issueByPartition(partition, msg.sender, tokenHolder, value, data);
  }

  function redeem(uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
  {
    _redeemByDefaultPartitions(msg.sender, msg.sender, value, data);
  }

  function redeemFrom(address from, uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
  {
    require(_isOperator(msg.sender, from), "58"); // 0x58	invalid operator (transfer agent)

    _redeemByDefaultPartitions(msg.sender, from, value, data);
  }

  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data)
    external
    isValidCertificate(data)
  {
    _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
  }

  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData)
    external
    isValidCertificate(operatorData)
  {
    require(_isOperatorForPartition(partition, msg.sender, tokenHolder), "58"); // 0x58	invalid operator (transfer agent)

    _redeemByPartition(partition, msg.sender, tokenHolder, value, "", operatorData);
  }
  /************************************************************************************************/


  /************************************** Transfer Validity ***************************************/
  /**
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param partition Name of the partition.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
  function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    bytes4 functionSig = this.transferByPartition.selector; // 0xf3d490db: 4 first bytes of keccak256(transferByPartition(bytes32,address,uint256,bytes))
    if(!_checkCertificate(data, 0, functionSig)) {
      return(hex"54", "", partition); // 0x54	transfers halted (contract paused)
    } else {
      return ERC1400._canTransfer(functionSig, partition, msg.sender, msg.sender, to, value, data, "");
    }
  }
  /**
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param partition Name of the partition.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
  function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    bytes4 functionSig = this.operatorTransferByPartition.selector; // 0x8c0dee9c: 4 first bytes of keccak256(operatorTransferByPartition(bytes32,address,address,uint256,bytes,bytes))
    if(!_checkCertificate(operatorData, 0, functionSig)) {
      return(hex"54", "", partition); // 0x54	transfers halted (contract paused)
    } else {
      return ERC1400._canTransfer(functionSig, partition, msg.sender, from, to, value, data, operatorData);
    }
  }
  /************************************************************************************************/

  /******************* Token extension (hooks triggered by the contract) **************************/
  /**
   * @dev Set validator contract address.
   * The validator contract needs to verify "ERC1400TokensValidator" interface.
   * Once setup, the validator will be called everytime a transfer is executed.
   * @param validatorAddress Address of the validator contract.
   * @param interfaceLabel Interface label of hook contract.
   */
  function _setHookContract(address validatorAddress, string memory interfaceLabel) internal {
    address oldValidatorAddress = interfaceAddr(address(this), interfaceLabel);
    _setCertificateSigner(oldValidatorAddress, false);
    
    ERC1400._setHookContract(validatorAddress, interfaceLabel);
    _setCertificateSigner(validatorAddress, true);
  }
  /************************************************************************************************/

}