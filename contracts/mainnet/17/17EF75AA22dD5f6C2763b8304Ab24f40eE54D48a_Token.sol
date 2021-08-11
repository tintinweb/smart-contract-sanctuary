/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    *
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
    *
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return sub(a, b, "SafeMath: subtraction overflow");
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b <= a, errorMessage);
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
    *
    * - Multiplication cannot overflow.
    */
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
       // benefit is lost if 'b' is also tested.
       // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    *
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       return div(a, b, "SafeMath: division by zero");
   }

   /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b > 0, errorMessage);
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
    *
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return mod(a, b, "SafeMath: modulo by zero");
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b != 0, errorMessage);
       return a % b;
   }
}
// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/




/**
* @dev Interface of the ERC20 standard as defined in the EIP.
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
    * Emits a {Transfer} event.
    */
   function transfer(address recipient, uint256 amount) external returns (bool);

   /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
   function allowance(address owner, address spender) external view returns (uint256);

   /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
   function approve(address spender, uint256 amount) external returns (bool);

   /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
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
    * a call to {approve}. `value` is the new allowance.
    */
   event Approval(address indexed owner, address indexed spender, uint256 value);
}
// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/




/*
* @dev Provides information about the current execution context, including the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with GSN meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*
* This contract is only required for intermediate, library-like contracts.
*/
abstract contract Context {
   function _msgSender() internal view virtual returns (address payable) {
       return msg.sender;
   }

   function _msgData() internal view virtual returns (bytes memory) {
       this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
       return msg.data;
   }
}
// Copyright (c) 2019-2020 revolutionpopuli.com

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.





// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/





/**
* @dev Contract module which provides a basic access control mechanism, where
* there is an account (an owner) that can be granted exclusive access to
* specific functions.
*
* By default, the owner account will be the one that deploys the contract. This
* can later be changed with {transferOwnership}.
*
* This module is used through inheritance. It will make available the modifier
* `onlyOwner`, which can be applied to your functions to restrict their use to
* the owner.
*/
abstract contract Ownable is Context {
   address private _owner;

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
   constructor () internal {
       address msgSender = _msgSender();
       _owner = msgSender;
       emit OwnershipTransferred(address(0), msgSender);
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
       require(_owner == _msgSender(), "Ownable: caller is not the owner");
       _;
   }

   /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
   function renounceOwnership() public virtual onlyOwner {
       emit OwnershipTransferred(_owner, address(0));
       _owner = address(0);
   }

   /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
   function transferOwnership(address newOwner) public virtual onlyOwner {
       require(newOwner != address(0), "Ownable: new owner is the zero address");
       emit OwnershipTransferred(_owner, newOwner);
       _owner = newOwner;
   }
}

// Copyright (c) 2019-2020 revolutionpopuli.com

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.





// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/








