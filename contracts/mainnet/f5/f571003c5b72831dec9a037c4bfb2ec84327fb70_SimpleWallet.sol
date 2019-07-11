/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

pragma solidity >=0.4.21 <0.6.0;

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */



/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */



/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */


/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */




/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


///@title Custom Ownable
///@notice Custom ownable contract.
contract CustomOwnable is Ownable {
  ///The trustee wallet.
  address private _trustee;

  event TrusteeAssigned(address indexed account);

  ///@notice Validates if the sender is actually the trustee.
  modifier onlyTrustee() {
    require(msg.sender == _trustee, "Access is denied.");
    _;
  }

  ///@notice Assigns or changes the trustee wallet.
  ///@param account A wallet address which will become the new trustee.
  ///@return Returns true if the operation was successful.
  function assignTrustee(address account) external onlyOwner returns(bool) {
    require(account != address(0), "Please provide a valid address for trustee.");

    _trustee = account;
    emit TrusteeAssigned(account);
    return true;
  }

  ///@notice Changes the owner of this contract.
  ///@param newOwner Specify a wallet address which will become the new owner.
  ///@return Returns true if the operation was successful.
  function reassignOwner(address newOwner) external onlyTrustee returns(bool) {
    super._transferOwnership(newOwner);
    return true;
  }

  ///@notice The trustee wallet has the power to change the owner in case of unforeseen or unavoidable situation.
  ///@return Wallet address of the trustee account.
  function getTrustee() external view returns(address) {
    return _trustee;
  }
}

///@title Custom Admin
///@notice Custom admin contract provides features to have multiple administrators
/// who can collective perform admin-related tasks instead of depending on the owner.
/// &nbsp;
/// It is assumed by default that the owner is more power than admins
/// and therefore cannot be added to or removed from the admin list.
contract CustomAdmin is CustomOwnable {
  ///List of administrators.
  mapping(address => bool) private _admins;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  ///@notice Validates if the sender is actually an administrator.
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Access is denied.");
    _;
  }

  ///@notice Adds the specified address to the list of administrators.
  ///@param account The address to add to the administrator list.
  ///@return Returns true if the operation was successful.
  function addAdmin(address account) external onlyAdmin returns(bool) {
    require(account != address(0), "Invalid address.");
    require(!_admins[account], "This address is already an administrator.");

    require(account != super.owner(), "The owner cannot be added or removed to or from the administrator list.");

    _admins[account] = true;

    emit AdminAdded(account);
    return true;
  }

  ///@notice Adds multiple addresses to the administrator list.
  ///@param accounts The account addresses to add to the administrator list.
  ///@return Returns true if the operation was successful.
  function addManyAdmins(address[] calldata accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < accounts.length; i++) {
      address account = accounts[i];

      ///Zero address cannot be an admin.
      ///The owner is already an admin and cannot be assigned.
      ///The address cannot be an existing admin.
      if(account != address(0) && !_admins[account] && account != super.owner()) {
        _admins[account] = true;

        emit AdminAdded(accounts[i]);
      }
    }

    return true;
  }

  ///@notice Removes the specified address from the list of administrators.
  ///@param account The address to remove from the administrator list.
  ///@return Returns true if the operation was successful.
  function removeAdmin(address account) external onlyAdmin returns(bool) {
    require(account != address(0), "Invalid address.");
    require(_admins[account], "This address isn&#39;t an administrator.");

    //The owner cannot be removed as admin.
    require(account != super.owner(), "The owner cannot be added or removed to or from the administrator list.");

    _admins[account] = false;
    emit AdminRemoved(account);
    return true;
  }

  ///@notice Removes multiple addresses to the administrator list.
  ///@param accounts The account addresses to add to the administrator list.
  ///@return Returns true if the operation was successful.
  function removeManyAdmins(address[] calldata accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < accounts.length; i++) {
      address account = accounts[i];

      ///Zero address can neither be added or removed from this list.
      ///The owner is the super admin and cannot be removed.
      ///The address must be an existing admin in order for it to be removed.
      if(account != address(0) && _admins[account] && account != super.owner()) {
        _admins[account] = false;

        emit AdminRemoved(accounts[i]);
      }
    }

    return true;
  }

  ///@notice Checks if an address is an administrator.
  ///@return Returns true if the specified wallet is infact an administrator.
  function isAdmin(address account) public view returns(bool) {
    if(account == super.owner()) {
      //The owner has all rights and privileges assigned to the admins.
      return true;
    }

    return _admins[account];
  }
}

