pragma solidity ^0.4.24;


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


contract ERC1404 is ERC20 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction&#39;s reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string);
}


/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the “License”);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an “AS IS” BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

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


/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the “License”);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an “AS IS” BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.24;



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
  constructor(address _service) public {
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
    emit ReplaceService(oldService, service);
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


/**
   Copyright (c) 2017 Harbor Platform, Inc.

   Licensed under the Apache License, Version 2.0 (the “License”);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an “AS IS” BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.24;







/// @notice An ERC-20 token that has the ability to check for trade validity
contract RegulatedToken is DetailedERC20, MintableToken, BurnableToken {

  /**
   * @notice R-Token decimals setting (used when constructing DetailedERC20)
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
   * @param _name Name of the token: See DetailedERC20
   * @param _symbol Symbol of the token: See DetailedERC20
   */
  constructor(ServiceRegistry _registry, string _name, string _symbol) public
    DetailedERC20(_name, _symbol, RTOKEN_DECIMALS)
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
    require(_from != address(0) && _to != address(0));
    uint8 reason = _service().check(this, msg.sender, _from, _to, _value);

    emit CheckStatus(reason, msg.sender, _from, _to, _value);

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
  function _service() view public returns (RegulatorService) {
    return RegulatorService(registry.service());
  }
}


contract RegulatedTokenERC1404 is ERC1404, RegulatedToken {
    constructor(ServiceRegistry _registry, string _name, string _symbol) public
        RegulatedToken(_registry, _name, _symbol)
    {

    }

   /**
    * @notice Implementing detectTransferRestriction makes this token ERC-1404 compatible
    * 
    * @dev Notice in the call to _service.check(), the 2nd argument is address 0.
    *      This "spender" parameter is unused in Harbor&#39;s own R-Token implementation
    *      and will have to be remain unused for the purposes of our example.
    *
    * @param from The address of the sender
    * @param to The address of the receiver
    * @param value The number of tokens to transfer
    *
    * @return A code that is associated with the reason for a failed check
    */
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8) {
        return _service().check(this, address(0), from, to, value);
    }

   /**
    * @notice Implementing messageForTransferRestriction makes this token ERC-1404 compatible
    *
    * @dev The RegulatorService contract must implement the function messageforReason in this implementation
    * 
    * @param reason The restrictionCode returned from the service check
    *
    * @return The human-readable mesage string
    */
    function messageForTransferRestriction (uint8 reason) public view returns (string) {
        return _service().messageForReason(reason);
    }
}