/**
* @dev Implementation of the {IERC20} interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using {_mint}.
* For a generic mechanism see {ERC20PresetMinterPauser}.
*
* TIP: For a detailed writeup see our guide
* https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
* to implement supply mechanisms].
*
* We have followed general OpenZeppelin guidelines: functions revert instead
* of returning `false` on failure. This behavior is nonetheless conventional
* and does not conflict with the expectations of ERC20 applications.
*
* Additionally, an {Approval} event is emitted on calls to {transferFrom}.
* This allows applications to reconstruct the allowance for all accounts just
* by listening to said events. Other implementations of the EIP may not emit
* these events, as it isn't required by the specification.
*
* Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
* functions have been added to mitigate the well-known issues around setting
* allowances. See {IERC20-approve}.
*/
contract ERC20 is Context, IERC20 {
   using SafeMath for uint256;

   mapping (address => uint256) private _balances;

   mapping (address => mapping (address => uint256)) private _allowances;

   uint256 private _totalSupply;

   string private _name;
   string private _symbol;
   uint8 private _decimals;

   /**
    * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
    * a default value of 18.
    *
    * To select a different value for {decimals}, use {_setupDecimals}.
    *
    * All three of these values are immutable: they can only be set once during
    * construction.
    */
   constructor (string memory name_, string memory symbol_) public {
       _name = name_;
       _symbol = symbol_;
       _decimals = 18;
   }

   /**
    * @dev Returns the name of the token.
    */
   function name() public view returns (string memory) {
       return _name;
   }

   /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
   function symbol() public view returns (string memory) {
       return _symbol;
   }

   /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5,05` (`505 / 10 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
    * called.
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IERC20-balanceOf} and {IERC20-transfer}.
    */
   function decimals() public view returns (uint8) {
       return _decimals;
   }

   /**
    * @dev See {IERC20-totalSupply}.
    */
   function totalSupply() public view override returns (uint256) {
       return _totalSupply;
   }

   /**
    * @dev See {IERC20-balanceOf}.
    */
   function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];
   }

   /**
    * @dev See {IERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       _transfer(_msgSender(), recipient, amount);
       return true;
   }

   /**
    * @dev See {IERC20-allowance}.
    */
   function allowance(address owner, address spender) public view virtual override returns (uint256) {
       return _allowances[owner][spender];
   }

   /**
    * @dev See {IERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function approve(address spender, uint256 amount) public virtual override returns (bool) {
       _approve(_msgSender(), spender, amount);
       return true;
   }

   /**
    * @dev See {IERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20}.
    *
    * Requirements:
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least
    * `amount`.
    */
   function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
       _transfer(sender, recipient, amount);
       _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
       return true;
   }

   /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
       _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
       return true;
   }

   /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
   function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
       _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
       return true;
   }

   /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
       require(sender != address(0), "ERC20: transfer from the zero address");
       require(recipient != address(0), "ERC20: transfer to the zero address");

       _beforeTokenTransfer(sender, recipient, amount);

       _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
       _balances[recipient] = _balances[recipient].add(amount);
       emit Transfer(sender, recipient, amount);
   }

   /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements:
    *
    * - `to` cannot be the zero address.
    */
   function _mint(address account, uint256 amount) internal virtual {
       require(account != address(0), "ERC20: mint to the zero address");

       _beforeTokenTransfer(address(0), account, amount);

       _totalSupply = _totalSupply.add(amount);
       _balances[account] = _balances[account].add(amount);
       emit Transfer(address(0), account, amount);
   }

   /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
   function _burn(address account, uint256 amount) internal virtual {
       require(account != address(0), "ERC20: burn from the zero address");

       _beforeTokenTransfer(account, address(0), amount);

       _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
       _totalSupply = _totalSupply.sub(amount);
       emit Transfer(account, address(0), amount);
   }

   /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    *
    * This internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
   function _approve(address owner, address spender, uint256 amount) internal virtual {
       require(owner != address(0), "ERC20: approve from the zero address");
       require(spender != address(0), "ERC20: approve to the zero address");

       _allowances[owner][spender] = amount;
       emit Approval(owner, spender, amount);
   }

   /**
    * @dev Sets {decimals} to a value other than the default one of 18.
    *
    * WARNING: This function should only be called from the constructor. Most
    * applications that interact with token contracts will not expect
    * {decimals} to ever change, and may work incorrectly if it does.
    */
   function _setupDecimals(uint8 decimals_) internal {
       _decimals = decimals_;
   }

   /**
    * @dev Hook that is called before any transfer of tokens. This includes
    * minting and burning.
    *
    * Calling conditions:
    *
    * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    * will be to transferred to `to`.
    * - when `from` is zero, `amount` tokens will be minted for `to`.
    * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    * - `from` and `to` are never both zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
   function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// Copyright (c) 2019-2020 revolutionpopuli.com

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.





// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/






/**
* @dev Contract module which allows children to implement an emergency stop
* mechanism that can be triggered by an authorized account.
*
* This module is used through inheritance. It will make available the
* modifiers `whenNotPaused` and `whenPaused`, which can be applied to
* the functions of your contract. Note that they will not be pausable by
* simply including this module, only once the modifiers are put in place.
*/
abstract contract Pausable is Context {
   /**
    * @dev Emitted when the pause is triggered by `account`.
    */
   event Paused(address account);

   /**
    * @dev Emitted when the pause is lifted by `account`.
    */
   event Unpaused(address account);

   bool private _paused;

   /**
    * @dev Initializes the contract in unpaused state.
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
    *
    * Requirements:
    *
    * - The contract must not be paused.
    */
   modifier whenNotPaused() virtual {
       require(!_paused, "Pausable: paused");
       _;
   }

   /**
    * @dev Modifier to make a function callable only when the contract is paused.
    *
    * Requirements:
    *
    * - The contract must be paused.
    */
   modifier whenPaused() {
       require(_paused, "Pausable: not paused");
       _;
   }

   /**
    * @dev Triggers stopped state.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    */
   function _pause() internal virtual whenNotPaused {
       _paused = true;
       emit Paused(_msgSender());
   }

   /**
    * @dev Returns to normal state.
    *
    * Requirements:
    *
    * - The contract must be paused.
    */
   function _unpause() internal virtual whenPaused {
       _paused = false;
       emit Unpaused(_msgSender());
   }
}