///@title Custom Pausable Contract
///@notice This contract provides pausable mechanism to stop in case of emergency.
/// The "pausable" features can be used and set by the contract administrators
/// and the owner.
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool private _paused = false;

  ///@notice Ensures that the contract is not paused.
  modifier whenNotPaused() {
    require(!_paused, "Sorry but the contract is paused.");
    _;
  }

  ///@notice Ensures that the contract is paused.
  modifier whenPaused() {
    require(_paused, "Sorry but the contract isn&#39;t paused.");
    _;
  }

  ///@notice Pauses the contract.
  function pause() external onlyAdmin whenNotPaused {
    _paused = true;
    emit Paused();
  }

  ///@notice Unpauses the contract and returns to normal state.
  function unpause() external onlyAdmin whenPaused {
    _paused = false;
    emit Unpaused();
  }

  ///@notice Indicates if the contract is paused.
  ///@return Returns true if this contract is paused.
  function isPaused() external view returns(bool) {
    return _paused;
  }
}
/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */







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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
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
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
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



/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
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
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
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
 * these events, as it isn&#39;t required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
     * - the caller must have allowance for `sender`&#39;s tokens of at least
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
     * @dev Destoys `amount` tokens from `account`, reducing the
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
     * from the caller&#39;s allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}







/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract&#39;s constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity&#39;s return data size checking mechanism, since
        // we&#39;re implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */





///@title Capped Transfer
///@author Binod Nirvan
///@notice The capped transfer contract outlines the rules on the maximum amount of ERC20 or Ether transfer for each transaction.
contract CappedTransfer is CustomPausable {
  event CapChanged(uint256 maximumTransfer, uint256 maximumTransferWei, uint256 oldMaximumTransfer, uint256 oldMaximumTransferWei);

  //Zero means unlimited transfer
  uint256 private _maximumTransfer = 0;
  uint256 private _maximumTransferWei = 0;

  ///@notice Ensures that the requested ERC20 transfer amount is within the maximum allowed limit.
  ///@param amount The amount being requested to be transferred out of this contract.
  ///@return Returns true if the transfer request is valid and acceptable.
  function checkIfValidTransfer(uint256 amount) public view returns(bool) {
    require(amount > 0, "Access is denied.");

    if(_maximumTransfer > 0) {
      require(amount <= _maximumTransfer, "Sorry but the amount you&#39;re transferring is too much.");
    }

    return true;
  }

  ///@notice Ensures that the requested wei transfer amount is within the maximum allowed limit.
  ///@param amount The Ether wei unit amount being requested to be transferred out of this contract.
  ///@return Returns true if the transfer request is valid and acceptable.
  function checkIfValidWeiTransfer(uint256 amount) public view returns(bool) {
    require(amount > 0, "Access is denied.");

    if(_maximumTransferWei > 0) {
      require(amount <= _maximumTransferWei, "Sorry but the amount you&#39;re transferring is too much.");
    }

    return true;
  }

  ///@notice Sets the maximum cap for a single ERC20 and Ether transfer.
  ///@return Returns true if the operation was successful.
  function setCap(uint256 cap, uint256 weiCap) external onlyOwner whenNotPaused returns(bool) {
    emit CapChanged(cap, weiCap, _maximumTransfer, _maximumTransferWei);

    _maximumTransfer = cap;
    _maximumTransferWei = weiCap;
    return true;
  }

  ///@notice Gets the transfer cap defined in this contract.
  ///@return Returns maximum allowed value for a single transfer operation of ERC20 token and Ethereum.
  function getCap() external view returns(uint256, uint256) {
    return (_maximumTransfer, _maximumTransferWei);
  }
}

///@title Transfer Base Contract
///@author Binod Nirvan
///@notice The base contract which contains features related to token transfers.
contract TransferBase is CappedTransfer {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event TransferPerformed(address indexed token, address indexed transferredBy, address indexed destination, uint256 amount);
  event EtherTransferPerformed(address indexed transferredBy, address indexed destination, uint256 amount);

  ///@notice Allows the sender to transfer tokens to the beneficiary.
  ///@param token The ERC20 token to transfer.
  ///@param destination The destination wallet address to send funds to.
  ///@param amount The amount of tokens to send to the specified address.
  ///@return Returns true if the operation was successful.
  function transferTokens(address token, address destination, uint256 amount)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(checkIfValidTransfer(amount), "Access is denied.");

    ERC20 erc20 = ERC20(token);

    require
    (
      erc20.balanceOf(address(this)) >= amount,
      "You don&#39;t have sufficient funds to transfer amount that large."
    );


    erc20.safeTransfer(destination, amount);


    emit TransferPerformed(token, msg.sender, destination, amount);
    return true;
  }

  ///@notice Allows the sender to transfer Ethers to the beneficiary.
  ///@param destination The destination wallet address to send funds to.
  ///@param amount The amount of Ether in wei to send to the specified address.
  ///@return Returns true if the operation was successful.
  function transferEthers(address payable destination, uint256 amount)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(checkIfValidWeiTransfer(amount), "Access is denied.");

    require
    (
      address(this).balance >= amount,
      "You don&#39;t have sufficient funds to transfer amount that large."
    );


    destination.transfer(amount);


    emit EtherTransferPerformed(msg.sender, destination, amount);
    return true;
  }

  ///@return Returns balance of the ERC20 token held by this contract.
  function tokenBalanceOf(address token) external view returns(uint256) {
    ERC20 erc20 = ERC20(token);
    return erc20.balanceOf(address(this));
  }

  ///@notice Accepts incoming funds
  function () external payable whenNotPaused {
    //nothing to do
  }
}

