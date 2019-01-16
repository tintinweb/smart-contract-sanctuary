pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
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
  function isOwner() public view returns(bool) {
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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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
   * @dev remove an account&#39;s access to this role
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
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

// File: contracts/RegulatorService.sol

/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the &#212;&#199;&#163;License&#212;&#199;&#216;);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an &#212;&#199;&#163;AS IS&#212;&#199;&#216; BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.18;

/// @notice Standard interface for `RegulatorService`s
contract RegulatorService {

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

// File: contracts/ServiceRegistry.sol

/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the &#212;&#199;&#163;License&#212;&#199;&#216;);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an &#212;&#199;&#163;AS IS&#212;&#199;&#216; BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.18;



/// @notice A service that points to a `RegulatorService`
contract ServiceRegistry is Ownable {
  address public service;

  /**
   * @notice Triggered when service address is replaced
   */
  event ReplaceService(address oldService, address newService);

  /**
   * @dev Validate contract address
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   *
   * @param _addr The address of a smart contract
   */
  modifier withContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0);
    _;
  }

  /**
   * @notice Constructor
   *
   * @param _service The address of the `RegulatorService`
   *
   */
  function ServiceRegistry(address _service) public {
    service = _service;
  }

  /**
   * @notice Replaces the address pointer to the `RegulatorService`
   *
   * @dev This method is only callable by the contract&#39;s owner
   *
   * @param _service The address of the new `RegulatorService`
   */
  function replaceService(address _service) onlyOwner withContract(_service) public {
    address oldService = service;
    service = _service;
    ReplaceService(oldService, service);
  }
}

// File: contracts/RegulatedToken.sol

/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the &#212;&#199;&#163;License&#212;&#199;&#216;);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an &#212;&#199;&#163;AS IS&#212;&#199;&#216; BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.18;





/// @notice An ERC-20 token that has the ability to check for trade validity
contract RegulatedToken is ERC20Detailed, ERC20Mintable {

  /**
   * @notice R-Token decimals setting (used when constructing ERC20Detailed)
   */
  uint8 constant public RTOKEN_DECIMALS = 18;

  /**
   * @notice Triggered when regulator checks pass or fail
   */
  event CheckStatus(uint8 reason, address indexed spender, address indexed from, address indexed to, uint256 value);

  /**
   * @notice Address of the `ServiceRegistry` that has the location of the
   *         `RegulatorService` contract responsible for checking trade
   *         permissions.
   */
  ServiceRegistry public registry;

  /**
   * @notice Constructor
   *
   * @param _registry Address of `ServiceRegistry` contract
   * @param _name Name of the token: See ERC20Detailed
   * @param _symbol Symbol of the token: See ERC20Detailed
   */
  function RegulatedToken(ServiceRegistry _registry, string _name, string _symbol) public
    ERC20Detailed(_name, _symbol, RTOKEN_DECIMALS)
  {
    require(_registry != address(0));

    registry = _registry;
  }

  /**
   * @notice ERC-20 overridden function that include logic to check for trade validity.
   *
   * @param _to The address of the receiver
   * @param _value The number of tokens to transfer
   *
   * @return `true` if successful and `false` if unsuccessful
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (_check(msg.sender, _to, _value)) {
      return super.transfer(_to, _value);
    } else {
      return false;
    }
  }

  /**
   * @notice ERC-20 overridden function that include logic to check for trade validity.
   *
   * @param _from The address of the sender
   * @param _to The address of the receiver
   * @param _value The number of tokens to transfer
   *
   * @return `true` if successful and `false` if unsuccessful
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (_check(_from, _to, _value)) {
      return super.transferFrom(_from, _to, _value);
    } else {
      return false;
    }
  }

  /**
   * @notice Performs the regulator check
   *
   * @dev This method raises a CheckStatus event indicating success or failure of the check
   *
   * @param _from The address of the sender
   * @param _to The address of the receiver
   * @param _value The number of tokens to transfer
   *
   * @return `true` if the check was successful and `false` if unsuccessful
   */
  function _check(address _from, address _to, uint256 _value) private returns (bool) {
    var reason = _service().check(this, msg.sender, _from, _to, _value);

    CheckStatus(reason, msg.sender, _from, _to, _value);

    return reason == 0;
  }

  /**
   * @notice Retreives the address of the `RegulatorService` that manages this token.
   *
   * @dev This function *MUST NOT* memoize the `RegulatorService` address.  This would
   *      break the ability to upgrade the `RegulatorService`.
   *
   * @return The `RegulatorService` that manages this token.
   */
  function _service() constant public returns (RegulatorService) {
    return RegulatorService(registry.service());
  }
}

// File: contracts\TokenRegulatorService.sol

/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the &#212;&#199;&#163;License&#212;&#199;&#216;);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an &#212;&#199;&#163;AS IS&#212;&#199;&#216; BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.18;





/**
 * @title  On-chain RegulatorService implementation for approving trades
 * @author Bob Remeika
 */
contract TokenRegulatorService is RegulatorService, Ownable {
  /**
   * @dev Throws if called by any account other than the admin
   */
  modifier onlyAdmins() {
    require(msg.sender == admin || msg.sender == owner());
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

  // @dev Check success code
  uint8 constant private CHECK_SUCCESS = 0;

  // @dev Check error reason: Token is locked
  uint8 constant private CHECK_ELOCKED = 1;

  // @dev Check error reason: Token can not trade partial amounts
  uint8 constant private CHECK_EDIVIS = 2;

  // @dev Check error reason: Sender is not allowed to send the token
  uint8 constant private CHECK_ESEND = 3;

  // @dev Check error reason: Receiver is not allowed to receive the token
  uint8 constant private CHECK_ERECV = 4;

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

  function TokenRegulatorService() public {
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

    LogLockSet(_token, _locked);
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

   LogPartialTransferSet(_token, _enabled);
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

    LogPermissionSet(_token, _participant, _permission);
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

    LogTransferAdmin(oldAdmin, newAdmin);
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
   * @notice Retrieves the whole token value from a token that this `RegulatorService` manages
   *
   * @param  _token The token address of the managed token
   *
   * @return The uint256 value that represents a single whole token
   */
  function _wholeToken(address _token) view private returns (uint256) {
    return uint256(10)**ERC20Detailed(_token).decimals();
  }
}