contract PausableWithException is Pausable, Ownable {
   mapping(address => bool) public exceptions;

   modifier whenNotPaused() override {
       require(!paused() || hasException(_msgSender()), "Pausable: paused (and no exception)");

       _;
   }

   modifier whenNotPausedWithoutException() {
       require(!paused(), "Pausable: paused");

       _;
   }

   function hasException(address _account) public view returns (bool) {
       return exceptions[_account];
   }

   function setPausableException(address _account, bool _status) external whenNotPaused onlyOwner {
       exceptions[_account] = _status;
   }
}


contract Token is ERC20, PausableWithException {
   constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

   function pause() public onlyOwner {
       super._pause();
   }

   function unpause() public onlyOwner {
       super._unpause();
   }

   function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
       return super.transfer(recipient, amount);
   }

   function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPausedWithoutException returns (bool) {
       return super.transferFrom(sender, recipient, amount);
   }

   function mint(address account, uint amount) public onlyOwner whenNotPaused {
       _mint(account, amount);
   }

   function burn(address account, uint amount) public onlyOwner {
       _burn(account, amount);
   }
}

// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/






// This contract was copied from https://github.com/OpenZeppelin/openzeppelin-contracts/




/**
* @dev Collection of functions related to the address type
*/
library Address {
   /**
    * @dev Returns true if `account` is a contract.
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
   function isContract(address account) internal view returns (bool) {
       // This method relies on extcodesize, which returns 0 for contracts in
       // construction, since the code is only stored at the end of the
       // constructor execution.

       uint256 size;
       // solhint-disable-next-line no-inline-assembly
       assembly { size := extcodesize(account) }
       return size > 0;
   }

   /**
    * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    * `recipient`, forwarding all available gas and reverting on errors.
    *
    * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    * of certain opcodes, possibly making contracts go over the 2300 gas limit
    * imposed by `transfer`, making them unable to receive funds via
    * `transfer`. {sendValue} removes this limitation.
    *
    * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    *
    * IMPORTANT: because control is transferred to `recipient`, care must be
    * taken to not create reentrancy vulnerabilities. Consider using
    * {ReentrancyGuard} or the
    * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    */
   function sendValue(address payable recipient, uint256 amount) internal {
       require(address(this).balance >= amount, "Address: insufficient balance");

       // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
       (bool success, ) = recipient.call{ value: amount }("");
       require(success, "Address: unable to send value, recipient may have reverted");
   }

   /**
    * @dev Performs a Solidity function call using a low level `call`. A
    * plain`call` is an unsafe replacement for a function call: use this
    * function instead.
    *
    * If `target` reverts with a revert reason, it is bubbled up by this
    * function (like regular Solidity function calls).
    *
    * Returns the raw returned data. To convert to the expected return value,
    * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
    *
    * Requirements:
    *
    * - `target` must be a contract.
    * - calling `target` with `data` must not revert.
    *
    * _Available since v3.1._
    */
   function functionCall(address target, bytes memory data) internal returns (bytes memory) {
       return functionCall(target, data, "Address: low-level call failed");
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
    * `errorMessage` as a fallback revert reason when `target` reverts.
    *
    * _Available since v3.1._
    */
   function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
       return functionCallWithValue(target, data, 0, errorMessage);
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    * but also transferring `value` wei to `target`.
    *
    * Requirements:
    *
    * - the calling contract must have an ETH balance of at least `value`.
    * - the called Solidity function must be `payable`.
    *
    * _Available since v3.1._
    */
   function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
       return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
   }

   /**
    * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
    * with `errorMessage` as a fallback revert reason when `target` reverts.
    *
    * _Available since v3.1._
    */
   function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
       require(address(this).balance >= value, "Address: insufficient balance for call");
       require(isContract(target), "Address: call to non-contract");

       // solhint-disable-next-line avoid-low-level-calls
       (bool success, bytes memory returndata) = target.call{ value: value }(data);
       return _verifyCallResult(success, returndata, errorMessage);
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    * but performing a static call.
    *
    * _Available since v3.3._
    */
   function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
       return functionStaticCall(target, data, "Address: low-level static call failed");
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    * but performing a static call.
    *
    * _Available since v3.3._
    */
   function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
       require(isContract(target), "Address: static call to non-contract");

       // solhint-disable-next-line avoid-low-level-calls
       (bool success, bytes memory returndata) = target.staticcall(data);
       return _verifyCallResult(success, returndata, errorMessage);
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    * but performing a delegate call.
    *
    * _Available since v3.3._
    */
   function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
       return functionDelegateCall(target, data, "Address: low-level delegate call failed");
   }

   /**
    * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    * but performing a delegate call.
    *
    * _Available since v3.3._
    */
   function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
       require(isContract(target), "Address: delegate call to non-contract");

       // solhint-disable-next-line avoid-low-level-calls
       (bool success, bytes memory returndata) = target.delegatecall(data);
       return _verifyCallResult(success, returndata, errorMessage);
   }

   function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
       if (success) {
           return returndata;
       } else {
           // Look for revert reason and bubble it up if present
           if (returndata.length > 0) {
               // The easiest way to bubble the revert reason is using memory via assembly

               // solhint-disable-next-line no-inline-assembly
               assembly {
                   let returndata_size := mload(returndata)
                   revert(add(32, returndata), returndata_size)
               }
           } else {
               revert(errorMessage);
           }
       }
   }
}


