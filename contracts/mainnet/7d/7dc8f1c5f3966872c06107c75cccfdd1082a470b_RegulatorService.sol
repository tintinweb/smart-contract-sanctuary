pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

/// @notice Standard interface for `RegulatorService`s
contract RegulatorServiceI {

  /*
   * @notice This method *MUST* be called by `RegulatedToken`s during `transfer()` and `transferFrom()`.
   *         The implementation *SHOULD* check whether or not a transfer can be approved.
   *
   * @dev    This method *MAY* call back to the token contract specified by `_token` for
   *         more information needed to enforce trade approval.
   *
   * @param  _token The address of the token to be transfered
   * @param  _spender The address of the spender of the token
   * @param  _from The address of the sender account
   * @param  _to The address of the receiver account
   * @param  _amount The quantity of the token to trade
   *
   * @return uint8 The reason code: 0 means success.  Non-zero values are left to the implementation
   *               to assign meaning.
   */
  function check(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8);
}


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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


/**
 * @title  On-chain RegulatorService implementation for approving trades
 * @author Originally Bob Remeika, modified by TokenSoft Inc
 * @dev Orignal source: https://github.com/harborhq/r-token/blob/master/contracts/TokenRegulatorService.sol
 */
contract RegulatorService is RegulatorServiceI, Ownable {
  /**
   * @dev Throws if called by any account other than the admin
   */
  modifier onlyAdmins() {
    require(msg.sender == admin || msg.sender == owner);
    _;
  }

  /// @dev Settings that affect token trading at a global level
  struct Settings {

    /**
     * @dev Toggle for locking/unlocking trades at a token level.
     *      The default behavior of the zero memory state for locking will be unlocked.
     */
    bool locked;

    /**
     * @dev Toggle for allowing/disallowing fractional token trades at a token level.
     *      The default state when this contract is created `false` (or no partial
     *      transfers allowed).
     */
    bool partialTransfers;
  }

  // @dev Check success code & message
  uint8 constant private CHECK_SUCCESS = 0;
  string constant private SUCCESS_MESSAGE = &#39;Success&#39;;

  // @dev Check error reason: Token is locked
  uint8 constant private CHECK_ELOCKED = 1;
  string constant private ELOCKED_MESSAGE = &#39;Token is locked&#39;;

  // @dev Check error reason: Token can not trade partial amounts
  uint8 constant private CHECK_EDIVIS = 2;
  string constant private EDIVIS_MESSAGE = &#39;Token can not trade partial amounts&#39;;

  // @dev Check error reason: Sender is not allowed to send the token
  uint8 constant private CHECK_ESEND = 3;
  string constant private ESEND_MESSAGE = &#39;Sender is not allowed to send the token&#39;;

  // @dev Check error reason: Receiver is not allowed to receive the token
  uint8 constant private CHECK_ERECV = 4;
  string constant private ERECV_MESSAGE = &#39;Receiver is not allowed to receive the token&#39;;

  /// @dev Permission bits for allowing a participant to send tokens
  uint8 constant private PERM_SEND = 0x1;

  /// @dev Permission bits for allowing a participant to receive tokens
  uint8 constant private PERM_RECEIVE = 0x2;

  // @dev Address of the administrator
  address public admin;

  /// @notice Permissions that allow/disallow token trades on a per token level
  mapping(address => Settings) private settings;

  /// @dev Permissions that allow/disallow token trades on a per participant basis.
  ///      The format for key based access is `participants[tokenAddress][participantAddress]`
  ///      which returns the permission bits of a participant for a particular token.
  mapping(address => mapping(address => uint8)) private participants;

  /// @dev Event raised when a token&#39;s locked setting is set
  event LogLockSet(address indexed token, bool locked);

  /// @dev Event raised when a token&#39;s partial transfer setting is set
  event LogPartialTransferSet(address indexed token, bool enabled);

  /// @dev Event raised when a participant permissions are set for a token
  event LogPermissionSet(address indexed token, address indexed participant, uint8 permission);

  /// @dev Event raised when the admin address changes
  event LogTransferAdmin(address indexed oldAdmin, address indexed newAdmin);

  constructor() public {
    admin = msg.sender;
  }

  /**
   * @notice Locks the ability to trade a token
   *
   * @dev    This method can only be called by this contract&#39;s owner
   *
   * @param  _token The address of the token to lock
   */
  function setLocked(address _token, bool _locked) onlyOwner public {
    settings[_token].locked = _locked;

    emit LogLockSet(_token, _locked);
  }

  /**
   * @notice Allows the ability to trade a fraction of a token
   *
   * @dev    This method can only be called by this contract&#39;s owner
   *
   * @param  _token The address of the token to allow partial transfers
   */
  function setPartialTransfers(address _token, bool _enabled) onlyOwner public {
   settings[_token].partialTransfers = _enabled;

   emit LogPartialTransferSet(_token, _enabled);
  }

  /**
   * @notice Sets the trade permissions for a participant on a token
   *
   * @dev    The `_permission` bits overwrite the previous trade permissions and can
   *         only be called by the contract&#39;s owner.  `_permissions` can be bitwise
   *         `|`&#39;d together to allow for more than one permission bit to be set.
   *
   * @param  _token The address of the token
   * @param  _participant The address of the trade participant
   * @param  _permission Permission bits to be set
   */
  function setPermission(address _token, address _participant, uint8 _permission) onlyAdmins public {
    participants[_token][_participant] = _permission;

    emit LogPermissionSet(_token, _participant, _permission);
  }

  /**
   * @dev Allows the owner to transfer admin controls to newAdmin.
   *
   * @param newAdmin The address to transfer admin rights to.
   */
  function transferAdmin(address newAdmin) onlyOwner public {
    require(newAdmin != address(0));

    address oldAdmin = admin;
    admin = newAdmin;

    emit LogTransferAdmin(oldAdmin, newAdmin);
  }

  /**
   * @notice Checks whether or not a trade should be approved
   *
   * @dev    This method calls back to the token contract specified by `_token` for
   *         information needed to enforce trade approval if needed
   *
   * @param  _token The address of the token to be transfered
   * @param  _spender The address of the spender of the token (unused in this implementation)
   * @param  _from The address of the sender account
   * @param  _to The address of the receiver account
   * @param  _amount The quantity of the token to trade
   *
   * @return `true` if the trade should be approved and `false` if the trade should not be approved
   */
  function check(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8) {
    if (settings[_token].locked) {
      return CHECK_ELOCKED;
    }

    if (participants[_token][_from] & PERM_SEND == 0) {
      return CHECK_ESEND;
    }

    if (participants[_token][_to] & PERM_RECEIVE == 0) {
      return CHECK_ERECV;
    }

    if (!settings[_token].partialTransfers && _amount % _wholeToken(_token) != 0) {
      return CHECK_EDIVIS;
    }

    return CHECK_SUCCESS;
  }

  /**
   * @notice Returns the error message for a passed failed check reason
   *
   * @param  _reason The reason code: 0 means success.  Non-zero values are left to the implementation
   *                 to assign meaning.
   *
   * @return The human-readable mesage string
   */
  function messageForReason (uint8 _reason) public pure returns (string) {
    if (_reason == CHECK_ELOCKED) {
      return ELOCKED_MESSAGE;
    }
    
    if (_reason == CHECK_ESEND) {
      return ESEND_MESSAGE;
    }

    if (_reason == CHECK_ERECV) {
      return ERECV_MESSAGE;
    }

    if (_reason == CHECK_EDIVIS) {
      return EDIVIS_MESSAGE;
    }

    return SUCCESS_MESSAGE;
  }

  /**
   * @notice Retrieves the whole token value from a token that this `RegulatorService` manages
   *
   * @param  _token The token address of the managed token
   *
   * @return The uint256 value that represents a single whole token
   */
  function _wholeToken(address _token) view private returns (uint256) {
    return uint256(10)**DetailedERC20(_token).decimals();
  }
}