///@title Bulk Transfer Contract
///@author Binod Nirvan
///@notice The bulk transfer contract enables administrators to transfer an ERC20 token
/// or Ethereum in batches. Every single feature of this contract is strictly restricted to be used by admin(s) only.
contract BulkTransfer is TransferBase {
  event BulkTransferPerformed(address indexed token, address indexed transferredBy, uint256 length, uint256 totalAmount);
  event EtherBulkTransferPerformed(address indexed transferredBy, uint256 length, uint256 totalAmount);

  ///@notice Creates a sum total of the supplied values.
  ///@param values The collection of values to create the sum from.
  ///@return Returns the sum total of the supplied values.
  function sumOf(uint256[] memory values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < values.length; i++) {
      total = total.add(values[i]);
    }

    return total;
  }


  ///@notice Allows the requester to perform ERC20 bulk transfer operation.
  ///@param token The ERC20 token to bulk transfer.
  ///@param destinations The destination wallet addresses to send funds to.
  ///@param amounts The respective amount of funds to send to the specified addresses.
  ///@return Returns true if the operation was successful.
  function bulkTransfer(address token, address[] calldata destinations, uint256[] calldata amounts)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(destinations.length == amounts.length, "Invalid operation.");

    //Saving gas by first determining if the sender actually has sufficient balance
    //to post this transaction.
    uint256 requiredBalance = sumOf(amounts);

    //Verifying whether or not this transaction exceeds the maximum allowed ERC20 transfer cap.
    require(checkIfValidTransfer(requiredBalance), "Access is denied.");

    ERC20 erc20 = ERC20(token);

    require
    (
      erc20.balanceOf(address(this)) >= requiredBalance,
      "You don&#39;t have sufficient funds to transfer amount this big."
    );


    for (uint256 i = 0; i < destinations.length; i++) {
      erc20.safeTransfer(destinations[i], amounts[i]);
    }

    emit BulkTransferPerformed(token, msg.sender, destinations.length, requiredBalance);
    return true;
  }


  ///@notice Allows the requester to perform Ethereum bulk transfer operation.
  ///@param destinations The destination wallet addresses to send funds to.
  ///@param amounts The respective amount of funds to send to the specified addresses.
  ///@return Returns true if the operation was successful.
  function bulkTransferEther(address[] calldata destinations, uint256[] calldata amounts)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(destinations.length == amounts.length, "Invalid operation.");

    //Saving gas by first determining if the sender actually has sufficient balance
    //to post this transaction.
    uint256 requiredBalance = sumOf(amounts);

    //Verifying whether or not this transaction exceeds the maximum allowed Ethereum transfer cap.
    require(checkIfValidWeiTransfer(requiredBalance), "Access is denied.");

    require
    (
      address(this).balance >= requiredBalance,
      "You don&#39;t have sufficient funds to transfer amount this big."
    );


    for (uint256 i = 0; i < destinations.length; i++) {
      address payable beneficiary = address(uint160(destinations[i]));
      beneficiary.transfer(amounts[i]);
    }


    emit EtherBulkTransferPerformed(msg.sender, destinations.length, requiredBalance);
    return true;
  }
}
/*
Copyright 2018 Binod Nirvan
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/








///@title Reclaimable Contract
///@author Binod Nirvan
///@notice Reclaimable contract enables the owner
///to reclaim accidentally sent Ethers and ERC20 token(s)
///to this contract.
contract Reclaimable is CustomPausable {
  using SafeERC20 for ERC20;

  ///@notice Transfers all Ether held by the contract to the caller.
  function reclaimEther() external whenNotPaused onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  ///@notice Transfers all ERC20 tokens held by the contract to the caller.
  ///@param token The amount of token to reclaim.
  function reclaimToken(address token) external whenNotPaused onlyOwner {
    ERC20 erc20 = ERC20(token);
    uint256 balance = erc20.balanceOf(address(this));
    erc20.safeTransfer(msg.sender, balance);
  }
}

contract SimpleWallet is BulkTransfer, Reclaimable {
}