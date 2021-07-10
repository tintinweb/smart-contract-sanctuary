/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
		// This method relies in extcodesize, which returns 0 for contracts in
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
		return _functionCallWithValue(target, data, 0, errorMessage);
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
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;

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
	using Address for address;

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
	constructor (string memory name, string memory symbol) public {
		_name = name;
		_symbol = symbol;
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
	 * required by the EIP. See the note at the beginning of {ERC20};
	 *
	 * Requirements:
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
	 * Requirements
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
	 * Requirements
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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: contracts/MoonlaToken.sol

pragma solidity 0.6.12;

// MoonlaToken with Governance.
contract MoonlaToken is ERC20("MoonlaToken", "MLA"), Ownable {
	uint256 private _cap = 60000000e18;

	address public feeaddr;
	uint256 public transferFeeRate;
	
	mapping(address => bool) private _isExcludedFromFee;

	function cap() public view returns (uint256) {
		return _cap;
	}

	function capfarm() public view returns (uint256) {
		return cap().sub(totalSupply());
	} 

	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 *
	 * Requirements:
	 *
	 * - minted tokens must not cause the total supply to go over the cap.
	 */
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
		super._beforeTokenTransfer(from, to, amount);

		if (from == address(0)) { // When minting tokens
			require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
		}
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
	function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
		if (transferFeeRate > 0 && _isExcludedFromFee[recipient] == false && recipient != address(0) && feeaddr != address(0)) {
			uint256 _feeamount = amount * transferFeeRate / 100;
			super._transfer(sender, feeaddr, _feeamount); // TransferFee
			amount = amount - _feeamount;
		}

		super._transfer(sender, recipient, amount);
	}

	/// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
	function mint(address _to, uint256 _amount) public onlyOwner {
		_mint(_to, _amount);
	}

	function _transferownership(address _addr) public onlyOwner {
            transferOwnership(_addr);
    }
    
	/**
	 * @dev Destroys `amount` tokens from the caller.
	 *
	 * See {ERC20-_burn}.
	 */
	function burn(uint256 amount) public virtual returns (bool) {
		_burn(_msgSender(), amount);
		return true;
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, deducting from the caller's
	 * allowance.
	 *
	 * See {ERC20-_burn} and {ERC20-allowance}.
	 *
	 * Requirements:
	 *
	 * - the caller must have allowance for ``accounts``'s tokens of at least
	 * `amount`.
	 */
	function burnFrom(address account, uint256 amount) public virtual returns (bool) {
		uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

		_approve(account, _msgSender(), decreasedAllowance);
		_burn(account, amount);
		return true;
	}


    function addToWhilteList(address _address) public onlyOwner {
        _isExcludedFromFee[_address] = false;
    }

	function removeFromWhilteList(address _address) public onlyOwner {
	    _isExcludedFromFee[_address] = true;
	}
	
     function isWhilteListed(address _address) public view returns (bool) {
        return _isExcludedFromFee[_address];
    }


    function setFeeAddr(address _feeaddr) public onlyOwner {
		feeaddr = _feeaddr;
    }

	constructor() public {
		transferFeeRate = 2;
		_mint(msg.sender, 6000000*10**18);
	}
}

// File: contracts/libraries/SafeERC20.sol

pragma solidity ^0.6.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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

// File: contracts/MoonlaFarm.sol

pragma solidity ^0.6.0;

contract MoonlaFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
       uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
        uint256 lockAmount;        // Lock amount reward token
        uint256 nextClaimUntil; // When can the user claim again.
        uint256 lastUnlockBlock;
        uint256[] lockAmounts;
        uint256[] claimUntil;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of LP token contract.
        MoonlaToken rewardToken;        // Address of reward token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MLAs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that MLAs distribution occurs.
        uint256 accMlaPerShare;   // Accumulated MLAs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 startBlock;        // Start at block.
        uint256 totalLock;         // Total lock reward token on pool.
        uint256 lockFromBlock;     // Lock from block.
        uint256 lockInterval;      //lockInterval in seconds
    }

    // The MLA TOKEN!
    MoonlaToken public mla;
    
    uint256 public stakeAmountLv1 = 100*10**18;    // Minimum stake UBU token condition level1 for referral program.
    uint256 public stakeAmountLv2 = 1000*10**18;    // Minimum stake UBU token condition level2 for referral program.

    uint256 public percentForReferLv1 = 5; // Percent reward level1 referral program.
    uint256 public percentForReferLv2 = 2; // Percent reward level2 referral program.
    
    uint256 public percentLockAmount = 30; // Percent lock amount.
    
    // Dev address.
    address public devaddr;
    // MLA tokens created per block.
    uint256 public mlaPerBlock;
    
    // Deposit Fee address
    address public feeAddress;
    
    address public zeoAddress= address(0);

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => address) public referrers;
    
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
   
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MLA mining starts.
    
    uint256 public startBlock;
    
    uint256 public referralsTotalCount = 0;
    uint256 public referralsTotalCommission = 0;

    mapping(IERC20 => uint256) public totalLocks;
    
    mapping(IERC20 => bool) public poolExistence;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Lock(address indexed to, uint256 value);
    event SendReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);
    
    constructor(
        MoonlaToken _mla,
        address _devaddr,
        address _feeAddress,
        uint256 _mlaPerBlock,
        uint256 _startBlock
    ) public {
        mla = _mla;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        mlaPerBlock = _mlaPerBlock;
        startBlock = _startBlock;
    }
    
    modifier nonDuplicated(IERC20 _lpToken)  {
        require (poolExistence[_lpToken]  ==  false,  "nonDuplicated: duplicated");
        _;
    }  

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, MoonlaToken _rewardToken, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate,uint256 _startBlock,uint256 _lockFromBlock,uint256 _lockInterval) public onlyOwner nonDuplicated(_lpToken){
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            rewardToken: _rewardToken,
            allocPoint: _allocPoint,
            startBlock: _startBlock,
            totalLock: 0,
            lastRewardBlock: lastRewardBlock,
            accMlaPerShare: 0,
            depositFeeBP: _depositFeeBP,
            lockFromBlock: _lockFromBlock,
            lockInterval : _lockInterval
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }
    
    function setreferralToken(MoonlaToken _referralToken) public onlyOwner {
        mla = _referralToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingMla(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMlaPerShare = pool.accMlaPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 mlaReward = multiplier.mul(mlaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMlaPerShare = accMlaPerShare.add(mlaReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMlaPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mlaReward = multiplier.mul(mlaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accMlaPerShare = pool.accMlaPerShare.add(mlaReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        
    }
    
    function recordReferral(address _user, address _referrer) internal {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            referralsTotalCount += 1;
        }
    }

    // Deposit LP tokens to MasterChef for MLA allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _harvest(_pid);
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
            recordReferral(msg.sender,_referrer);
        }
        
        user.rewardDebt = user.amount.mul(pool.accMlaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
          if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMlaPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 masterBal = pool.rewardToken.capfarm().sub(totalLocks[pool.rewardToken]);

                if (pending > masterBal) {
                pending = masterBal;
                }
            
                uint256 referAmountLv1 = pending.mul(percentForReferLv1).div(100);
                uint256 referAmountLv2 = pending.mul(percentForReferLv2).div(100);
                _transferReferral(_pid, referAmountLv1, referAmountLv2);

                uint256 amount = pending.sub(referAmountLv1).sub(referAmountLv2);
                uint256 lockAmount = amount.mul(percentLockAmount).div(100);    
                pool.rewardToken.mint(msg.sender, amount.sub(lockAmount));
                farmLock(msg.sender, lockAmount, _pid);
                user.rewardDebtAtBlock = block.number;
                emit SendReward(msg.sender, _pid, amount, lockAmount);
            }
            user.rewardDebt = user.amount.mul(pool.accMlaPerShare).div(1e12);
        }
    }
    
    function _transferReferral(uint256 _pid, uint256 _referAmountLv1, uint256 _referAmountLv2) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address referrerLv1 = referrers[address(msg.sender)];
        uint256 referAmountForDev = 0;

        if (referrerLv1 != address(0)) {
            uint256 lpStaked = mla.balanceOf(referrerLv1);
            if (lpStaked >= stakeAmountLv1) {
                pool.rewardToken.mint(referrerLv1,  _referAmountLv1);
                totalReferralCommissions[referrerLv1] += _referAmountLv1;
                referralsTotalCommission += _referAmountLv1;
            } else {
                // dev team will receive reward of referrer level 1
                referAmountForDev = referAmountForDev.add(_referAmountLv1);
            }

            address referrerLv2 = referrers[referrerLv1];
            uint256 lpStaked2 = mla.balanceOf(referrerLv2);
            if (referrerLv2 != address(0) && lpStaked2 >= stakeAmountLv2) {
                pool.rewardToken.mint(referrerLv2, _referAmountLv2);
                totalReferralCommissions[referrerLv2] += _referAmountLv2;
                referralsTotalCommission += _referAmountLv2;
            } else {
                // dev team will receive reward of referrer level 2
                referAmountForDev = referAmountForDev.add(_referAmountLv2);
            }

        } else {
            referAmountForDev = _referAmountLv1.add(_referAmountLv2);
        }
        
        if (referAmountForDev > 0) {
            pool.rewardToken.mint(devaddr, referAmountForDev);
        }
    }
    
    
    function farmLock(address _holder, uint256 _amount, uint256 _pid) internal {
        require(_holder != address(0), "ERC20: lock to the zero address");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_holder];

        user.lockAmount = user.lockAmount.add(_amount);
        pool.totalLock = pool.totalLock.add(_amount);
        user.lockAmounts.push(_amount);
        user.claimUntil.push(block.timestamp.add(pool.lockInterval));
       
        totalLocks[pool.rewardToken] = totalLocks[pool.rewardToken].add(_amount);
        if (user.lastUnlockBlock < pool.lockFromBlock) {
            user.lastUnlockBlock = pool.lockFromBlock;
        }
        
        emit Lock(_holder, _amount);
    }
    
  
    function getNextClaim(uint256 _pid,uint256 _id) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.lockAmounts[_id];        
    }

    function unlock(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockAmount > 0, "ERC20: cannot unlock");

        uint256 amount = canUnlockAmount(msg.sender, _pid);
        uint256 masterBL = pool.rewardToken.capfarm();
		
        if (amount > masterBL) {
            amount = masterBL;
        }
        
        pool.rewardToken.mint(msg.sender, amount);
        user.lockAmount = user.lockAmount.sub(amount);
        //remove the first claimAmount.
        if(user.lockAmounts.length > 0){
          for(uint i = 0; i < user.lockAmounts.length-1; i++){
            user.lockAmounts[i] = user.lockAmounts[i+1];
            user.claimUntil[i] = user.claimUntil[i+1];
          }
         user.lockAmounts.pop();
         user.claimUntil.pop();
        }
        user.lastUnlockBlock = block.number;
        pool.totalLock = pool.totalLock.sub(amount);
        totalLocks[pool.rewardToken] = totalLocks[pool.rewardToken].sub(amount);
    }
    // View function to see if user can harvest Gators.
    function canClaim(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextClaimUntil;
    }
    
    function canUnlockAmount(address _holder, uint256 _pid) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_holder];
        if(user.lockAmounts.length > 0){
            if(block.timestamp < user.claimUntil[0]){
                return 0;
            }else{
                return user.lockAmounts[0];
            }
        }
     }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _harvest(_pid);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMlaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from UFarmer.
    function withdrawAll(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid);
		emergencyWithdraw(_pid);
    }
	
   
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    function totalLockInPool(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].totalLock;
    }

    function totalLock(MoonlaToken _rewardToken) public view returns (uint256) {
        return totalLocks[_rewardToken];
    }

    function lockOf(address _holder, uint256 _pid) public view returns (uint256) {
        return userInfo[_pid][_holder].lockAmount;
    }

    function lastUnlockBlock(address _holder, uint256 _pid) public view returns (uint256) {
        return userInfo[_pid][_holder].lastUnlockBlock;
    }

    // Safe mla transfer function, just in case if rounding error causes pool to not have enough MLAs.
    function safeMlaTransfer(address _to, uint256 _amount) internal {
        uint256 mlaBal = mla.balanceOf(address(this));
        if (_amount > mlaBal) {
            mla.transfer(_to, mlaBal);
        } else {
            mla.transfer(_to, _amount);
        }
    }

    function changeTokenOwner(address _addr) public onlyOwner{
       mla._transferownership(_addr);
    }


    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    
    function setAmountLPStakeLevelRefer(uint256 _stakeAmountLv1, uint256 _stakeAmountLv2) public onlyOwner {
        stakeAmountLv1 = _stakeAmountLv1;
        stakeAmountLv2 = _stakeAmountLv2;
    }
    

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }
    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _mlaPerBlock) public onlyOwner {
        massUpdatePools();
        mlaPerBlock = _mlaPerBlock;
    }
}