/**
* @title SafeERC20
* @dev Wrappers around ERC20 operations that throw on failure (when the token
* contract returns false). Tokens that return no value (and instead revert or
* throw on failure) are also supported, non-reverting calls are assumed to be
* successful.
* To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
* which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
*/
library SafeERC20 {
   using SafeMath for uint256;
   using Address for address;

   function safeTransfer(IERC20 token, address to, uint256 value) internal {
       _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
   }

   function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
       _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
   }

   /**
    * @dev Deprecated. This function has issues similar to the ones found in
    * {IERC20-approve}, and its usage is discouraged.
    *
    * Whenever possible, use {safeIncreaseAllowance} and
    * {safeDecreaseAllowance} instead.
    */
   function safeApprove(IERC20 token, address spender, uint256 value) internal {
       // safeApprove should only be called when setting an initial allowance,
       // or when resetting it to zero. To increase and decrease it, use
       // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
       // solhint-disable-next-line max-line-length
       require((value == 0) || (token.allowance(address(this), spender) == 0),
           "SafeERC20: approve from non-zero to non-zero allowance"
       );
       _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
   }

   function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
       uint256 newAllowance = token.allowance(address(this), spender).add(value);
       _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
   }

   function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
       uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
       _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
   }

   /**
    * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
    * on the return value: the return value is optional (but if data is returned, it must not be false).
    * @param token The token targeted by the call.
    * @param data The call data (encoded using abi.encode or one of its variants).
    */
   function _callOptionalReturn(IERC20 token, bytes memory data) private {
       // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
       // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
       // the target address contains contract code and also asserts for success in the low-level call.

       bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
       if (returndata.length > 0) { // Return data is optional
           // solhint-disable-next-line max-line-length
           require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
       }
   }
}


