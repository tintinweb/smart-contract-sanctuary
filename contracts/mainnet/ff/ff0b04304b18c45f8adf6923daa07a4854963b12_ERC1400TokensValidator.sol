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

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */





/**
 * @title PauserRole
 * @dev Pausers are responsible for pausing/unpausing transfers.
 */
contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed token, address indexed account);
    event PauserRemoved(address indexed token, address indexed account);

    // Mapping from token to token pausers.
    mapping(address => Roles.Role) private _pausers;

    constructor () internal {}

    modifier onlyPauser(address token) {
        require(isPauser(token, msg.sender));
        _;
    }

    function isPauser(address token, address account) public view returns (bool) {
        return _pausers[token].has(account);
    }

    function addPauser(address token, address account) public onlyPauser(token) {
        _addPauser(token, account);
    }

    function renouncePauser(address token) public {
        _removePauser(token, msg.sender);
    }

    function _addPauser(address token, address account) internal {
        _pausers[token].add(account);
        emit PauserAdded(token, account);
    }

    function _removePauser(address token, address account) internal {
        _pausers[token].remove(account);
        emit PauserRemoved(token, account);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address indexed token, address account);
    event Unpaused(address indexed token, address account);

    // Mapping from token to token paused status.
    mapping(address => bool) private _paused;

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused(address token) public view returns (bool) {
        return _paused[token];
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address token) {
        require(!_paused[token]);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused(address token) {
        require(_paused[token]);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause(address token) public onlyPauser(token) whenNotPaused(token) {
        _paused[token] = true;
        emit Paused(token, msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause(address token) public onlyPauser(token) whenPaused(token) {
        _paused[token] = false;
        emit Unpaused(token, msg.sender);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */





/**
 * @title AllowlistAdminRole
 * @dev AllowlistAdmins are responsible for assigning and removing Allowlisted accounts.
 */
contract AllowlistAdminRole {
    using Roles for Roles.Role;

    event AllowlistAdminAdded(address indexed token, address indexed account);
    event AllowlistAdminRemoved(address indexed token, address indexed account);

    // Mapping from token to token allowlist admins.
    mapping(address => Roles.Role) private _allowlistAdmins;

    constructor () internal {}

    modifier onlyAllowlistAdmin(address token) {
        require(isAllowlistAdmin(token, msg.sender));
        _;
    }

    function isAllowlistAdmin(address token, address account) public view returns (bool) {
        return _allowlistAdmins[token].has(account);
    }

    function addAllowlistAdmin(address token, address account) public onlyAllowlistAdmin(token) {
        _addAllowlistAdmin(token, account);
    }

    function renounceAllowlistAdmin(address token) public {
        _removeAllowlistAdmin(token, msg.sender);
    }

    function _addAllowlistAdmin(address token, address account) internal {
        _allowlistAdmins[token].add(account);
        emit AllowlistAdminAdded(token, account);
    }

    function _removeAllowlistAdmin(address token, address account) internal {
        _allowlistAdmins[token].remove(account);
        emit AllowlistAdminRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */






/**
 * @title AllowlistedRole
 * @dev Allowlisted accounts have been forbidden by a AllowlistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are AllowlistAdmins (who can also remove
 * it), and not Allowlisteds themselves.
 */
contract AllowlistedRole is AllowlistAdminRole {
    using Roles for Roles.Role;

    event AllowlistedAdded(address indexed token, address indexed account);
    event AllowlistedRemoved(address indexed token, address indexed account);

    // Mapping from token to token allowlisteds.
    mapping(address => Roles.Role) private _allowlisteds;

    modifier onlyNotAllowlisted(address token) {
        require(!isAllowlisted(token, msg.sender));
        _;
    }

    function isAllowlisted(address token, address account) public view returns (bool) {
        return _allowlisteds[token].has(account);
    }

    function addAllowlisted(address token, address account) public onlyAllowlistAdmin(token) {
        _addAllowlisted(token, account);
    }

    function removeAllowlisted(address token, address account) public onlyAllowlistAdmin(token) {
        _removeAllowlisted(token, account);
    }

    function _addAllowlisted(address token, address account) internal {
        _allowlisteds[token].add(account);
        emit AllowlistedAdded(token, account);
    }

    function _removeAllowlisted(address token, address account) internal {
        _allowlisteds[token].remove(account);
        emit AllowlistedRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */





/**
 * @title BlocklistAdminRole
 * @dev BlocklistAdmins are responsible for assigning and removing Blocklisted accounts.
 */
contract BlocklistAdminRole {
    using Roles for Roles.Role;

    event BlocklistAdminAdded(address indexed token, address indexed account);
    event BlocklistAdminRemoved(address indexed token, address indexed account);

    // Mapping from token to token blocklist admins.
    mapping(address => Roles.Role) private _blocklistAdmins;

    constructor () internal {}

    modifier onlyBlocklistAdmin(address token) {
        require(isBlocklistAdmin(token, msg.sender));
        _;
    }

    function isBlocklistAdmin(address token, address account) public view returns (bool) {
        return _blocklistAdmins[token].has(account);
    }

    function addBlocklistAdmin(address token, address account) public onlyBlocklistAdmin(token) {
        _addBlocklistAdmin(token, account);
    }

    function renounceBlocklistAdmin(address token) public {
        _removeBlocklistAdmin(token, msg.sender);
    }

    function _addBlocklistAdmin(address token, address account) internal {
        _blocklistAdmins[token].add(account);
        emit BlocklistAdminAdded(token, account);
    }

    function _removeBlocklistAdmin(address token, address account) internal {
        _blocklistAdmins[token].remove(account);
        emit BlocklistAdminRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */






/**
 * @title BlocklistedRole
 * @dev Blocklisted accounts have been forbidden by a BlocklistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are BlocklistAdmins (who can also remove
 * it), and not Blocklisteds themselves.
 */
contract BlocklistedRole is BlocklistAdminRole {
    using Roles for Roles.Role;

    event BlocklistedAdded(address indexed token, address indexed account);
    event BlocklistedRemoved(address indexed token, address indexed account);

    // Mapping from token to token blocklisteds.
    mapping(address => Roles.Role) private _blocklisteds;

    modifier onlyNotBlocklisted(address token) {
        require(!isBlocklisted(token, msg.sender));
        _;
    }

    function isBlocklisted(address token, address account) public view returns (bool) {
        return _blocklisteds[token].has(account);
    }

    function addBlocklisted(address token, address account) public onlyBlocklistAdmin(token) {
        _addBlocklisted(token, account);
    }

    function removeBlocklisted(address token, address account) public onlyBlocklistAdmin(token) {
        _removeBlocklisted(token, account);
    }

    function _addBlocklisted(address token, address account) internal {
        _blocklisteds[token].add(account);
        emit BlocklistedAdded(token, account);
    }

    function _removeBlocklisted(address token, address account) internal {
        _blocklisteds[token].remove(account);
        emit BlocklistedRemoved(token, account);
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
 * @notice Interface to the Minterrole contract
 */
interface IMinterRole {
  function isMinter(address account) external view returns (bool);
}


contract ERC1400TokensValidator is IERC1400TokensValidator, Pausable, AllowlistedRole, BlocklistedRole, ERC1820Client, ERC1820Implementer {
  using SafeMath for uint256;

  string constant internal ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";

  bytes4 constant internal ERC20_TRANSFER_FUNCTION_ID = bytes4(keccak256("transfer(address,uint256)"));
  bytes4 constant internal ERC20_TRANSFERFROM_FUNCTION_ID = bytes4(keccak256("transferFrom(address,address,uint256)"));

  // Mapping from token to allowlist activation status.
  mapping(address => bool) internal _allowlistActivated;

  // Mapping from token to blocklist activation status.
  mapping(address => bool) internal _blocklistActivated;

  // Mapping from token to partition granularity activation status.
  mapping(address => bool) internal _granularityByPartitionActivated;

  // Mapping from token to holds activation status.
  mapping(address => bool) internal _holdsActivated;

  // Mapping from token to self-holds activation status.
  mapping(address => bool) internal _selfHoldsActivated;

  // Mapping from token to token controllers.
  mapping(address => address[]) internal _tokenControllers;

  // Mapping from (token, operator) to token controller status.
  mapping(address => mapping(address => bool)) internal _isTokenController;

  enum HoldStatusCode {
    Nonexistent,
    Ordered,
    Executed,
    ExecutedAndKeptOpen,
    ReleasedByNotary,
    ReleasedByPayee,
    ReleasedOnExpiration
  }

  struct Hold {
    bytes32 partition;
    address sender;
    address recipient;
    address notary;
    uint256 value;
    uint256 expiration;
    bytes32 secretHash;
    bytes32 secret;
    HoldStatusCode status;
  }

  // Mapping from (token, partition) to partition granularity.
  mapping(address => mapping(bytes32 => uint256)) internal _granularityByPartition;
  
  // Mapping from (token, holdId) to hold.
  mapping(address => mapping(bytes32 => Hold)) internal _holds;

  // Mapping from (token, tokenHolder) to balance on hold.
  mapping(address => mapping(address => uint256)) internal _heldBalance;

  // Mapping from (token, tokenHolder, partition) to balance on hold of corresponding partition.
  mapping(address => mapping(address => mapping(bytes32 => uint256))) internal _heldBalanceByPartition;

  // Mapping from (token, partition) to global balance on hold of corresponding partition.
  mapping(address => mapping(bytes32 => uint256)) internal _totalHeldBalanceByPartition;

  // Total balance on hold.
  mapping(address => uint256) internal _totalHeldBalance;

  // Mapping from hold parameter's hash to hold's nonce.
  mapping(bytes32 => uint256) internal _hashNonce;

  // Mapping from (hash, nonce) to hold ID.
  mapping(bytes32 => mapping(uint256 => bytes32)) internal _holdIds;

  event HoldCreated(
    address indexed token,
    bytes32 indexed holdId,
    bytes32 partition,
    address sender,
    address recipient,
    address indexed notary,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  );
  event HoldReleased(address indexed token, bytes32 holdId, address indexed notary, HoldStatusCode status);
  event HoldRenewed(address indexed token, bytes32 holdId, address indexed notary, uint256 oldExpiration, uint256 newExpiration);
  event HoldExecuted(address indexed token, bytes32 holdId, address indexed notary, uint256 heldValue, uint256 transferredValue, bytes32 secret);
  event HoldExecutedAndKeptOpen(address indexed token, bytes32 holdId, address indexed notary, uint256 heldValue, uint256 transferredValue, bytes32 secret);
  
  /**
   * @dev Modifier to verify if sender is a token controller.
   */
  modifier onlyTokenController(address token) {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender],
      "Sender is not a token controller."
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is a pauser.
   */
  modifier onlyPauser(address token) {
    require(
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isPauser(token, msg.sender),
      "Sender is not a pauser"
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is an allowlist admin.
   */
  modifier onlyAllowlistAdmin(address token) {
    require(
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isAllowlistAdmin(token, msg.sender),
      "Sender is not an allowlist admin"
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is a blocklist admin.
   */
  modifier onlyBlocklistAdmin(address token) {
    require(
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isBlocklistAdmin(token, msg.sender),
      "Sender is not a blocklist admin"
    );
    _;
  }

  constructor() public {
    ERC1820Implementer._setInterface(ERC1400_TOKENS_VALIDATOR);
  }

  /**
   * @dev Get the list of token controllers for a given token.
   * @return Setup of a given token.
   */
  function retrieveTokenSetup(address token) external view returns (bool, bool, bool, bool, bool, address[] memory) {
    return (
      _allowlistActivated[token],
      _blocklistActivated[token],
      _granularityByPartitionActivated[token],
      _holdsActivated[token],
      _selfHoldsActivated[token],
      _tokenControllers[token]
    );
  }

  /**
   * @dev Register token setup.
   */
  function registerTokenSetup(
    address token,
    bool allowlistActivated,
    bool blocklistActivated,
    bool granularityByPartitionActivated,
    bool holdsActivated,
    bool selfHoldsActivated,
    address[] calldata operators
  ) external onlyTokenController(token) {
    _allowlistActivated[token] = allowlistActivated;
    _blocklistActivated[token] = blocklistActivated;
    _granularityByPartitionActivated[token] = granularityByPartitionActivated;
    _holdsActivated[token] = holdsActivated;
    _selfHoldsActivated[token] = selfHoldsActivated;
    _setTokenControllers(token, operators);
  }

  /**
   * @dev Set list of token controllers for a given token.
   * @param token Token address.
   * @param operators Operators addresses.
   */
  function _setTokenControllers(address token, address[] memory operators) internal {
    for (uint i = 0; i<_tokenControllers[token].length; i++){
      _isTokenController[token][_tokenControllers[token][i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isTokenController[token][operators[j]] = true;
    }
    _tokenControllers[token] = operators;
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @param token Address of the token.
   * @param functionSig ID of the function that is called.
   * @param partition Name of the partition (left empty for ERC20 transfer).
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
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
  ) // Comments to avoid compilation warnings for unused variables.
    external
    view 
    returns(bool)
  {
    (bool canValidateToken,) = _canValidate(token, functionSig, partition, operator, from, to, value, data, operatorData);
    return canValidateToken;
  }

  /**
   * @dev Function called by the token contract before executing a transfer.
   * @param functionSig ID of the function that is called.
   * @param partition Name of the partition (left empty for ERC20 transfer).
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  function tokensToValidate(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) // Comments to avoid compilation warnings for unused variables.
    external
  {
    (bool canValidateToken, bytes32 holdId) = _canValidate(msg.sender, functionSig, partition, operator, from, to, value, data, operatorData);
    require(canValidateToken, "55"); // 0x55	funds locked (lockup period)

    if (_holdsActivated[msg.sender] && holdId != "") {
      Hold storage executableHold = _holds[msg.sender][holdId];
      _setHoldToExecuted(
        msg.sender,
        executableHold,
        holdId,
        value,
        executableHold.value,
        ""
      );
    }
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   * @return hold ID in case a hold can be executed for the given parameters.
   */
  function _canValidate(
    address token,
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes memory /*data*/,
    bytes memory /*operatorData*/
  ) // Comments to avoid compilation warnings for unused variables.
    internal
    view
    whenNotPaused(token)
    returns(bool, bytes32)
  {
    if(_functionRequiresValidation(functionSig)) {
      if(_allowlistActivated[token]) {
        if(!isAllowlisted(token, from) || !isAllowlisted(token, to)) {
          return (false, "");
        }
      }
      if(_blocklistActivated[token]) {
        if(isBlocklisted(token, from) || isBlocklisted(token, to)) {
          return (false, "");
        }
      }
    }

    if(_granularityByPartitionActivated[token]) {
      if(
        _granularityByPartition[token][partition] > 0 &&
        !_isMultiple(_granularityByPartition[token][partition], value)
      ) {
        return (false, "");
      } 
    }

    if (_holdsActivated[token]) {
      if(functionSig == ERC20_TRANSFERFROM_FUNCTION_ID) {
        (,, bytes32 holdId) = _retrieveHoldHashNonceId(token, partition, operator, from, to, value);
        Hold storage hold = _holds[token][holdId];
        
        if (_holdCanBeExecutedAsNotary(hold, operator, value) && value <= IERC1400(token).balanceOfByPartition(partition, from)) {
          return (true, holdId);
        }
      }
      
      if(value > _spendableBalanceOfByPartition(token, partition, from)) {
        return (false, "");
      }
    }
    
    return (true, "");
  }

  /**
   * @dev Get granularity for a given partition.
   * @param token Address of the token.
   * @param partition Name of the partition.
   * @return Granularity of the partition.
   */
  function granularityByPartition(address token, bytes32 partition) external view returns (uint256) {
    return _granularityByPartition[token][partition];
  }
  
  /**
   * @dev Set partition granularity
   */
  function setGranularityByPartition(
    address token,
    bytes32 partition,
    uint256 granularity
  )
    external
    onlyTokenController(token)
  {
    _granularityByPartition[token][partition] = granularity;
  }

  /**
   * @dev Create a new token pre-hold.
   */
  function preHoldFor(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash
  )
    external
    returns (bool)
  {
    return _createHold(
      token,
      holdId,
      address(0),
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash
    );
  }

  /**
   * @dev Create a new token pre-hold with expiration date.
   */
  function preHoldForWithExpirationDate(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);

    return _createHold(
      token,
      holdId,
      address(0),
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash
    );
  }

  /**
   * @dev Create a new token hold.
   */
  function hold(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash
  ) 
    external
    returns (bool)
  {
    return _createHold(
      token,
      holdId,
      msg.sender,
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash
    );
  }

  /**
   * @dev Create a new token hold on behalf of the token holder.
   */
  function holdFrom(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash
  )
    external
    returns (bool)
  {
    require(sender != address(0), "Payer address must not be zero address");
    return _createHold(
      token,
      holdId,
      sender,
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash
    );
  }

  /**
   * @dev Create a new token hold with expiration date.
   */
  function holdWithExpirationDate(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);

    return _createHold(
      token,
      holdId,
      msg.sender,
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash
    );
  }

  /**
   * @dev Create a new token hold with expiration date on behalf of the token holder.
   */
  function holdFromWithExpirationDate(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);
    require(sender != address(0), "Payer address must not be zero address");

    return _createHold(
      token,
      holdId,
      sender,
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash
    );
  }

  /**
   * @dev Create a new token hold.
   */
  function _createHold(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  ) internal returns (bool)
  {
    Hold storage newHold = _holds[token][holdId];

    require(recipient != address(0), "Payee address must not be zero address");
    require(value != 0, "Value must be greater than zero");
    require(newHold.value == 0, "This holdId already exists");
    require(notary != address(0), "Notary address must not be zero address");
    
    if (sender == address(0)) { // pre-hold (tokens do not already exist)
      require(
        _canPreHold(token, msg.sender),
        "The pre-hold can only be created by the minter"
      );
    } else { // post-hold (tokens already exist)
      require(value <= _spendableBalanceOfByPartition(token, partition, sender), "Amount of the hold can't be greater than the spendable balance of the sender");
      require(
        _canPostHold(token, partition, msg.sender, sender),
        "The hold can only be renewed by the issuer or the payer"
      );
    }
    
    newHold.partition = partition;
    newHold.sender = sender;
    newHold.recipient = recipient;
    newHold.notary = notary;
    newHold.value = value;
    newHold.expiration = expiration;
    newHold.secretHash = secretHash;
    newHold.status = HoldStatusCode.Ordered;

    if(sender != address(0)) {
      // In case tokens already exist, increase held balance
      _increaseHeldBalance(token, newHold, holdId);
    }

    emit HoldCreated(
      token,
      holdId,
      partition,
      sender,
      recipient,
      notary,
      value,
      expiration,
      secretHash
    );

    return true;
  }

  /**
   * @dev Release token hold.
   */
  function releaseHold(address token, bytes32 holdId) external returns (bool) {
    return _releaseHold(token, holdId);
  }

  /**
   * @dev Release token hold.
   */
  function _releaseHold(address token, bytes32 holdId) internal returns (bool) {
    Hold storage releasableHold = _holds[token][holdId];

    require(
        releasableHold.status == HoldStatusCode.Ordered || releasableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
        "A hold can only be released in status Ordered or ExecutedAndKeptOpen"
    );
    require(
        _isExpired(releasableHold.expiration) ||
        (msg.sender == releasableHold.notary) ||
        (msg.sender == releasableHold.recipient),
        "A not expired hold can only be released by the notary or the payee"
    );

    if (_isExpired(releasableHold.expiration)) {
        releasableHold.status = HoldStatusCode.ReleasedOnExpiration;
    } else {
        if (releasableHold.notary == msg.sender) {
            releasableHold.status = HoldStatusCode.ReleasedByNotary;
        } else {
            releasableHold.status = HoldStatusCode.ReleasedByPayee;
        }
    }

    if(releasableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, releasableHold, releasableHold.value);
    }

    emit HoldReleased(token, holdId, releasableHold.notary, releasableHold.status);

    return true;
  }

  /**
   * @dev Renew hold.
   */
  function renewHold(address token, bytes32 holdId, uint256 timeToExpiration) external returns (bool) {
    return _renewHold(token, holdId, _computeExpiration(timeToExpiration));
  }

  /**
   * @dev Renew hold with expiration time.
   */
  function renewHoldWithExpirationDate(address token, bytes32 holdId, uint256 expiration) external returns (bool) {
    _checkExpiration(expiration);

    return _renewHold(token, holdId, expiration);
  }

  /**
   * @dev Renew hold.
   */
  function _renewHold(address token, bytes32 holdId, uint256 expiration) internal returns (bool) {
    Hold storage renewableHold = _holds[token][holdId];

    require(
      renewableHold.status == HoldStatusCode.Ordered
      || renewableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
      "A hold can only be renewed in status Ordered or ExecutedAndKeptOpen"
    );
    require(!_isExpired(renewableHold.expiration), "An expired hold can not be renewed");

    if (renewableHold.sender == address(0)) { // pre-hold (tokens do not already exist)
      require(
        _canPreHold(token, msg.sender),
        "The pre-hold can only be renewed by the minter"
      );
    } else { // post-hold (tokens already exist)
      require(
        _canPostHold(token, renewableHold.partition, msg.sender, renewableHold.sender),
        "The hold can only be renewed by the issuer or the payer"
      );
    }
    
    uint256 oldExpiration = renewableHold.expiration;
    renewableHold.expiration = expiration;

    emit HoldRenewed(
      token,
      holdId,
      renewableHold.notary,
      oldExpiration,
      expiration
    );

    return true;
  }

  /**
   * @dev Execute hold.
   */
  function executeHold(address token, bytes32 holdId, uint256 value, bytes32 secret) external returns (bool) {
    return _executeHold(
      token,
      holdId,
      msg.sender,
      value,
      secret,
      false
    );
  }

  /**
   * @dev Execute hold and keep open.
   */
  function executeHoldAndKeepOpen(address token, bytes32 holdId, uint256 value, bytes32 secret) external returns (bool) {
    return _executeHold(
      token,
      holdId,
      msg.sender,
      value,
      secret,
      true
    );
  }
  
  /**
   * @dev Execute hold.
   */
  function _executeHold(
    address token,
    bytes32 holdId,
    address operator,
    uint256 value,
    bytes32 secret,
    bool keepOpenIfHoldHasBalance
  ) internal returns (bool)
  {
    Hold storage executableHold = _holds[token][holdId];

    bool canExecuteHold;
    if(secret != "" && _holdCanBeExecutedAsSecretHolder(executableHold, value, secret)) {
      executableHold.secret = secret;
      canExecuteHold = true;
    } else if(_holdCanBeExecutedAsNotary(executableHold, operator, value)) {
      canExecuteHold = true;
    }

    if(canExecuteHold) {
      if (keepOpenIfHoldHasBalance && ((executableHold.value - value) > 0)) {
        _setHoldToExecutedAndKeptOpen(
          token,
          executableHold,
          holdId,
          value,
          value,
          secret
        );
      } else {
        _setHoldToExecuted(
          token,
          executableHold,
          holdId,
          value,
          executableHold.value,
          secret
        );
      }

      if (executableHold.sender == address(0)) { // pre-hold (tokens do not already exist)
        IERC1400(token).issueByPartition(executableHold.partition, executableHold.recipient, value, "");
      } else { // post-hold (tokens already exist)
        IERC1400(token).operatorTransferByPartition(executableHold.partition, executableHold.sender, executableHold.recipient, value, "", "");
      }
      
    } else {
      revert("hold can not be executed");
    }

  }

  /**
   * @dev Set hold to executed.
   */
  function _setHoldToExecuted(
    address token,
    Hold storage executableHold,
    bytes32 holdId,
    uint256 value,
    uint256 heldBalanceDecrease,
    bytes32 secret
  ) internal
  {
    if(executableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, executableHold, heldBalanceDecrease);
    }

    executableHold.status = HoldStatusCode.Executed;

    emit HoldExecuted(
      token,
      holdId,
      executableHold.notary,
      executableHold.value,
      value,
      secret
    );
  }

  /**
   * @dev Set hold to executed and kept open.
   */
  function _setHoldToExecutedAndKeptOpen(
    address token,
    Hold storage executableHold,
    bytes32 holdId,
    uint256 value,
    uint256 heldBalanceDecrease,
    bytes32 secret
  ) internal
  {
    if(executableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, executableHold, heldBalanceDecrease);
    } 

    executableHold.status = HoldStatusCode.ExecutedAndKeptOpen;
    executableHold.value = executableHold.value.sub(value);

    emit HoldExecutedAndKeptOpen(
      token,
      holdId,
      executableHold.notary,
      executableHold.value,
      value,
      secret
    );
  }

  /**
   * @dev Increase held balance.
   */
  function _increaseHeldBalance(address token, Hold storage executableHold, bytes32 holdId) private {
    _heldBalance[token][executableHold.sender] = _heldBalance[token][executableHold.sender].add(executableHold.value);
    _totalHeldBalance[token] = _totalHeldBalance[token].add(executableHold.value);

    _heldBalanceByPartition[token][executableHold.sender][executableHold.partition] = _heldBalanceByPartition[token][executableHold.sender][executableHold.partition].add(executableHold.value);
    _totalHeldBalanceByPartition[token][executableHold.partition] = _totalHeldBalanceByPartition[token][executableHold.partition].add(executableHold.value);

    _increaseNonce(token, executableHold, holdId);
  }

  /**
   * @dev Decrease held balance.
   */
  function _decreaseHeldBalance(address token, Hold storage executableHold, uint256 value) private {
    _heldBalance[token][executableHold.sender] = _heldBalance[token][executableHold.sender].sub(value);
    _totalHeldBalance[token] = _totalHeldBalance[token].sub(value);

    _heldBalanceByPartition[token][executableHold.sender][executableHold.partition] = _heldBalanceByPartition[token][executableHold.sender][executableHold.partition].sub(value);
    _totalHeldBalanceByPartition[token][executableHold.partition] = _totalHeldBalanceByPartition[token][executableHold.partition].sub(value);

    if(executableHold.status == HoldStatusCode.Ordered) {
      _decreaseNonce(token, executableHold);
    }
  }

  /**
   * @dev Increase nonce.
   */
  function _increaseNonce(address token, Hold storage executableHold, bytes32 holdId) private {
    (bytes32 holdHash, uint256 nonce,) = _retrieveHoldHashNonceId(
      token, executableHold.partition,
      executableHold.notary,
      executableHold.sender,
      executableHold.recipient,
      executableHold.value
    );
    _hashNonce[holdHash] = nonce.add(1);
    _holdIds[holdHash][nonce.add(1)] = holdId;
  }

  /**
   * @dev Decrease nonce.
   */
  function _decreaseNonce(address token, Hold storage executableHold) private {
    (bytes32 holdHash, uint256 nonce,) = _retrieveHoldHashNonceId(
      token,
      executableHold.partition,
      executableHold.notary,
      executableHold.sender,
      executableHold.recipient,
      executableHold.value
    );
    _holdIds[holdHash][nonce] = "";
    _hashNonce[holdHash] = _hashNonce[holdHash].sub(1);
  }

  /**
   * @dev Check secret.
   */
  function _checkSecret(Hold storage executableHold, bytes32 secret) internal view returns (bool) {
    if(executableHold.secretHash == sha256(abi.encodePacked(secret))) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Compute expiration time.
   */
  function _computeExpiration(uint256 timeToExpiration) internal view returns (uint256) {
    uint256 expiration = 0;

    if (timeToExpiration != 0) {
        expiration = now.add(timeToExpiration);
    }

    return expiration;
  }

  /**
   * @dev Check expiration time.
   */
  function _checkExpiration(uint256 expiration) private view {
    require(expiration > now || expiration == 0, "Expiration date must be greater than block timestamp or zero");
  }

  /**
   * @dev Check is expiration date is past.
   */
  function _isExpired(uint256 expiration) internal view returns (bool) {
    return expiration != 0 && (now >= expiration);
  }

  /**
   * @dev Retrieve hold hash, nonce, and ID for given parameters
   */
  function _retrieveHoldHashNonceId(address token, bytes32 partition, address notary, address sender, address recipient, uint value) internal view returns (bytes32, uint256, bytes32) {
    // Pack and hash hold parameters
    bytes32 holdHash = keccak256(abi.encodePacked(
      token,
      partition,
      sender,
      recipient,
      notary,
      value
    ));
    uint256 nonce = _hashNonce[holdHash];
    bytes32 holdId = _holdIds[holdHash][nonce];

    return (holdHash, nonce, holdId);
  }  

  /**
   * @dev Check if hold can be executed
   */
  function _holdCanBeExecuted(Hold storage executableHold, uint value) internal view returns (bool) {
    if(!(executableHold.status == HoldStatusCode.Ordered || executableHold.status == HoldStatusCode.ExecutedAndKeptOpen)) {
      return false; // A hold can only be executed in status Ordered or ExecutedAndKeptOpen
    } else if(value == 0) {
      return false; // Value must be greater than zero
    } else if(_isExpired(executableHold.expiration)) {
      return false; // The hold has already expired
    } else if(value > executableHold.value) {
      return false; // The value should be equal or less than the held amount
    } else {
      return true;
    }
  }

  /**
   * @dev Check if hold can be executed as secret holder
   */
  function _holdCanBeExecutedAsSecretHolder(Hold storage executableHold, uint value, bytes32 secret) internal view returns (bool) {
    if(
      _checkSecret(executableHold, secret)
      && _holdCanBeExecuted(executableHold, value)) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Check if hold can be executed as notary
   */
  function _holdCanBeExecutedAsNotary(Hold storage executableHold, address operator, uint value) internal view returns (bool) {
    if(
      executableHold.notary == operator
      && _holdCanBeExecuted(executableHold, value)) {
      return true;
    } else {
      return false;
    }
  }  

  /**
   * @dev Retrieve hold data.
   */
  function retrieveHoldData(address token, bytes32 holdId) external view returns (
    bytes32 partition,
    address sender,
    address recipient,
    address notary,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes32 secret,
    HoldStatusCode status)
  {
    Hold storage retrievedHold = _holds[token][holdId];
    return (
      retrievedHold.partition,
      retrievedHold.sender,
      retrievedHold.recipient,
      retrievedHold.notary,
      retrievedHold.value,
      retrievedHold.expiration,
      retrievedHold.secretHash,
      retrievedHold.secret,
      retrievedHold.status
    );
  }

  /**
   * @dev Total supply on hold.
   */
  function totalSupplyOnHold(address token) external view returns (uint256) {
    return _totalHeldBalance[token];
  }

  /**
   * @dev Total supply on hold for a specific partition.
   */
  function totalSupplyOnHoldByPartition(address token, bytes32 partition) external view returns (uint256) {
    return _totalHeldBalanceByPartition[token][partition];
  }

  /**
   * @dev Get balance on hold of a tokenholder.
   */
  function balanceOnHold(address token, address account) external view returns (uint256) {
    return _heldBalance[token][account];
  }

  /**
   * @dev Get balance on hold of a tokenholder for a specific partition.
   */
  function balanceOnHoldByPartition(address token, bytes32 partition, address account) external view returns (uint256) {
    return _heldBalanceByPartition[token][account][partition];
  }

  /**
   * @dev Get spendable balance of a tokenholder.
   */
  function spendableBalanceOf(address token, address account) external view returns (uint256) {
    return _spendableBalanceOf(token, account);
  }

  /**
   * @dev Get spendable balance of a tokenholder for a specific partition.
   */
  function spendableBalanceOfByPartition(address token, bytes32 partition, address account) external view returns (uint256) {
    return _spendableBalanceOfByPartition(token, partition, account);
  }

  /**
   * @dev Get spendable balance of a tokenholder.
   */
  function _spendableBalanceOf(address token, address account) internal view returns (uint256) {
    return IERC20(token).balanceOf(account) - _heldBalance[token][account];
  }

  /**
   * @dev Get spendable balance of a tokenholder for a specific partition.
   */
  function _spendableBalanceOfByPartition(address token, bytes32 partition, address account) internal view returns (uint256) {
    return IERC1400(token).balanceOfByPartition(partition, account) - _heldBalanceByPartition[token][account][partition];
  }

  /************************** TOKEN CONTROLLERS *******************************/

  /**
   * @dev Check if operator can create pre-holds.
   * @return 'true' if the operator can create pre-holds, 'false' if not.
   */
  function _canPreHold(address token, address operator) internal view returns(bool) { 
    return IMinterRole(token).isMinter(operator);
  }

  /**
   * @dev Check if operator can create/update holds.
   * @return 'true' if the operator can create/update holds, 'false' if not.
   */
  function _canPostHold(address token, bytes32 partition, address operator, address sender) internal view returns(bool) {    
    if (_selfHoldsActivated[token]) {
      return IERC1400(token).isOperatorForPartition(partition, operator, sender);
    } else {
      return _isTokenController[token][operator];
    }
  }


  /**
   * @dev Check if validator is activated for the function called in the smart contract.
   * @param functionSig ID of the function that is called.
   * @return 'true' if the function requires validation, 'false' if not.
   */
  function _functionRequiresValidation(bytes4 functionSig) internal pure returns(bool) {
    if(_areEqual(functionSig, ERC20_TRANSFER_FUNCTION_ID) || _areEqual(functionSig, ERC20_TRANSFERFROM_FUNCTION_ID)) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Check if 2 variables of type bytes4 are identical.
   * @return 'true' if 2 variables are identical, 'false' if not.
   */
  function _areEqual(bytes4 a, bytes4 b) internal pure returns(bool) {
    for (uint256 i = 0; i < a.length; i++) {
      if(a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Check if 'value' is multiple of 'granularity'.
   * @param granularity The granularity that want's to be checked.
   * @param value The quantity that want's to be checked.
   * @return 'true' if 'value' is a multiple of 'granularity'.
   */
  function _isMultiple(uint256 granularity, uint256 value) internal pure returns(bool) {
    return(value.div(granularity).mul(granularity) == value);
  }

}