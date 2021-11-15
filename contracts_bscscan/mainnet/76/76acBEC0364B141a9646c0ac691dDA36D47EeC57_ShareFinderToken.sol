/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */

pragma solidity ^0.5.3;

import "./zeppelin/math/SafeMath.sol";
import "./zeppelin/token/ERC20/ERC20.sol";
import "./zeppelin/lifecycle/Pausable.sol";
import "./zeppelin/ownership/Ownable.sol";
import "./interface/IIssuable.sol";
import "./interface/IRedeemable.sol";
import "./interface/IDestroyable.sol";
import "./interface/IReassignable.sol";
import "./interface/IIdentifiable.sol";
import "./interface/IContactable.sol";
import "./interface/IRuleEngine.sol";

/**
 * @title CMTA20
 * @dev CMTA20 contract
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 * errors:
 * CM01: Attempt to reassign from an original address which is 0x0
 * CM02: Attempt to reassign to a replacement address is 0x0
 * CM03: Attempt to reassign to replacement address which is the same as the original address
 * CM04: Transfer rejected by Rule Engine 
 * CM05: Attempt to reassign from an original address which does not have any tokens
 * CM06: Cannot call destroy with owner address contained in parameter
 */

//IDestroyable
//IReassignable
 
contract ShareFinderToken is ERC20, Ownable, Pausable, IContactable, IIdentifiable, IIssuable, IRedeemable  {
  using SafeMath for uint256;

  /* Constants */
  uint8 constant TRANSFER_OK = 0;
  uint8 constant TRANSFER_REJECTED_PAUSED = 1;

  string constant TEXT_TRANSFER_OK = "No restriction";
  string constant TEXT_TRANSFER_REJECTED_PAUSED = "All transfers paused";

  string public name;
  string public symbol;
  string public contact;
  mapping (address => bytes) internal identities;
  IRuleEngine public ruleEngine;

  // solium-disable-next-line uppercase
  uint8 constant public decimals = 0;

  constructor(string memory _name, string memory _symbol, string memory _contact) public {
    name = _name;
    symbol = _symbol;
    contact = _contact;
  }

  /**
  * Purpose:
  * This event is emitted when rule engine is changed
  *
  * @param newRuleEngine - new rule engine address
  */
  event LogRuleEngineSet(address indexed newRuleEngine);
  /**
  * Purpose:
  * This event is emitted when the contact information is changed
  *
  * @param contact - new contact information
  */
  event LogContactSet(string contact);

  /**
  * Purpose
  * Set optional rule engine by owner
  * 
  * @param _ruleEngine - the rule engine that will approve/reject transfers
  */
  function setRuleEngine(IRuleEngine _ruleEngine) external onlyOwner {
    ruleEngine = _ruleEngine;
    emit LogRuleEngineSet(address(_ruleEngine));
  }

  /**
  * Purpose
  * Set contact point for shareholders
  * 
  * @param _contact - the contact information for the shareholders
  */
  function setContact(string calldata _contact) external onlyOwner {
    contact = _contact;
    emit LogContactSet(_contact);
  }

  /**
  * Purpose
  * Retrieve identity of a potential/actual shareholder
  */
  function identity(address shareholder) external view returns (bytes memory) {
    return identities[shareholder];
  }

  /**
  * Purpose
  * Set identity of a potential/actual shareholder. Can only be called by the potential/actual shareholder himself. Has to be encrypted data.
  * 
  * @param _identity - the potential/actual shareholder identity
  */
  function setMyIdentity(bytes calldata _identity) external {
    identities[msg.sender] = _identity;
  }

  /**
  * Purpose:
  * Issue tokens on the owner address
  *
  * @param _value - amount of newly issued tokens
  */
  function issue(uint256 _value) public onlyOwner {
    _balances[owner] = _balances[owner].add(_value);
    _totalSupply = _totalSupply.add(_value);

    emit Transfer(address(0), owner, _value);
    emit LogIssued(_value);
  }

  /**
  * Purpose:
  * Redeem tokens on the owner address
  *
  * @param _value - amount of redeemed tokens
  */
  function redeem(uint256 _value) public onlyOwner {
    _balances[owner] = _balances[owner].sub(_value);
    _totalSupply = _totalSupply.sub(_value);

    emit Transfer(owner, address(0), _value);
    emit LogRedeemed(_value);
  }


  /**
    * Purpose:
    * Redeem tokens on the owner address
    *
    * @param value - amount of tokens to burn
    */
    function burn(uint256 value)  public whenNotPaused  {

     return _burn(msg.sender, value);
    }


  /**
  * @dev check if _value token can be transferred from _from to _to
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  */
  function canTransfer(address _from, address _to, uint256 _value) public view returns (bool) {
    if (paused()) {
      return false;
    }
    if (address(ruleEngine) != address(0)) {
      return ruleEngine.validateTransfer(_from, _to, _value);
    }
    return true;
  }

  /**
  * @dev check if _value token can be transferred from _from to _to
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  * @return code of the rejection reason
  */
  function detectTransferRestriction (address _from, address _to, uint256 _value) public view returns (uint8) {
    if (paused()) {
      return TRANSFER_REJECTED_PAUSED;
    }
    if (address(ruleEngine) != address(0)) {
      return ruleEngine.detectTransferRestriction(_from, _to, _value);
    }
    return TRANSFER_OK;
  }

  /**
  * @dev returns the human readable explaination corresponding to the error code returned by detectTransferRestriction
  * @param _restrictionCode The error code returned by detectTransferRestriction
  * @return The human readable explaination corresponding to the error code returned by detectTransferRestriction
  */
  function messageForTransferRestriction (uint8 _restrictionCode) external view returns (string memory) {
    if (_restrictionCode == TRANSFER_OK) {
      return TEXT_TRANSFER_OK;
    } else if (_restrictionCode == TRANSFER_REJECTED_PAUSED) {
      return TEXT_TRANSFER_REJECTED_PAUSED;
    } else if (address(ruleEngine) != address(0)) {
      return ruleEngine.messageForTransferRestriction(_restrictionCode);
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    if (address(ruleEngine) != address(0)) {
      require(ruleEngine.validateTransfer(msg.sender, _to, _value), "CM04");
      return super.transfer(_to, _value);
    } else {
      return super.transfer(_to, _value);
    }
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    if (address(ruleEngine) != address(0)) {
      require(ruleEngine.validateTransfer(_from, _to, _value), "CM04");
      return super.transferFrom(_from, _to, _value);
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public whenNotPaused returns (bool)
  {
    return super.increaseAllowance(_spender, _addedValue);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool)
  {
    return super.decreaseAllowance(_spender, _subtractedValue);
  }

  /**
  * Purpose:
  * To withdraw tokens from the original address and
  * transfer those tokens to the replacement address.
  * Use in cases when e.g. investor loses access to his account.
  *
  * ShareFinderInterjection - DO WE WANT THIS???
  * Conditions:
  * Throw error if the `original` address supplied is not a shareholder.
  * Only issuer can execute this function.
  *
  * @param original - original address
  * @param replacement - replacement address
  
  function reassign(address original, address replacement) external onlyOwner whenNotPaused {
    require(original != address(0), "CM01");
    require(replacement != address(0), "CM02");
    require(original != replacement, "CM03");
    uint256 originalBalance = _balances[original];
    require(originalBalance != 0, "CM05");
    _balances[replacement] = _balances[replacement].add(originalBalance);
    _balances[original] = 0;
    emit Transfer(original, replacement, originalBalance);
    emit LogReassigned(original, replacement, originalBalance);
  }
    */

  /**
  * Purpose;
  * To destroy issued tokens.
  *
  * Conditions:
  * Only issuer can execute this function.
  *
  * ShareFinder - Do we need this?? Remove...
  *
  * @param shareholders - list of shareholders
  
  function destroy(address[] calldata shareholders) external onlyOwner {
    for (uint256 i = 0; i<shareholders.length; i++) {
      require(shareholders[i] != owner, "CM06");
      uint256 shareholderBalance = _balances[shareholders[i]];
      _balances[owner] = _balances[owner].add(shareholderBalance);
      _balances[shareholders[i]] = 0;
      emit Transfer(shareholders[i], owner, shareholderBalance);
    }
    emit LogDestroyed(shareholders);
  }
  */
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */

pragma solidity ^0.5.3;

/**
 * @title IContactable
 * @dev IContactable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/


interface IContactable {
  function contact() external view returns (string memory);
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */

pragma solidity ^0.5.3;

/**
 * @title IDestroyable
 * @dev IDestroyable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/
 

interface IDestroyable {
  /**
  * Purpose;
  * To destroy issued tokens.
  *
  * Conditions:
  * Only issuer can execute this function.
  *
  * @param shareholders - list of shareholders
  */
  function destroy(address[] calldata shareholders) external;

  /**
  * Purpose:
  * This event is emitted when issued tokens are destroyed.
  *
  * @param shareholders - list of shareholders of destroyed tokens
  */
  event LogDestroyed(address[] shareholders);
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;

/**
 * @title IIdentifiable
 * @dev IIdentifiable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/


interface IIdentifiable {
  function identity(address shareholder) external view returns (bytes memory);
  function setMyIdentity(bytes calldata _identity) external;
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;

/**
 * @title IIssuable
 * @dev IIssuable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/


interface IIssuable {
  function issue(uint256 value) external;
  /**
  * Purpose:
  * This event is emitted when new tokens are issued.
  *
  * @param value - amount of newly issued tokens
  */
  event LogIssued(uint256 value);
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;

/**
 * @title IReassignable
 * @dev IReassignable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/
 

interface IReassignable {
  /**
  * Purpose:
  * To withdraw tokens from the original address and
  * transfer those tokens to the replacement address.
  * Use in cases when e.g. investor loses access to his account.
  *
  * Conditions:
  * Throw error if the `original` address supplied is not a shareholder.
  * Throw error if the 'replacement' address already holds tokens.
  * Original address MUST NOT be reused again.
  * Only issuer can execute this function.
  *
  * @param original - original address
  * @param replacement - replacement address
    */
  function reassign(
    address original,
    address replacement
  ) 
    external;

  /**
  * Purpose:
  * This event is emitted when tokens are withdrawn from one address
  * and issued to a new one.
  *
  * @param original - original address
  * @param replacement - replacement address
  * @param value - amount transfered from original to replacement
  */
  event LogReassigned(
    address indexed original,
    address indexed replacement,
    uint256 value
  );
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;

/**
 * @title IRedeemable
 * @dev IRedeemable interface
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 **/


interface IRedeemable {
  function redeem(uint256 value) external;

  /**
  * Purpose:
  * This event is emitted when tokens are redeemed.
  *
  * @param value - amount of redeemed tokens
  */
  event LogRedeemed(uint256 value);
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */

pragma solidity ^0.5.3;

/**
 * @title IRule
 * @dev IRule interface.
 **/
interface IRule {
  function isTransferValid(
    address _from, address _to, uint256 _amount)
  external view returns (bool isValid);

  function detectTransferRestriction(
    address _from, address _to, uint256 _amount)
  external view returns (uint8);

  function canReturnTransferRestrictionCode(uint8 _restrictionCode) external view returns (bool);
  function messageForTransferRestriction(uint8 _restrictionCode) external view returns (string memory);
}

/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;


import "./IRule.sol";

/**
 * @title IRuleEngine
 * @dev IRuleEngine 
 **/


interface IRuleEngine {

  function setRules(IRule[] calldata rules) external;
  function ruleLength() external view returns (uint256);
  function rule(uint256 ruleId) external view returns (IRule);
  function rules() external view returns(IRule[] memory);

  function validateTransfer(
    address _from,
    address _to,
    uint256 _amount)
  external view returns (bool);

  function detectTransferRestriction (
    address _from,
    address _to,
    uint256 _value)
  external view returns (uint8);

  function messageForTransferRestriction (uint8 _restrictionCode) external view returns (string memory);
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "../Roles.sol";

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity ^0.5.0;

import "../access/roles/PauserRole.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * errors
 * OW01: Sender is not owner
 * OW02: Trying to set owner to 0x0
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