// Copyright (c) 2019-2020 revolutionpopuli.com

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.






// Copyright (c) 2019-2020 revolutionpopuli.com

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.










contract TokenEscrow is Ownable {
   using SafeMath for uint256;
   using SafeERC20 for Token;

   struct Share {
       uint256 proportion;
       uint256 periods;
       uint256 periodLength;
   }

   uint256 public unlockStart;
   uint256 public totalShare;

   mapping(address => Share) public shares;
   mapping(address => uint256) public unlocked;

   Token public token;

   constructor(Token _token) {
       token = _token;
   }

   function setUnlockStart(uint256 _unlockStart) external virtual onlyOwner {
       require(unlockStart == 0, "unlockStart should be == 0");
       require(_unlockStart >= block.timestamp, "_unlockStart should be >= block.timestamp");

       unlockStart = _unlockStart;
   }

   function addShare(address _beneficiary, uint256 _proportion, uint256 _periods, uint256 _periodLength) external onlyOwner {
       shares[_beneficiary] = Share(shares[_beneficiary].proportion.add(_proportion),_periods,_periodLength);
       totalShare = totalShare.add(_proportion);
   }

   // If the time of freezing expired will return the funds to the owner.
   function unlockFor(address _beneficiary) public {
       require(unlockStart > 0, "unlockStart should be > 0");
       require(
           block.timestamp >= (unlockStart.add(shares[_beneficiary].periodLength)),
           "block.timestamp should be >= (unlockStart.add(shares[_beneficiary].periodLength))"
       );

       uint256 share = shares[_beneficiary].proportion;
       uint256 periodsSinceUnlockStart = ((block.timestamp).sub(unlockStart)).div(shares[_beneficiary].periodLength);

       if (periodsSinceUnlockStart < shares[_beneficiary].periods) {
           share = share.mul(periodsSinceUnlockStart).div(shares[_beneficiary].periods);
       }

       share = share.sub(unlocked[_beneficiary]);

       if (share > 0) {
           unlocked[_beneficiary] = unlocked[_beneficiary].add(share);
           uint256 unlockedToken = token.balanceOf(address(this)).mul(share).div(totalShare);
           totalShare = totalShare.sub(share);
           token.safeTransfer(_beneficiary,unlockedToken);
       }
   }
}


contract Creator {
   Token public token = new Token('RevolutionPopuli ERC20 Token', 'RVP');
   TokenEscrow public tokenEscrow;

   constructor() {
       token.transferOwnership(msg.sender);
   }

   function createTokenEscrow() external returns (TokenEscrow) {
       tokenEscrow = new TokenEscrow(token);
       tokenEscrow.transferOwnership(msg.sender);

       return tokenEscrow;
   }
}


contract TokenSale is Ownable {
   using SafeMath for uint256;
   using SafeERC20 for Token;

   uint constant public MIN_ETH = 0.1 ether; // !!! for real ICO change to 1 ether
   uint constant public WINDOW_DURATION = 23 hours; // !!! for real ICO change to 23 hours

   uint constant public MARKETING_SHARE = 200000000 ether;
   uint constant public TEAM_MEMBER_1_SHARE = 50000000 ether;
   uint constant public TEAM_MEMBER_2_SHARE = 50000000 ether;
   uint constant public TEAM_MEMBER_3_SHARE = 50000000 ether;
   uint constant public TEAM_MEMBER_4_SHARE = 50000000 ether;
   uint constant public REVPOP_FOUNDATION_SHARE = 200000000 ether;
   uint constant public REVPOP_FOUNDATION_PERIOD_LENGTH = 365 days; // !!! for real ICO change to 365 days
   uint constant public REVPOP_FOUNDATION_PERIODS = 10; // 10 years (!!! for real ICO it would be 10 years)
   uint constant public REVPOP_COMPANY_SHARE = 200000000 ether;
   uint constant public REVPOP_COMPANY_PERIOD_LENGTH = 365 days; // !!! for real ICO change to 365 days
   uint constant public REVPOP_COMPANY_PERIODS = 10; // 10 years (!!! for real ICO it would be 10 years)

   address[9] public wallets = [
       // RevPop.org foundation
       0x26be1e82026BB50742bBF765c8b1665bCB763c4c,

       // RevPop company
       0x4A2d3b4475dA7E634154F1868e689705bDCEEF4c,

       // Marketing
       0x73d3F88BF15EB48e94E6583968041cC850d61D62,

       // Team member 1
       0x1F3eFCe792f9744d919eee34d23e054631351eBc,

       // Team member 2
       0xEB7bb38D821219aE20d3Df7A80A161563CDe5f1b,

       // Team member 3
       0x9F3868cF5FEdb90Df9D9974A131dE6B56B3aA7Ca,

       // Team member 4
       0xE7320724CA4C20aEb193472D3082593f6c58A3C5,

       // Unsold tokens taker
       0xCde8311aa7AAbECDEf84179D93a04005C8C549c0,

       // Beneficiarry
       0x8B104136F8c1FC63fBA34cb46c42c7af5532f80e
   ];

   Token public token;                   // The Token token itself
   TokenEscrow public tokenEscrow;

   uint public totalSupply;           // Total Token amount created

   uint public firstWindowStartTime;  // Time of window 1 opening
   uint public createPerFirstWindow;  // Tokens sold in window 1

   uint public otherWindowsStartTime; // Time of other windows opening
   uint public numberOfOtherWindows;  // Number of other windows
   uint public createPerOtherWindow;  // Tokens sold in each window after window 1

   uint public totalBoughtTokens;
   uint public totalRaisedETH;
   uint public totalBulkPurchasedTokens;

   uint public collectedUnsoldTokensBeforeWindow = 0;

   bool public initialized = false;
   bool public tokensPerPeriodAreSet = false;
   bool public distributedShares = false;
   bool public began = false;
   bool public tokenSalePaused = false;

   mapping(uint => uint) public dailyTotals;
   mapping(uint => mapping(address => uint)) public userBuys;
   mapping(uint => mapping(address => bool)) public claimed;

   event LogBuy           (uint window, address user, uint amount);
   event LogClaim         (uint window, address user, uint amount);
   event LogCollect       (uint amount);
   event LogCollectUnsold (uint amount);

   constructor(Creator creator) {
       token = creator.token();

       require(token.totalSupply() == 0, "Total supply of Token should be 0");

       tokenEscrow = creator.createTokenEscrow();

       require(tokenEscrow.owner() == address(this), "Invalid owner of the TokenEscrow");
       require(tokenEscrow.unlockStart() == 0, "TokenEscrow.unlockStart should be 0");
   }

   function renounceOwnership() public override onlyOwner {
       require(address(this).balance == 0, "address(this).balance should be == 0");

       super.renounceOwnership();
   }

   function initialize(
       uint _totalSupply,
       uint _firstWindowStartTime,
       uint _otherWindowsStartTime,
       uint _numberOfOtherWindows
   ) public onlyOwner {
       require(token.owner() == address(this), "Invalid owner of the Token");
       token.setPausableException(address(tokenEscrow), true);
       token.setPausableException(address(this), true);
       token.setPausableException(wallets[2], true);
       token.setPausableException(wallets[7], true);

       require(initialized == false, "initialized should be == false");
       require(_totalSupply > 0, "_totalSupply should be > 0");
       require(_firstWindowStartTime < _otherWindowsStartTime, "_firstWindowStartTime should be < _otherWindowsStartTime");
       require(_numberOfOtherWindows > 0, "_numberOfOtherWindows should be > 0");
       require(_totalSupply > totalReservedTokens(), "_totalSupply should be more than totalReservedTokens()");

       numberOfOtherWindows = _numberOfOtherWindows;
       totalSupply = _totalSupply;
       firstWindowStartTime = _firstWindowStartTime;
       otherWindowsStartTime = _otherWindowsStartTime;

       initialized = true;

       token.mint(address(this), totalSupply);
   }

   function addBulkPurchasers(address[] memory _purchasers, uint[] memory _tokens) public onlyOwner {
       require(initialized == true, "initialized should be == true");
       require(tokensPerPeriodAreSet == false, "tokensPerPeriodAreSet should be == false");

       uint count = _purchasers.length;

       require(count > 0, "count should be > 0");
       require(count == _tokens.length, "count should be == _tokens.length");

       for (uint i = 0; i < count; i++) {
           require(_tokens[i] > 0, "_tokens[i] should be > 0");
           token.safeTransfer(_purchasers[i], _tokens[i]);
           totalBulkPurchasedTokens = totalBulkPurchasedTokens.add(_tokens[i]);
       }

       require(
           token.balanceOf(address(this)) > totalReservedTokens(),
           "token.balanceOf(address(this)) should be > totalReservedTokens() after bulk purchases"
       );
   }

   function setTokensPerPeriods(uint _firstPeriodTokens, uint _otherPeriodTokens) public onlyOwner {
       require(initialized == true, "initialized should be == true");
       require(began == false, "began should be == false");

       tokensPerPeriodAreSet = true;

       uint totalTokens = _firstPeriodTokens.add(_otherPeriodTokens.mul(numberOfOtherWindows));

       require(
           totalSupply.sub(totalReservedTokens()).sub(totalBulkPurchasedTokens) == totalTokens,
           "totalSupply.sub(totalReservedTokens()).sub(totalBulkPurchasedTokens) should be == totalTokens"
       );

       createPerFirstWindow = _firstPeriodTokens;
       createPerOtherWindow = _otherPeriodTokens;
   }

   function distributeShares() public onlyOwner {
       require(tokensPerPeriodAreSet == true, "tokensPerPeriodAreSet should be == true");
       require(distributedShares == false, "distributedShares should be == false");

       distributedShares = true;

       token.safeTransfer(address(tokenEscrow), REVPOP_COMPANY_SHARE.add(REVPOP_FOUNDATION_SHARE));
       token.safeTransfer(wallets[2], MARKETING_SHARE);
       token.safeTransfer(wallets[3], TEAM_MEMBER_1_SHARE);
       token.safeTransfer(wallets[4], TEAM_MEMBER_2_SHARE);
       token.safeTransfer(wallets[5], TEAM_MEMBER_3_SHARE);
       token.safeTransfer(wallets[6], TEAM_MEMBER_4_SHARE);

       tokenEscrow.addShare(wallets[0], 50, REVPOP_FOUNDATION_PERIODS, REVPOP_FOUNDATION_PERIOD_LENGTH);
       tokenEscrow.addShare(wallets[1], 50, REVPOP_COMPANY_PERIODS, REVPOP_COMPANY_PERIOD_LENGTH);
       tokenEscrow.setUnlockStart(time());

       // We pause all transfers and minting.
       // We allow to use transfer() function ONLY for tokenEscrow contract,
       // because it is an escrow and it should allow to transfer tokens to a certain party.
       pauseTokenTransfer();
   }

   function totalReservedTokens() internal pure returns (uint) {
       return MARKETING_SHARE
           .add(TEAM_MEMBER_1_SHARE)
           .add(TEAM_MEMBER_2_SHARE)
           .add(TEAM_MEMBER_3_SHARE)
           .add(TEAM_MEMBER_4_SHARE)
           .add(REVPOP_COMPANY_SHARE)
           .add(REVPOP_FOUNDATION_SHARE);
   }

   function begin() public onlyOwner {
       require(distributedShares == true, "distributedShares should be == true");
       require(began == false, "began should be == false");

       began = true;
   }

   function pauseTokenTransfer() public onlyOwner {
       token.pause();
   }

   function unpauseTokenTransfer() public onlyOwner {
       token.unpause();
   }

   function pauseTokenSale() public onlyOwner {
       tokenSalePaused = true;
   }

   function unpauseTokenSale() public onlyOwner {
       tokenSalePaused = false;
   }

   function burnTokens(address account, uint amount) public onlyOwner {
       token.burn(account, amount);
   }

   function removePausableException(address _address) public onlyOwner {
       token.setPausableException(_address, false);
   }

   function time() internal view returns (uint) {
       return block.timestamp;
   }

   function today() public view returns (uint) {
       return windowFor(time());
   }

   function windowDuration() public virtual pure returns (uint) {
       return WINDOW_DURATION;
   }

   // Each window is windowDuration() (23 hours) long so that end-of-window rotates
   // around the clock for all timezones.
   function windowFor(uint timestamp) public view returns (uint) {
       return timestamp < otherWindowsStartTime
       ? 0
       : timestamp.sub(otherWindowsStartTime).div(windowDuration()).add(1);
   }

   function createOnWindow(uint window) public view returns (uint) {
       return window == 0 ? createPerFirstWindow : createPerOtherWindow;
   }

   // This method provides the buyer some protections regarding which
   // day the buy order is submitted and the maximum price prior to
   // applying this payment that will be allowed.
   function buyWithLimit(uint window, uint limit) public payable {
       require(began == true, "began should be == true");
       require(tokenSalePaused == false, "tokenSalePaused should be == false");
       require(time() >= firstWindowStartTime, "time() should be >= firstWindowStartTime");
       require(today() <= numberOfOtherWindows, "today() should be <= numberOfOtherWindows");
       require(msg.value >= MIN_ETH, "msg.value should be >= MIN_ETH");
       require(window >= today(), "window should be >= today()");
       require(window <= numberOfOtherWindows, "window should be <= numberOfOtherWindows");

       if (limit != 0) {
           require(dailyTotals[window] <= limit, "dailyTotals[window] should be <= limit");
       }

       userBuys[window][msg.sender] = userBuys[window][msg.sender].add(msg.value);
       dailyTotals[window] = dailyTotals[window].add(msg.value);
       totalRaisedETH = totalRaisedETH.add(msg.value);

       emit LogBuy(window, msg.sender, msg.value);
   }

   function buy() public payable {
       buyWithLimit(today(), 0);
   }

   fallback() external payable {
       buy();
   }

   receive() external payable {
       buy();
   }

   function claim(uint window) public {
       require(began == true, "began should be == true");
       require(today() > window, "today() should be > window");

       if (claimed[window][msg.sender] || dailyTotals[window] == 0 || userBuys[window][msg.sender] == 0) {
           return;
       }

       // 100 ether below is 100% * 10^18
       uint256 userEthShare = userBuys[window][msg.sender].mul(100 ether).div(dailyTotals[window]);
       uint256 reward = (createOnWindow(window)).mul(userEthShare).div(100 ether);

       totalBoughtTokens = totalBoughtTokens.add(reward);
       claimed[window][msg.sender] = true;
       token.safeTransfer(msg.sender, reward);

       emit LogClaim(window, msg.sender, reward);
   }

   function claimAll() public {
       require(began == true, "began should be == true");

       for (uint i = 0; i < today(); i++) {
           claim(i);
       }
   }

   // Crowdsale owners can collect ETH  number of times
   function collect() public {
       require(began == true, "began should be == true");
       require(today() > 0, "today() should be > 0");
       // Prevent recycling during window 0

       uint balance = address(this).balance;
       payable(wallets[8]).transfer(address(this).balance);

       emit LogCollect(balance);
   }

   function collectUnsoldTokens(uint window) public {
       require(began == true, "began should be == true");
       require(today() > 0, "today() should be > 0");
       require(window <= today(), "window should be <= today()");
       require(window > collectedUnsoldTokensBeforeWindow, "window should be > collectedUnsoldTokensBeforeWindow");

       uint unsoldTokens = 0;

       for (uint i = collectedUnsoldTokensBeforeWindow; i < window; i++) {
           uint dailyTotal = dailyTotals[i];

           if (dailyTotal == 0) {
               unsoldTokens = unsoldTokens.add(i == 0 ? createPerFirstWindow : createPerOtherWindow);
           }
       }

       collectedUnsoldTokensBeforeWindow = window;

       if (unsoldTokens > 0) {
           token.safeTransfer(wallets[7], unsoldTokens);
       }

       emit LogCollectUnsold(unsoldTokens);
   }
}