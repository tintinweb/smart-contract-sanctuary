/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/Common/Context.sol


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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/Math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/ERC20/IERC20.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


// File contracts/Utils/Address.sol


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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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


// File contracts/ERC20/ERC20.sol





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File contracts/ERC20/ERC20Permit/IERC20Permit.sol



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/ERC20/ERC20Permit/ECDSA.sol



/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/ERC20/ERC20Permit/EIP712.sol



/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File contracts/ERC20/ERC20Permit/Counters.sol



/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/ERC20/ERC20Permit/ERC20Permit.sol







/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function PERMIT_TYPEHASH() external view returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}


// File contracts/Uniswap/TransferHelper.sol


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/Staking/Owned.sol


// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// File contracts/Utils/ReentrancyGuard.sol


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/ERC20/__CROSSCHAIN/CrossChainCanonical.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== CrossChainCanonical =======================
// ====================================================================
// Cross-chain / non mainnet canonical token contract.
// Can accept any number of old non-canonical tokens. These will be 
// withdrawable by the owner so they can de-bridge it and get back mainnet 'real' tokens
// Does not include any spurious mainnet logic

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett





contract CrossChainCanonical is ERC20Permit, Owned, ReentrancyGuard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelock_address; // Governance timelock address
    address public custodian_address; 

    // Misc
    uint256 public mint_cap;
    mapping(address => uint256[2]) public swap_fees;
    mapping(address => bool) public fee_exempt_list;

    // Acceptable old tokens
    address[] public bridge_tokens_array;
    mapping(address => bool) public bridge_tokens;

    // The addresses in this array are able to mint tokens
    address[] public minters_array;
    mapping(address => bool) public minters; // Mapping is also used for faster verification

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // Administrative booleans
    bool public exchangesPaused; // Pause old token exchanges in case of an emergency
    mapping(address => bool) public canSwap;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyMinters() {
       require(minters[msg.sender], "Not a minter");
        _;
    } 

    modifier onlyMintersOwnGov() {
       require(_isMinterOwnGov(msg.sender), "Not minter, owner, or tlck");
        _;
    } 

    modifier validBridgeToken(address token_address) {
       require(bridge_tokens[token_address], "Invalid old token");
        _;
    } 

    /* ========== CONSTRUCTOR ========== */

    constructor (
        string memory _name,
        string memory _symbol,
        address _creator_address,
        uint256 _initial_mint_amt,
        address _custodian_address,
        address[] memory _bridge_tokens
    ) ERC20(_name, _symbol) ERC20Permit(_name) Owned(_creator_address) {
        custodian_address = _custodian_address;

        // Initialize the starting old tokens
        for (uint256 i = 0; i < _bridge_tokens.length; i++){ 
            // Mark as accepted
            bridge_tokens[_bridge_tokens[i]] = true;

            // Add to the array
            bridge_tokens_array.push(_bridge_tokens[i]);

            // Set a small swap fee initially of 0.04%
            swap_fees[_bridge_tokens[i]] = [400, 400];

            // Make sure swapping is on
            canSwap[_bridge_tokens[i]] = true;
        }

        // Set the mint cap to the initial mint amount
        mint_cap = _initial_mint_amt;

        // Mint some canonical tokens to the creator
        super._mint(_creator_address, _initial_mint_amt);


    }

    /* ========== VIEWS ========== */

    // Helpful for UIs
    function allBridgeTokens() external view returns (address[] memory) {
        return bridge_tokens_array;
    }

    function _isMinterOwnGov(address the_address) internal view returns (bool) {
        return (the_address == timelock_address || the_address == owner || minters[the_address]);
    }

    function _isFeeExempt(address the_address) internal view returns (bool) {
        return (_isMinterOwnGov(the_address) || fee_exempt_list[the_address]);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // Enforce a minting cap
    function _mint_capped(address account, uint256 amount) internal {
        require(totalSupply() + amount <= mint_cap, "Mint cap");
        super._mint(account, amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Exchange old tokens for these canonical tokens
    function exchangeOldForCanonical(address bridge_token_address, uint256 token_amount) external nonReentrant validBridgeToken(bridge_token_address) returns (uint256 canonical_tokens_out) {
        require(!exchangesPaused && canSwap[bridge_token_address], "Exchanges paused");

        // Pull in the old tokens
        TransferHelper.safeTransferFrom(bridge_token_address, msg.sender, address(this), token_amount);

        // Handle the fee, if applicable
        canonical_tokens_out = token_amount;
        if (!_isFeeExempt(msg.sender)) {
            canonical_tokens_out -= ((canonical_tokens_out * swap_fees[bridge_token_address][0]) / PRICE_PRECISION);
        }

        // Mint canonical tokens and give it to the sender
        _mint_capped(msg.sender, canonical_tokens_out);
    }

    // Exchange canonical tokens for old tokens
    function exchangeCanonicalForOld(address bridge_token_address, uint256 token_amount) external nonReentrant validBridgeToken(bridge_token_address) returns (uint256 bridge_tokens_out) {
        require(!exchangesPaused && canSwap[bridge_token_address], "Exchanges paused");
        
        // Burn the canonical tokens
        super._burn(msg.sender, token_amount);

        // Handle the fee, if applicable
        bridge_tokens_out = token_amount;
        if (!_isFeeExempt(msg.sender)) {
            bridge_tokens_out -= ((bridge_tokens_out * swap_fees[bridge_token_address][1]) / PRICE_PRECISION);
        }

        // Give old tokens to the sender
        TransferHelper.safeTransfer(bridge_token_address, msg.sender, bridge_tokens_out);
    }

    /* ========== MINTERS OR GOVERNANCE FUNCTIONS ========== */

    // Collect old tokens so you can de-bridge them back on mainnet
    function withdrawBridgeTokens(address bridge_token_address, uint256 bridge_token_amount) external onlyMintersOwnGov validBridgeToken(bridge_token_address) {
        TransferHelper.safeTransfer(bridge_token_address, msg.sender, bridge_token_amount);
    }

    /* ========== MINTERS ONLY ========== */

    // This function is what other minters will call to mint new tokens 
    function minter_mint(address m_address, uint256 m_amount) external onlyMinters {
        _mint_capped(m_address, m_amount);
        emit TokenMinted(msg.sender, m_address, m_amount);
    }

    // This function is what other minters will call to burn tokens
    function minter_burn(uint256 amount) external onlyMinters {
        super._burn(msg.sender, amount);
        emit TokenBurned(msg.sender, amount);
    }

    /* ========== RESTRICTED FUNCTIONS, BUT CUSTODIAN CAN CALL TOO ========== */

    function toggleExchanges() external onlyByOwnGovCust {
        exchangesPaused = !exchangesPaused;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addBridgeToken(address bridge_token_address) external onlyByOwnGov {
        // Make sure the token is not already present
        for (uint i = 0; i < bridge_tokens_array.length; i++){ 
            if (bridge_tokens_array[i] == bridge_token_address){
                revert("Token already present");
            }
        }

        // Add the old token
        bridge_tokens[bridge_token_address] = true;
        bridge_tokens_array.push(bridge_token_address);

        // Turn swapping on
        canSwap[bridge_token_address] = true;

        emit BridgeTokenAdded(bridge_token_address);
    }

    function toggleBridgeToken(address bridge_token_address) external onlyByOwnGov {
        bridge_tokens[bridge_token_address] = !bridge_tokens[bridge_token_address];

        // Toggle swapping
        canSwap[bridge_token_address] = !canSwap[bridge_token_address];

        emit BridgeTokenToggled(bridge_token_address, !bridge_tokens[bridge_token_address]);
    }

    // Adds a minter address
    function addMinter(address minter_address) external onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");

        require(minters[minter_address] == false, "Address already exists");
        minters[minter_address] = true; 
        minters_array.push(minter_address);

        emit MinterAdded(minter_address);
    }

    // Remove a minter 
    function removeMinter(address minter_address) external onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");
        require(minters[minter_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete minters[minter_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < minters_array.length; i++){ 
            if (minters_array[i] == minter_address) {
                minters_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit MinterRemoved(minter_address);
    }

    function setMintCap(uint256 _mint_cap) external onlyByOwnGov {
        mint_cap = _mint_cap;

        emit MintCapSet(_mint_cap);
    }

    function setSwapFees(address bridge_token_address, uint256 _bridge_to_canonical, uint256 _canonical_to_old) external onlyByOwnGov {
        swap_fees[bridge_token_address] = [_bridge_to_canonical, _canonical_to_old];
    }

    function toggleFeesForAddress(address the_address) external onlyByOwnGov {
        fee_exempt_list[the_address] = !fee_exempt_list[the_address];
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        require(new_timelock != address(0), "Zero address detected");
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        require(_custodian_address != address(0), "Zero address detected");
        custodian_address = _custodian_address;

        emit CustodianSet(_custodian_address);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        require(!bridge_tokens[tokenAddress], "Cannot withdraw bridge tokens");
        require(tokenAddress != address(this), "Cannot withdraw these tokens");

        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // // Generic proxy
    // function execute(
    //     address _to,
    //     uint256 _value,
    //     bytes calldata _data
    // ) external onlyByOwnGov returns (bool, bytes memory) {
    //     (bool success, bytes memory result) = _to.call{value:_value}(_data);
    //     return (success, result);
    // }

    /* ========== EVENTS ========== */

    event TokenBurned(address indexed from, uint256 amount);
    event TokenMinted(address indexed from, address indexed to, uint256 amount);
    event BridgeTokenAdded(address indexed bridge_token_address);
    event BridgeTokenToggled(address indexed bridge_token_address, bool state);
    event CollateralRatioRefreshed(uint256 global_collateral_ratio);
    event MinterAdded(address pool_address);
    event MinterRemoved(address pool_address);
    event MintCapSet(uint256 new_mint_cap);
    event TimelockSet(address new_timelock);
    event CustodianSet(address custodian_address);
}


// File contracts/ERC20/__CROSSCHAIN/CrossChainCanonicalFRAX.sol


contract CrossChainCanonicalFRAX is CrossChainCanonical {
    constructor (
        string memory _name,
        string memory _symbol,
        address _creator_address,
        uint256 _initial_mint_amt,
        address _custodian_address,
        address[] memory _bridge_tokens
    ) 
    CrossChainCanonical(_name, _symbol, _creator_address, _initial_mint_amt, _custodian_address, _bridge_tokens)
    {}
}


// File contracts/ERC20/__CROSSCHAIN/CrossChainCanonicalFXS.sol


contract CrossChainCanonicalFXS is CrossChainCanonical {
    constructor (
        string memory _name,
        string memory _symbol,
        address _creator_address,
        uint256 _initial_mint_amt,
        address _custodian_address,
        address[] memory _bridge_tokens
    ) 
    CrossChainCanonical(_name, _symbol, _creator_address, _initial_mint_amt, _custodian_address, _bridge_tokens)
    {}
}


// File contracts/Math/Math.sol


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/ERC20/__CROSSCHAIN/IAnyswapV4ERC20.sol


interface IAnyswapV4ERC20 {
  function DOMAIN_SEPARATOR() external view returns(bytes32);
  function PERMIT_TYPEHASH() external view returns(bytes32);
  function Swapin(bytes32 txhash, address account, uint256 amount) external returns(bool);
  function Swapout(uint256 amount, address bindaddr) external returns(bool);
  function TRANSFER_TYPEHASH() external view returns(bytes32);
  function allowance(address, address) external view returns(uint256);
  function applyMinter() external;
  function applyVault() external;
  function approve(address spender, uint256 value) external returns(bool);
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns(bool);
  function balanceOf(address) external view returns(uint256);
  function burn(address from, uint256 amount) external returns(bool);
  function changeMPCOwner(address newVault) external returns(bool);
  function changeVault(address newVault) external returns(bool);
  function decimals() external view returns(uint8);
  function delay() external view returns(uint256);
  function delayDelay() external view returns(uint256);
  function delayMinter() external view returns(uint256);
  function delayVault() external view returns(uint256);
  function deposit(uint256 amount, address to) external returns(uint256);
  function deposit(uint256 amount) external returns(uint256);
  function deposit() external returns(uint256);
  function depositVault(uint256 amount, address to) external returns(uint256);
  function depositWithPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns(uint256);
  function depositWithTransferPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns(uint256);
  function getAllMinters() external view returns(address[] memory);
  function initVault(address _vault) external;
  function isMinter(address) external view returns(bool);
  function mint(address to, uint256 amount) external returns(bool);
  function minters(uint256) external view returns(address);
  function mpc() external view returns(address);
  function name() external view returns(string memory);
  function nonces(address) external view returns(uint256);
  function owner() external view returns(address);
  function pendingDelay() external view returns(uint256);
  function pendingMinter() external view returns(address);
  function pendingVault() external view returns(address);
  function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
  function revokeMinter(address _auth) external;
  function setMinter(address _auth) external;
  function setVault(address _vault) external;
  function setVaultOnly(bool enabled) external;
  function symbol() external view returns(string memory);
  function totalSupply() external view returns(uint256);
  function transfer(address to, uint256 value) external returns(bool);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns(bool);
  function transferFrom(address from, address to, uint256 value) external returns(bool);
  function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns(bool);
  function underlying() external view returns(address);
  function vault() external view returns(address);
  function withdraw(uint256 amount, address to) external returns(uint256);
  function withdraw(uint256 amount) external returns(uint256);
  function withdraw() external returns(uint256);
  function withdrawVault(address from, uint256 amount, address to) external returns(uint256);
}


// File contracts/Frax/IFrax.sol


interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}


// File contracts/FXS/IFxs.sol


interface IFxs {
  function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
  function FRAXStablecoinAdd() external view returns(address);
  function FXS_DAO_min() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
  function decimals() external view returns(uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
  function genesis_supply() external view returns(uint256);
  function getCurrentVotes(address account) external view returns(uint96);
  function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
  function getRoleAdmin(bytes32 role) external view returns(bytes32);
  function getRoleMember(bytes32 role, uint256 index) external view returns(address);
  function getRoleMemberCount(bytes32 role) external view returns(uint256);
  function grantRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns(bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
  function mint(address to, uint256 amount) external;
  function name() external view returns(string memory);
  function numCheckpoints(address) external view returns(uint32);
  function oracle_address() external view returns(address);
  function owner_address() external view returns(address);
  function pool_burn_from(address b_address, uint256 b_amount) external;
  function pool_mint(address m_address, uint256 m_amount) external;
  function renounceRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function setFRAXAddress(address frax_contract_address) external;
  function setFXSMinDAO(uint256 min_FXS) external;
  function setOracle(address new_oracle) external;
  function setOwner(address _owner_address) external;
  function setTimelock(address new_timelock) external;
  function symbol() external view returns(string memory);
  function timelock_address() external view returns(address);
  function toggleVotes() external;
  function totalSupply() external view returns(uint256);
  function trackingVotes() external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}


// File contracts/Oracle/AggregatorV3Interface.sol


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File contracts/Frax/IFraxAMOMinter.sol


// MAY need to be updated
interface IFraxAMOMinter {
  function FRAX() external view returns(address);
  function FXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnFraxFromAMO(uint256 frax_amount) external;
  function burnFxsFromAMO(uint256 fxs_amount) external;
  function col_idx() external view returns(uint256);
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 frax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function fraxDollarBalanceStored() external view returns(uint256);
  function fraxTrackedAMO(address amo_address) external view returns(int256);
  function fraxTrackedGlobal() external view returns(int256);
  function frax_mint_balances(address) external view returns(int256);
  function frax_mint_cap() external view returns(int256);
  function frax_mint_sum() external view returns(int256);
  function fxs_mint_balances(address) external view returns(int256);
  function fxs_mint_cap() external view returns(int256);
  function fxs_mint_sum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function min_cr() external view returns(uint256);
  function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
  function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 frax_amount) external;
  function old_pool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setFraxMintCap(uint256 _frax_mint_cap) external;
  function setFraxPool(address _pool_address) external;
  function setFxsMintCap(uint256 _fxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}


// File contracts/Frax/Pools/FraxPoolV3.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FraxPoolV3 ============================
// ====================================================================
// Allows multiple stablecoins (fixed amount at initialization) as collateral
// LUSD, sUSD, USDP, Wrapped UST, and FEI initially
// For this pool, the goal is to accept crypto-backed / overcollateralized stablecoins to limit
// government / regulatory risk (e.g. USDC blacklisting until holders KYC)

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett
// Hameed








contract FraxPoolV3 is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelock_address;
    address public custodian_address; // Custodian is an EOA (or msig) with pausing privileges only, in case of an emergency
    IFrax private FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IFxs private FXS = IFxs(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    mapping(address => bool) public amo_minter_addresses; // minter address -> is it enabled
    AggregatorV3Interface public priceFeedFRAXUSD = AggregatorV3Interface(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD);
    AggregatorV3Interface public priceFeedFXSUSD = AggregatorV3Interface(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
    uint256 private chainlink_frax_usd_decimals;
    uint256 private chainlink_fxs_usd_decimals;

    // Collateral
    address[] public collateral_addresses;
    string[] public collateral_symbols;
    uint256[] public missing_decimals; // Number of decimals needed to get to E18. collateral index -> missing_decimals
    uint256[] public pool_ceilings; // Total across all collaterals. Accounts for missing_decimals
    uint256[] public collateral_prices; // Stores price of the collateral, if price is paused
    mapping(address => uint256) public collateralAddrToIdx; // collateral addr -> collateral index
    mapping(address => bool) public enabled_collaterals; // collateral address -> is it enabled
    
    // Redeem related
    mapping (address => uint256) public redeemFXSBalances;
    mapping (address => mapping(uint256 => uint256)) public redeemCollateralBalances; // Address -> collateral index -> balance
    uint256[] public unclaimedPoolCollateral; // collateral index -> balance
    uint256 public unclaimedPoolFXS;
    mapping (address => uint256) public lastRedeemed; // Collateral independent
    uint256 public redemption_delay = 2; // Number of blocks to wait before being able to collectRedemption()
    uint256 public redeem_price_threshold = 990000; // $0.99
    uint256 public mint_price_threshold = 1010000; // $1.01
    
    // Buyback related
    mapping(uint256 => uint256) public bbkHourlyCum; // Epoch hour ->  Collat out in that hour (E18)
    uint256 public bbkMaxColE18OutPerHour = 1000e18;

    // Recollat related
    mapping(uint256 => uint256) public rctHourlyCum; // Epoch hour ->  FXS out in that hour
    uint256 public rctMaxFxsOutPerHour = 1000e18;

    // Fees and rates
    // getters are in collateral_information()
    uint256[] private minting_fee;
    uint256[] private redemption_fee;
    uint256[] private buyback_fee;
    uint256[] private recollat_fee;
    uint256 public bonus_rate; // Bonus rate on FXS minted during recollateralize(); 6 decimals of precision, set to 0.75% on genesis
    
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // Pause variables
    // getters are in collateral_information()
    bool[] private mintPaused; // Collateral-specific
    bool[] private redeemPaused; // Collateral-specific
    bool[] private recollateralizePaused; // Collateral-specific
    bool[] private buyBackPaused; // Collateral-specific

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyAMOMinters() {
        require(amo_minter_addresses[msg.sender], "Not an AMO Minter");
        _;
    }

    modifier collateralEnabled(uint256 col_idx) {
        require(enabled_collaterals[collateral_addresses[col_idx]], "Collateral disabled");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address _pool_manager_address,
        address _custodian_address,
        address _timelock_address,
        address[] memory _collateral_addresses,
        uint256[] memory _pool_ceilings,
        uint256[] memory _initial_fees
    ) Owned(_pool_manager_address){
        // Core
        timelock_address = _timelock_address;
        custodian_address = _custodian_address;

        // Fill collateral info
        collateral_addresses = _collateral_addresses;
        for (uint256 i = 0; i < _collateral_addresses.length; i++){ 
            // For fast collateral address -> collateral idx lookups later
            collateralAddrToIdx[_collateral_addresses[i]] = i;

            // Set all of the collaterals initially to disabled
            enabled_collaterals[_collateral_addresses[i]] = false;

            // Add in the missing decimals
            missing_decimals.push(uint256(18).sub(ERC20(_collateral_addresses[i]).decimals()));

            // Add in the collateral symbols
            collateral_symbols.push(ERC20(_collateral_addresses[i]).symbol());

            // Initialize unclaimed pool collateral
            unclaimedPoolCollateral.push(0);

            // Initialize paused prices to $1 as a backup
            collateral_prices.push(PRICE_PRECISION);

            // Handle the fees
            minting_fee.push(_initial_fees[0]);
            redemption_fee.push(_initial_fees[1]);
            buyback_fee.push(_initial_fees[2]);
            recollat_fee.push(_initial_fees[3]);

            // Handle the pauses
            mintPaused.push(false);
            redeemPaused.push(false);
            recollateralizePaused.push(false);
            buyBackPaused.push(false);
        }

        // Pool ceiling
        pool_ceilings = _pool_ceilings;

        // Set the decimals
        chainlink_frax_usd_decimals = priceFeedFRAXUSD.decimals();
        chainlink_fxs_usd_decimals = priceFeedFXSUSD.decimals();
    }

    /* ========== STRUCTS ========== */
    
    struct CollateralInformation {
        uint256 index;
        string symbol;
        address col_addr;
        bool is_enabled;
        uint256 missing_decs;
        uint256 price;
        uint256 pool_ceiling;
        bool mint_paused;
        bool redeem_paused;
        bool recollat_paused;
        bool buyback_paused;
        uint256 minting_fee;
        uint256 redemption_fee;
        uint256 buyback_fee;
        uint256 recollat_fee;
    }

    /* ========== VIEWS ========== */

    // Helpful for UIs
    function collateral_information(address collat_address) external view returns (CollateralInformation memory return_data){
        require(enabled_collaterals[collat_address], "Invalid collateral");

        // Get the index
        uint256 idx = collateralAddrToIdx[collat_address];
        
        return_data = CollateralInformation(
            idx, // [0]
            collateral_symbols[idx], // [1]
            collat_address, // [2]
            enabled_collaterals[collat_address], // [3]
            missing_decimals[idx], // [4]
            collateral_prices[idx], // [5]
            pool_ceilings[idx], // [6]
            mintPaused[idx], // [7]
            redeemPaused[idx], // [8]
            recollateralizePaused[idx], // [9]
            buyBackPaused[idx], // [10]
            minting_fee[idx], // [11]
            redemption_fee[idx], // [12]
            buyback_fee[idx], // [13]
            recollat_fee[idx] // [14]
        );
    }

    function allCollaterals() external view returns (address[] memory) {
        return collateral_addresses;
    }

    function getFRAXPrice() public view returns (uint256) {
        ( , int price, , , ) = priceFeedFRAXUSD.latestRoundData();
        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlink_frax_usd_decimals);
    }

    function getFXSPrice() public view returns (uint256) {
        ( , int price, , , ) = priceFeedFXSUSD.latestRoundData();
        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlink_fxs_usd_decimals);
    }

    // Returns the FRAX value in collateral tokens
    function getFRAXInCollateral(uint256 col_idx, uint256 frax_amount) public view returns (uint256) {
        return frax_amount.mul(PRICE_PRECISION).div(10 ** missing_decimals[col_idx]).div(collateral_prices[col_idx]);
    }

    // Used by some functions.
    function freeCollatBalance(uint256 col_idx) public view returns (uint256) {
        return ERC20(collateral_addresses[col_idx]).balanceOf(address(this)).sub(unclaimedPoolCollateral[col_idx]);
    }

    // Returns dollar value of collateral held in this Frax pool, in E18
    function collatDollarBalance() external view returns (uint256 balance_tally) {
        balance_tally = 0;

        // Test 1
        for (uint256 i = 0; i < collateral_addresses.length; i++){ 
            balance_tally += freeCollatBalance(i).mul(10 ** missing_decimals[i]).mul(collateral_prices[i]).div(PRICE_PRECISION);
        }

    }

    function comboCalcBbkRct(uint256 cur, uint256 max, uint256 theo) internal pure returns (uint256) {
        if (cur >= max) {
            // If the hourly limit has already been reached, return 0;
            return 0;
        }
        else {
            // Get the available amount
            uint256 available = max.sub(cur);

            if (theo >= available) {
                // If the the theoretical is more than the available, return the available
                return available;
            }
            else {
                // Otherwise, return the theoretical amount
                return theo;
            }
        } 
    }

    // Returns the value of excess collateral (in E18) held globally, compared to what is needed to maintain the global collateral ratio
    // Also has throttling to avoid dumps during large price movements
    function buybackAvailableCollat() public view returns (uint256) {
        uint256 total_supply = FRAX.totalSupply();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 global_collat_value = FRAX.globalCollateralValue();

        if (global_collateral_ratio > PRICE_PRECISION) global_collateral_ratio = PRICE_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(PRICE_PRECISION); // Calculates collateral needed to back each 1 FRAX with $1 of collateral at current collat ratio
        
        if (global_collat_value > required_collat_dollar_value_d18) {
            // Get the theoretical buyback amount
            uint256 theoretical_bbk_amt = global_collat_value.sub(required_collat_dollar_value_d18);

            // See how much has collateral has been issued this hour
            uint256 current_hr_bbk = bbkHourlyCum[curEpochHr()];

            // Account for the throttling
            return comboCalcBbkRct(current_hr_bbk, bbkMaxColE18OutPerHour, theoretical_bbk_amt);
        }
        else return 0;
    }

    // Returns the missing amount of collateral (in E18) needed to maintain the collateral ratio
    function recollatTheoColAvailableE18() public view returns (uint256) {
        uint256 frax_total_supply = FRAX.totalSupply();
        uint256 effective_collateral_ratio = FRAX.globalCollateralValue().mul(PRICE_PRECISION).div(frax_total_supply); // Returns it in 1e6
        
        uint256 desired_collat_e24 = (FRAX.global_collateral_ratio()).mul(frax_total_supply);
        uint256 effective_collat_e24 = effective_collateral_ratio.mul(frax_total_supply);

        // Return 0 if already overcollateralized
        // Otherwise, return the deficiency
        if (effective_collat_e24 >= desired_collat_e24) return 0;
        else {
            return (desired_collat_e24.sub(effective_collat_e24)).div(PRICE_PRECISION);
        }
    }

    // Returns the value of FXS available to be used for recollats
    // Also has throttling to avoid dumps during large price movements
    function recollatAvailableFxs() public view returns (uint256) {
        uint256 fxs_price = getFXSPrice();

        // Get the amount of collateral theoretically available
        uint256 recollat_theo_available_e18 = recollatTheoColAvailableE18();

        // Get the amount of FXS theoretically outputtable
        uint256 fxs_theo_out = recollat_theo_available_e18.mul(PRICE_PRECISION).div(fxs_price);

        // See how much FXS has been issued this hour
        uint256 current_hr_rct = rctHourlyCum[curEpochHr()];

        // Account for the throttling
        return comboCalcBbkRct(current_hr_rct, rctMaxFxsOutPerHour, fxs_theo_out);
    }

    // Returns the current epoch hour
    function curEpochHr() public view returns (uint256) {
        return (block.timestamp / 3600); // Truncation desired
    }

    /* ========== PUBLIC FUNCTIONS ========== */

     function mintFrax(
        uint256 col_idx, 
        uint256 frax_amt,
        uint256 frax_out_min,
        bool one_to_one_override
    ) external collateralEnabled(col_idx) returns (
        uint256 total_frax_mint, 
        uint256 collat_needed, 
        uint256 fxs_needed
    ) {
        require(mintPaused[col_idx] == false, "Minting is paused");

        // Prevent unneccessary mints
        require(getFRAXPrice() >= mint_price_threshold, "Frax price too low");

        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

        if (one_to_one_override || global_collateral_ratio >= PRICE_PRECISION) { 
            // 1-to-1, overcollateralized, or user selects override
            collat_needed = getFRAXInCollateral(col_idx, frax_amt);
            fxs_needed = 0;
        } else if (global_collateral_ratio == 0) { 
            // Algorithmic
            collat_needed = 0;
            fxs_needed = frax_amt.mul(PRICE_PRECISION).div(getFXSPrice());
        } else { 
            // Fractional
            uint256 frax_for_collat = frax_amt.mul(global_collateral_ratio).div(PRICE_PRECISION);
            uint256 frax_for_fxs = frax_amt.sub(frax_for_collat);
            collat_needed = getFRAXInCollateral(col_idx, frax_for_collat);
            fxs_needed = frax_for_fxs.mul(PRICE_PRECISION).div(getFXSPrice());
        }

        // Subtract the minting fee
        total_frax_mint = (frax_amt.mul(PRICE_PRECISION.sub(minting_fee[col_idx]))).div(PRICE_PRECISION);

        // Checks
        require((frax_out_min <= total_frax_mint), "FRAX slippage");
        require(freeCollatBalance(col_idx).add(collat_needed) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take the FXS and collateral first
        FXS.pool_burn_from(msg.sender, fxs_needed);
        TransferHelper.safeTransferFrom(collateral_addresses[col_idx], msg.sender, address(this), collat_needed);

        // Mint the FRAX
        FRAX.pool_mint(msg.sender, total_frax_mint);
    }

    function redeemFrax(
        uint256 col_idx, 
        uint256 frax_amount, 
        uint256 fxs_out_min, 
        uint256 col_out_min
    ) external collateralEnabled(col_idx) returns (
        uint256 collat_out, 
        uint256 fxs_out
    ) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");

        // Prevent unneccessary redemptions that could adversely affect the FXS price
        require(getFRAXPrice() <= redeem_price_threshold, "Frax price too high");

        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 frax_after_fee = (frax_amount.mul(PRICE_PRECISION.sub(redemption_fee[col_idx]))).div(PRICE_PRECISION);

        // Assumes $1 FRAX in all cases
        if(global_collateral_ratio >= PRICE_PRECISION) { 
            // 1-to-1 or overcollateralized
            collat_out = frax_after_fee
                            .mul(collateral_prices[col_idx])
                            .div(10 ** (6 + missing_decimals[col_idx])); // PRICE_PRECISION + missing decimals
            fxs_out = 0;
        } else if (global_collateral_ratio == 0) { 
            // Algorithmic
            fxs_out = frax_after_fee
                            .mul(PRICE_PRECISION)
                            .div(getFXSPrice());
            collat_out = 0;
        } else { 
            // Fractional
            collat_out = frax_after_fee
                            .mul(global_collateral_ratio)
                            .mul(collateral_prices[col_idx])
                            .div(10 ** (12 + missing_decimals[col_idx])); // PRICE_PRECISION ^2 + missing decimals
            fxs_out = frax_after_fee
                            .mul(PRICE_PRECISION.sub(global_collateral_ratio))
                            .div(getFXSPrice()); // PRICE_PRECISIONS CANCEL OUT
        }

        // Checks
        require(collat_out <= (ERC20(collateral_addresses[col_idx])).balanceOf(address(this)).sub(unclaimedPoolCollateral[col_idx]), "Insufficient pool collateral");
        require(collat_out >= col_out_min, "Collateral slippage");
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Account for the redeem delay
        redeemCollateralBalances[msg.sender][col_idx] = redeemCollateralBalances[msg.sender][col_idx].add(collat_out);
        unclaimedPoolCollateral[col_idx] = unclaimedPoolCollateral[col_idx].add(collat_out);

        redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_out);
        unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_out);

        lastRedeemed[msg.sender] = block.number;

        FRAX.pool_burn_from(msg.sender, frax_amount);
        FXS.pool_mint(address(this), fxs_out);
    }

    // After a redemption happens, transfer the newly minted FXS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out FRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption(uint256 col_idx) external returns (uint256 fxs_amount, uint256 collateral_amount) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Too soon");
        bool sendFXS = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if(redeemFXSBalances[msg.sender] > 0){
            fxs_amount = redeemFXSBalances[msg.sender];
            redeemFXSBalances[msg.sender] = 0;
            unclaimedPoolFXS = unclaimedPoolFXS.sub(fxs_amount);
            sendFXS = true;
        }
        
        if(redeemCollateralBalances[msg.sender][col_idx] > 0){
            collateral_amount = redeemCollateralBalances[msg.sender][col_idx];
            redeemCollateralBalances[msg.sender][col_idx] = 0;
            unclaimedPoolCollateral[col_idx] = unclaimedPoolCollateral[col_idx].sub(collateral_amount);
            sendCollateral = true;
        }

        // Send out the tokens
        if(sendFXS){
            TransferHelper.safeTransfer(address(FXS), msg.sender, fxs_amount);
        }
        if(sendCollateral){
            TransferHelper.safeTransfer(collateral_addresses[col_idx], msg.sender, collateral_amount);
        }
    }

    // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackFxs(uint256 col_idx, uint256 fxs_amount, uint256 col_out_min) external collateralEnabled(col_idx) returns (uint256 col_out) {
        require(buyBackPaused[col_idx] == false, "Buyback is paused");
        uint256 fxs_price = getFXSPrice();
        uint256 available_excess_collat_dv = buybackAvailableCollat();

        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible FXS with the desired collateral
        require(available_excess_collat_dv > 0, "Insuf Collat Avail For BBK");

        // Make sure not to take more than is available
        uint256 fxs_dollar_value_d18 = fxs_amount.mul(fxs_price).div(PRICE_PRECISION);
        require(fxs_dollar_value_d18 <= available_excess_collat_dv, "Insuf Collat Avail For BBK");

        // Get the equivalent amount of collateral based on the market value of FXS provided 
        uint256 collateral_equivalent_d18 = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(collateral_prices[col_idx]);
        col_out = collateral_equivalent_d18.div(10 ** missing_decimals[col_idx]); // In its natural decimals()

        // Subtract the buyback fee
        col_out = (col_out.mul(PRICE_PRECISION.sub(buyback_fee[col_idx]))).div(PRICE_PRECISION);

        // Check for slippage
        require(col_out >= col_out_min, "Collateral slippage");

        // Take in and burn the FXS, then send out the collateral
        FXS.pool_burn_from(msg.sender, fxs_amount);
        TransferHelper.safeTransfer(collateral_addresses[col_idx], msg.sender, col_out);

        // Increment the outbound collateral, in E18, for that hour
        // Used for buyback throttling
        bbkHourlyCum[curEpochHr()] += collateral_equivalent_d18;
    }

    // When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    function recollateralize(uint256 col_idx, uint256 collateral_amount, uint256 fxs_out_min) external collateralEnabled(col_idx) returns (uint256 fxs_out) {
        require(recollateralizePaused[col_idx] == false, "Recollat is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals[col_idx]);
        uint256 fxs_price = getFXSPrice();

        // Get the amount of FXS actually available (accounts for throttling)
        uint256 fxs_actually_available = recollatAvailableFxs();

        // Calculated the attempted amount of FXS
        fxs_out = collateral_amount_d18.mul(PRICE_PRECISION.add(bonus_rate).sub(recollat_fee[col_idx])).div(fxs_price);

        // Make sure there is FXS available
        require(fxs_out <= fxs_actually_available, "Insuf FXS Avail For RCT");

        // Check slippage
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Don't take in more collateral than the pool ceiling for this token allows
        require(freeCollatBalance(col_idx).add(collateral_amount) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take in the collateral and pay out the FXS
        TransferHelper.safeTransferFrom(collateral_addresses[col_idx], msg.sender, address(this), collateral_amount);
        FXS.pool_mint(msg.sender, fxs_out);

        // Increment the outbound FXS, in E18
        // Used for recollat throttling
        rctHourlyCum[curEpochHr()] += fxs_out;
    }

    // Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral
    function amoMinterBorrow(uint256 collateral_amount) external onlyAMOMinters {
        // Checks the col_idx of the minter as an additional safety check
        uint256 minter_col_idx = IFraxAMOMinter(msg.sender).col_idx();

        // Transfer
        TransferHelper.safeTransfer(collateral_addresses[minter_col_idx], msg.sender, collateral_amount);
    }

    /* ========== RESTRICTED FUNCTIONS, CUSTODIAN CAN CALL TOO ========== */

    function toggleMRBR(uint256 col_idx, uint8 tog_idx) external onlyByOwnGovCust {
        if (tog_idx == 0) mintPaused[col_idx] = !mintPaused[col_idx];
        else if (tog_idx == 1) redeemPaused[col_idx] = !redeemPaused[col_idx];
        else if (tog_idx == 2) buyBackPaused[col_idx] = !buyBackPaused[col_idx];
        else if (tog_idx == 3) recollateralizePaused[col_idx] = !recollateralizePaused[col_idx];

        emit MRBRToggled(col_idx, tog_idx);
    }

    /* ========== RESTRICTED FUNCTIONS, GOVERNANCE ONLY ========== */

    // Add an AMO Minter
    function addAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        require(amo_minter_addr != address(0), "Zero address detected");

        // Make sure the AMO Minter has collatDollarBalance()
        uint256 collat_val_e18 = IFraxAMOMinter(amo_minter_addr).collatDollarBalance();
        require(collat_val_e18 >= 0, "Invalid AMO");

        amo_minter_addresses[amo_minter_addr] = true;

        emit AMOMinterAdded(amo_minter_addr);
    }

    // Remove an AMO Minter 
    function removeAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        amo_minter_addresses[amo_minter_addr] = false;
        
        emit AMOMinterRemoved(amo_minter_addr);
    }

    function setCollateralPrice(uint256 col_idx, uint256 _new_price) external onlyByOwnGov {
        collateral_prices[col_idx] = _new_price;

        emit CollateralPriceSet(col_idx, _new_price);
    }

    // Could also be called toggleCollateral
    function toggleCollateral(uint256 col_idx) external onlyByOwnGov {
        address col_address = collateral_addresses[col_idx];
        enabled_collaterals[col_address] = !enabled_collaterals[col_address];

        emit CollateralToggled(col_idx, enabled_collaterals[col_address]);
    }

    function setPoolCeiling(uint256 col_idx, uint256 new_ceiling) external onlyByOwnGov {
        pool_ceilings[col_idx] = new_ceiling;

        emit PoolCeilingSet(col_idx, new_ceiling);
    }

    function setFees(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnGov {
        minting_fee[col_idx] = new_mint_fee;
        redemption_fee[col_idx] = new_redeem_fee;
        buyback_fee[col_idx] = new_buyback_fee;
        recollat_fee[col_idx] = new_recollat_fee;

        emit FeesSet(col_idx, new_mint_fee, new_redeem_fee, new_buyback_fee, new_recollat_fee);
    }

    function setPoolParameters(uint256 new_bonus_rate, uint256 new_redemption_delay) external onlyByOwnGov {
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        emit PoolParametersSet(new_bonus_rate, new_redemption_delay);
    }

    function setPriceThresholds(uint256 new_mint_price_threshold, uint256 new_redeem_price_threshold) external onlyByOwnGov {
        mint_price_threshold = new_mint_price_threshold;
        redeem_price_threshold = new_redeem_price_threshold;
        emit PriceThresholdsSet(new_mint_price_threshold, new_redeem_price_threshold);
    }

    function setBbkRctPerHour(uint256 _bbkMaxColE18OutPerHour, uint256 _rctMaxFxsOutPerHour) external onlyByOwnGov {
        bbkMaxColE18OutPerHour = _bbkMaxColE18OutPerHour;
        rctMaxFxsOutPerHour = _rctMaxFxsOutPerHour;
        emit BbkRctPerHourSet(_bbkMaxColE18OutPerHour, _rctMaxFxsOutPerHour);
    }

    // Set the Chainlink oracles
    function setOracles(address _frax_usd_chainlink_addr, address _fxs_usd_chainlink_addr) external onlyByOwnGov {
        // Set the instances
        priceFeedFRAXUSD = AggregatorV3Interface(_frax_usd_chainlink_addr);
        priceFeedFXSUSD = AggregatorV3Interface(_fxs_usd_chainlink_addr);

        // Set the decimals
        chainlink_frax_usd_decimals = priceFeedFRAXUSD.decimals();
        chainlink_fxs_usd_decimals = priceFeedFXSUSD.decimals();
        
        emit OraclesSet(_frax_usd_chainlink_addr, _fxs_usd_chainlink_addr);
    }

    function setCustodian(address new_custodian) external onlyByOwnGov {
        custodian_address = new_custodian;

        emit CustodianSet(new_custodian);
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    /* ========== EVENTS ========== */
    event CollateralToggled(uint256 col_idx, bool new_state);
    event PoolCeilingSet(uint256 col_idx, uint256 new_ceiling);
    event FeesSet(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee);
    event PoolParametersSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event PriceThresholdsSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event BbkRctPerHourSet(uint256 bbkMaxColE18OutPerHour, uint256 rctMaxFxsOutPerHour);
    event AMOMinterAdded(address amo_minter_addr);
    event AMOMinterRemoved(address amo_minter_addr);
    event OraclesSet(address frax_usd_chainlink_addr, address fxs_usd_chainlink_addr);
    event CustodianSet(address new_custodian);
    event TimelockSet(address new_timelock);
    event MRBRToggled(uint256 col_idx, uint8 tog_idx);
    event CollateralPriceSet(uint256 col_idx, uint256 new_price);
}


// File contracts/Frax/Pools/IFraxPool.sol


interface IFraxPool {
    function minting_fee() external returns (uint256);
    function redeemCollateralBalances(address addr) external returns (uint256);
    function redemption_fee() external returns (uint256);
    function buyback_fee() external returns (uint256);
    function recollat_fee() external returns (uint256);
    function collatDollarBalance() external returns (uint256);
    function availableExcessCollatDV() external returns (uint256);
    function getCollateralPrice() external returns (uint256);
    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external;
    function mint1t1FRAX(uint256 collateral_amount, uint256 FRAX_out_min) external;
    function mintAlgorithmicFRAX(uint256 fxs_amount_d18, uint256 FRAX_out_min) external;
    function mintFractionalFRAX(uint256 collateral_amount, uint256 fxs_amount, uint256 FRAX_out_min) external;
    function redeem1t1FRAX(uint256 FRAX_amount, uint256 COLLATERAL_out_min) external;
    function redeemFractionalFRAX(uint256 FRAX_amount, uint256 FXS_out_min, uint256 COLLATERAL_out_min) external;
    function redeemAlgorithmicFRAX(uint256 FRAX_amount, uint256 FXS_out_min) external;
    function collectRedemption() external;
    function recollateralizeFRAX(uint256 collateral_amount, uint256 FXS_out_min) external;
    function buyBackFXS(uint256 FXS_amount, uint256 COLLATERAL_out_min) external;
    function toggleMinting() external;
    function toggleRedeeming() external;
    function toggleRecollateralize() external;
    function toggleBuyBack() external;
    function toggleCollateralPrice(uint256 _new_price) external;
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external;
    function setTimelock(address new_timelock) external;
    function setOwner(address _owner_address) external;
}


// File contracts/Misc_AMOs/IAMO.sol

pragma experimental ABIEncoderV2;

interface IAMO {
    function dollarBalances() external view returns (uint256 frax_val_e18, uint256 collat_val_e18);
}


// File contracts/Frax/FraxAMOMinter.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== FraxAMOMinter ==========================
// ====================================================================
// globalCollateralValue() in Frax.sol is gassy because of the loop and all of the AMOs attached to it. 
// This minter would be single mint point for all of the AMOs, and would track the collatDollarBalance with a
// state variable after any mint occurs, or manually with a sync() call
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett
// Hameed









contract FraxAMOMinter is Owned {
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    IFrax public FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IFxs public FXS = IFxs(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    ERC20 public collateral_token;
    FraxPoolV3 public pool = FraxPoolV3(0x2fE065e6FFEf9ac95ab39E5042744d695F560729);
    IFraxPool public old_pool = IFraxPool(0x1864Ca3d47AaB98Ee78D11fc9DCC5E7bADdA1c0d);
    address public timelock_address;
    address public custodian_address;

    // Collateral related
    address public collateral_address;
    uint256 public col_idx;

    // AMO addresses
    address[] public amos_array;
    mapping(address => bool) public amos; // Mapping is also used for faster verification

    // Price constants
    uint256 private constant PRICE_PRECISION = 1e6;

    // Max amount of collateral the contract can borrow from the FraxPool
    int256 public collat_borrow_cap = int256(10000000e6);

    // Max amount of FRAX and FXS this contract can mint
    int256 public frax_mint_cap = int256(100000000e18);
    int256 public fxs_mint_cap = int256(100000000e18);

    // Minimum collateral ratio needed for new FRAX minting
    uint256 public min_cr = 810000;

    // Frax mint balances
    mapping(address => int256) public frax_mint_balances; // Amount of FRAX the contract minted, by AMO
    int256 public frax_mint_sum = 0; // Across all AMOs

    // Fxs mint balances
    mapping(address => int256) public fxs_mint_balances; // Amount of FXS the contract minted, by AMO
    int256 public fxs_mint_sum = 0; // Across all AMOs

    // Collateral borrowed balances
    mapping(address => int256) public collat_borrowed_balances; // Amount of collateral the contract borrowed, by AMO
    int256 public collat_borrowed_sum = 0; // Across all AMOs

    // FRAX balance related
    uint256 public fraxDollarBalanceStored = 0;

    // Collateral balance related
    uint256 public missing_decimals;
    uint256 public collatDollarBalanceStored = 0;

    // AMO balance corrections
    mapping(address => int256[2]) public correction_offsets_amos;
    // [amo_address][0] = AMO's frax_val_e18
    // [amo_address][1] = AMO's collat_val_e18

    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address _owner_address,
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _pool_address
    ) Owned(_owner_address) {
        custodian_address = _custodian_address;
        timelock_address = _timelock_address;

        // Pool related
        pool = FraxPoolV3(_pool_address);

        // Collateral related
        collateral_address = _collateral_address;
        col_idx = pool.collateralAddrToIdx(_collateral_address);
        collateral_token = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        missing_decimals = uint(18) - collateral_token.decimals();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier validAMO(address amo_address) {
        require(amos[amo_address], "Invalid AMO");
        _;
    }

    /* ========== VIEWS ========== */

    function collatDollarBalance() external view returns (uint256) {
        (, uint256 collat_val_e18) = dollarBalances();
        return collat_val_e18;
    }

    function dollarBalances() public view returns (uint256 frax_val_e18, uint256 collat_val_e18) {
        frax_val_e18 = fraxDollarBalanceStored;
        collat_val_e18 = collatDollarBalanceStored;
    }

    function allAMOAddresses() external view returns (address[] memory) {
        return amos_array;
    }

    function allAMOsLength() external view returns (uint256) {
        return amos_array.length;
    }

    function fraxTrackedGlobal() external view returns (int256) {
        return int256(fraxDollarBalanceStored) - frax_mint_sum - (collat_borrowed_sum * int256(10 ** missing_decimals));
    }

    function fraxTrackedAMO(address amo_address) external view returns (int256) {
        (uint256 frax_val_e18, ) = IAMO(amo_address).dollarBalances();
        int256 frax_val_e18_corrected = int256(frax_val_e18) + correction_offsets_amos[amo_address][0];
        return frax_val_e18_corrected - frax_mint_balances[amo_address] - ((collat_borrowed_balances[amo_address]) * int256(10 ** missing_decimals));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Callable by anyone willing to pay the gas
    function syncDollarBalances() public {
        uint256 total_frax_value_d18 = 0;
        uint256 total_collateral_value_d18 = 0; 
        for (uint i = 0; i < amos_array.length; i++){ 
            // Exclude null addresses
            address amo_address = amos_array[i];
            if (amo_address != address(0)){
                (uint256 frax_val_e18, uint256 collat_val_e18) = IAMO(amo_address).dollarBalances();
                total_frax_value_d18 += uint256(int256(frax_val_e18) + correction_offsets_amos[amo_address][0]);
                total_collateral_value_d18 += uint256(int256(collat_val_e18) + correction_offsets_amos[amo_address][1]);
            }
        }
        fraxDollarBalanceStored = total_frax_value_d18;
        collatDollarBalanceStored = total_collateral_value_d18;
    }

    /* ========== OLD POOL / BACKWARDS COMPATIBILITY ========== */

    function oldPoolRedeem(uint256 frax_amount) external onlyByOwnGov {
        uint256 redemption_fee = old_pool.redemption_fee();
        uint256 col_price_usd = old_pool.getCollateralPrice();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 redeem_amount_E6 = ((frax_amount * (uint256(1e6) - redemption_fee)) / 1e6) / (10 ** missing_decimals);
        uint256 expected_collat_amount = (redeem_amount_E6 * global_collateral_ratio) / 1e6;
        expected_collat_amount = (expected_collat_amount * 1e6) / col_price_usd;

        require((collat_borrowed_sum + int256(expected_collat_amount)) <= collat_borrow_cap, "Borrow cap");
        collat_borrowed_sum += int256(expected_collat_amount);

        // Mint the frax 
        FRAX.pool_mint(address(this), frax_amount);

        // Redeem the frax
        FRAX.approve(address(old_pool), frax_amount);
        old_pool.redeemFractionalFRAX(frax_amount, 0, 0);
    }

    function oldPoolCollectAndGive(address destination_amo) external onlyByOwnGov validAMO(destination_amo) {
        // Get the amount to be collected
        uint256 collat_amount = old_pool.redeemCollateralBalances(address(this));
        
        // Collect the redemption
        old_pool.collectRedemption();

        // Mark the destination amo's borrowed amount
        collat_borrowed_balances[destination_amo] += int256(collat_amount);

        // Give the collateral to the AMO
        TransferHelper.safeTransfer(collateral_address, destination_amo, collat_amount);

        // Sync
        syncDollarBalances();
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    // Only owner or timelock can call, to limit risk 

    // ------------------------------------------------------------------
    // ------------------------------ FRAX ------------------------------
    // ------------------------------------------------------------------

    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main FRAX contract
    function mintFraxForAMO(address destination_amo, uint256 frax_amount) external onlyByOwnGov validAMO(destination_amo) {
        int256 frax_amt_i256 = int256(frax_amount);

        // Make sure you aren't minting more than the mint cap
        require((frax_mint_sum + frax_amt_i256) <= frax_mint_cap, "Mint cap reached");
        frax_mint_balances[destination_amo] += frax_amt_i256;
        frax_mint_sum += frax_amt_i256;

        // Make sure the FRAX minting wouldn't push the CR down too much
        // This is also a sanity check for the int256 math
        uint256 current_collateral_E18 = FRAX.globalCollateralValue();
        uint256 cur_frax_supply = FRAX.totalSupply();
        uint256 new_frax_supply = cur_frax_supply + frax_amount;
        uint256 new_cr = (current_collateral_E18 * PRICE_PRECISION) / new_frax_supply;
        require(new_cr >= min_cr, "CR would be too low");

        // Mint the FRAX to the AMO
        FRAX.pool_mint(destination_amo, frax_amount);

        // Sync
        syncDollarBalances();
    }

    function burnFraxFromAMO(uint256 frax_amount) external validAMO(msg.sender) {
        int256 frax_amt_i256 = int256(frax_amount);

        // Burn first
        FRAX.pool_burn_from(msg.sender, frax_amount);

        // Then update the balances
        frax_mint_balances[msg.sender] -= frax_amt_i256;
        frax_mint_sum -= frax_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // ------------------------------- FXS ------------------------------
    // ------------------------------------------------------------------

    function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external onlyByOwnGov validAMO(destination_amo) {
        int256 fxs_amt_i256 = int256(fxs_amount);

        // Make sure you aren't minting more than the mint cap
        require((fxs_mint_sum + fxs_amt_i256) <= fxs_mint_cap, "Mint cap reached");
        fxs_mint_balances[destination_amo] += fxs_amt_i256;
        fxs_mint_sum += fxs_amt_i256;

        // Mint the FXS to the AMO
        FXS.pool_mint(destination_amo, fxs_amount);

        // Sync
        syncDollarBalances();
    }

    function burnFxsFromAMO(uint256 fxs_amount) external validAMO(msg.sender) {
        int256 fxs_amt_i256 = int256(fxs_amount);

        // Burn first
        FXS.pool_burn_from(msg.sender, fxs_amount);

        // Then update the balances
        fxs_mint_balances[msg.sender] -= fxs_amt_i256;
        fxs_mint_sum -= fxs_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // --------------------------- Collateral ---------------------------
    // ------------------------------------------------------------------

    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) external onlyByOwnGov validAMO(destination_amo) {
        int256 collat_amount_i256 = int256(collat_amount);

        require((collat_borrowed_sum + collat_amount_i256) <= collat_borrow_cap, "Borrow cap");
        collat_borrowed_balances[destination_amo] += collat_amount_i256;
        collat_borrowed_sum += collat_amount_i256;

        // Borrow the collateral
        pool.amoMinterBorrow(collat_amount);

        // Give the collateral to the AMO
        TransferHelper.safeTransfer(collateral_address, destination_amo, collat_amount);

        // Sync
        syncDollarBalances();
    }

    function receiveCollatFromAMO(uint256 usdc_amount) external validAMO(msg.sender) {
        int256 collat_amt_i256 = int256(usdc_amount);

        // Give back first
        TransferHelper.safeTransferFrom(collateral_address, msg.sender, address(pool), usdc_amount);

        // Then update the balances
        collat_borrowed_balances[msg.sender] -= collat_amt_i256;
        collat_borrowed_sum -= collat_amt_i256;

        // Sync
        syncDollarBalances();
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    // Adds an AMO 
    function addAMO(address amo_address, bool sync_too) public onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");

        (uint256 frax_val_e18, uint256 collat_val_e18) = IAMO(amo_address).dollarBalances();
        require(frax_val_e18 >= 0 && collat_val_e18 >= 0, "Invalid AMO");

        require(amos[amo_address] == false, "Address already exists");
        amos[amo_address] = true; 
        amos_array.push(amo_address);

        // Mint balances
        frax_mint_balances[amo_address] = 0;
        fxs_mint_balances[amo_address] = 0;
        collat_borrowed_balances[amo_address] = 0;

        // Offsets
        correction_offsets_amos[amo_address][0] = 0;
        correction_offsets_amos[amo_address][1] = 0;

        if (sync_too) syncDollarBalances();

        emit AMOAdded(amo_address);
    }

    // Removes an AMO
    function removeAMO(address amo_address, bool sync_too) public onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");
        require(amos[amo_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete amos[amo_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < amos_array.length; i++){ 
            if (amos_array[i] == amo_address) {
                amos_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        if (sync_too) syncDollarBalances();

        emit AMORemoved(amo_address);
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        require(_custodian_address != address(0), "Custodian address cannot be 0");        
        custodian_address = _custodian_address;
    }

    function setFraxMintCap(uint256 _frax_mint_cap) external onlyByOwnGov {
        frax_mint_cap = int256(_frax_mint_cap);
    }

    function setFxsMintCap(uint256 _fxs_mint_cap) external onlyByOwnGov {
        fxs_mint_cap = int256(_fxs_mint_cap);
    }

    function setCollatBorrowCap(uint256 _collat_borrow_cap) external onlyByOwnGov {
        collat_borrow_cap = int256(_collat_borrow_cap);
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnGov {
        min_cr = _min_cr;
    }

    function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external onlyByOwnGov {
        correction_offsets_amos[amo_address][0] = frax_e18_correction;
        correction_offsets_amos[amo_address][1] = collat_e18_correction;

        syncDollarBalances();
    }

    function setFraxPool(address _pool_address) external onlyByOwnGov {
        pool = FraxPoolV3(_pool_address);

        // Make sure the collaterals match, or balances could get corrupted
        require(pool.collateralAddrToIdx(collateral_address) == col_idx, "col_idx mismatch");
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Can only be triggered by owner or governance
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        
        emit Recovered(tokenAddress, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }

    /* ========== EVENTS ========== */

    event AMOAdded(address amo_address);
    event AMORemoved(address amo_address);
    event Recovered(address token, uint256 amount);
}


// File contracts/ERC20/SafeERC20.sol




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


// File contracts/Oracle/ICrossChainOracle.sol


interface ICrossChainOracle {
    // Returns in USD E6
    function getPrice(address token_address) external view returns (uint256 token_price);
}


// File contracts/Misc_AMOs/ICrossChainAMO.sol


interface ICrossChainAMO {
    function allDollarBalances() external view returns (uint256 frax_val_e18, uint256 fxs_val_e18, uint256 collat_val_e18, uint256 total_val_e18);
}


// File contracts/Bridges/CrossChainBridgeBacker.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== CrossChainBridgeBacker ======================
// ====================================================================
// Takes FRAX, FXS, and collateral and bridges it back to the Ethereum Mainnet
// Allows withdrawals to designated AMOs
// Tokens will need to be bridged to the contract first

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian










contract CrossChainBridgeBacker is Owned {
    // SafeMath automatically included in Solidity >= 8.0.0
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    // Core
    IAnyswapV4ERC20 public anyFRAX;
    CrossChainCanonical public canFRAX;
    IAnyswapV4ERC20 public anyFXS;
    CrossChainCanonical public canFXS;
    ERC20 public collateral_token;
    ICrossChainOracle public cross_chain_oracle;

    // Admin addresses
    address public timelock_address;

    // AMO addresses
    address[] public amos_array;
    mapping(address => bool) public eoa_amos; // These need to be tracked so allBalances() skips them
    mapping(address => bool) public amos; // Mapping is also used for faster verification
    
    // Informational
    string public name;

    // Price constants
    uint256 private constant PRICE_PRECISION = 1e6;

    // Bridge related
    address[3] public bridge_addresses;
    address public destination_address_override;
    string public non_evm_destination_address;

    // Frax lent balances
    mapping(address => uint256) public frax_lent_balances; // Amount of FRAX the contract lent, by AMO
    uint256 public frax_lent_sum = 0; // Across all AMOs
    uint256 public frax_bridged_back_sum = 0; // Across all AMOs

    // Fxs lent balances
    mapping(address => uint256) public fxs_lent_balances; // Amount of FXS the contract lent, by AMO
    uint256 public fxs_lent_sum = 0; // Across all AMOs
    uint256 public fxs_bridged_back_sum = 0; // Across all AMOs

    // Collateral lent balances
    mapping(address => uint256) public collat_lent_balances; // Amount of collateral the contract lent, by AMO
    uint256 public collat_lent_sum = 0; // Across all AMOs
    uint256 public collat_bridged_back_sum = 0; // Across all AMOs

    // Collateral balance related
    uint256 public missing_decimals;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
        _;
    }

    modifier validAMO(address amo_address) {
        require(amos[amo_address], "Invalid AMO");
        _;
    }

    modifier validCanonicalToken(address token_address) {
        require (
                token_address == address(canFRAX) || 
                token_address == address(canFXS) ||
                token_address == address(collateral_token), "Invalid canonical token"
            );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _owner,
        address _timelock_address,
        address _cross_chain_oracle_address,
        address[5] memory _token_addresses,
        address[3] memory _bridge_addresses,
        address _destination_address_override,
        string memory _non_evm_destination_address,
        string memory _name
    ) Owned(_owner) {
        // Core
        timelock_address = _timelock_address;
        cross_chain_oracle = ICrossChainOracle(_cross_chain_oracle_address);
        anyFRAX = IAnyswapV4ERC20(_token_addresses[0]);
        canFRAX = CrossChainCanonical(_token_addresses[1]);
        anyFXS = IAnyswapV4ERC20(_token_addresses[2]);
        canFXS = CrossChainCanonical(_token_addresses[3]);
        collateral_token = ERC20(_token_addresses[4]);
        missing_decimals = uint(18) - collateral_token.decimals();

        // Bridge related
        bridge_addresses = _bridge_addresses;
        destination_address_override = _destination_address_override;
        non_evm_destination_address = _non_evm_destination_address;

        // Informational
        name = _name;

        // Add this bridger as an AMO. Cannot used the addAMO function
        amos[address(this)] = true; 
        amos_array.push(address(this));
        frax_lent_balances[address(this)] = 0;
        fxs_lent_balances[address(this)] = 0;
        collat_lent_balances[address(this)] = 0;
    }


    /* ========== VIEWS ========== */

    function allAMOAddresses() external view returns (address[] memory) {
        return amos_array;
    }

    function allAMOsLength() external view returns (uint256) {
        return amos_array.length;
    }

    function getTokenType(address token_address) public view returns (uint256) {
        // 0 = FRAX, 1 = FXS, 2 = Collateral
        if (token_address == address(anyFRAX) || token_address == address(canFRAX)) return 0;
        else if (token_address == address(anyFXS) || token_address == address(canFXS)) return 1;
        else if (token_address == address(collateral_token)) return 2;

        // Revert on invalid tokens
        revert("getTokenType: Invalid token");
    }

    function showTokenBalances() public view returns (uint256[5] memory tkn_bals) {
        tkn_bals[0] = anyFRAX.balanceOf(address(this)); // anyFRAX
        tkn_bals[1] = canFRAX.balanceOf(address(this)); // canFRAX
        tkn_bals[2] = anyFXS.balanceOf(address(this)); // anyFXS
        tkn_bals[3] = canFXS.balanceOf(address(this)); // canFXS
        tkn_bals[4] = collateral_token.balanceOf(address(this)); // anyFRAX
    }

    function showAllocations() public view returns (uint256[12] memory allocations) {
        // All numbers given are in FRAX unless otherwise stated

        // Get some token balances
        uint256[5] memory tkn_bals = showTokenBalances();

        // FRAX
        allocations[0] = tkn_bals[0] + tkn_bals[1]; // Free FRAX
        allocations[1] = frax_lent_sum; // Lent FRAX
        allocations[2] = allocations[0] + allocations[1]; // Total FRAX

        // FXS
        allocations[3] = tkn_bals[2] + tkn_bals[3]; // Free FXS
        allocations[4] = fxs_lent_sum; // Lent FXS
        allocations[5] = allocations[3] + allocations[4]; // Total FXS
        allocations[6] = (allocations[5] * (cross_chain_oracle.getPrice(address(canFXS)))) / PRICE_PRECISION; // Total FXS value in USD

        // Collateral
        allocations[7] = tkn_bals[4]; // Free Collateral
        allocations[8] = collat_lent_sum; // Lent Collateral
        allocations[9] = allocations[7] + allocations[8]; // Total Collateral, in native decimals()
        allocations[10] = allocations[9] * (10 ** missing_decimals); // Total Collateral, in E18
    
        // Total USD value of everything, in E18
        allocations[11] = allocations[2] + allocations[6] + allocations[10];
    }

    function allBalances() public view returns (
        uint256 frax_ttl, 
        uint256 fxs_ttl,
        uint256 col_ttl, // in native decimals()
        uint256 ttl_val_usd_e18
    ) {
        // Handle this contract first (amos_array[0])
        uint256[12] memory allocations = showAllocations();
        frax_ttl = allocations[2];
        fxs_ttl = allocations[5];
        col_ttl = allocations[9];
        ttl_val_usd_e18 = allocations[11];

        // [0] will always be this address, so skip it to avoid an infinite loop 
        for (uint i = 1; i < amos_array.length; i++){ 
            // Exclude null addresses and EOAs
            if (amos_array[i] != address(0) && !eoa_amos[amos_array[i]]){
                (
                    uint256 frax_bal, 
                    uint256 fxs_bal, 
                    uint256 collat_bal,
                    uint256 total_val_e18
                ) = ICrossChainAMO(amos_array[i]).allDollarBalances();

                frax_ttl += frax_bal;
                fxs_ttl += fxs_bal;
                col_ttl += collat_bal;
                ttl_val_usd_e18 += total_val_e18;
            }
        }
    }


    /* ========== BRIDGING / AMO FUNCTIONS ========== */

    // Used for crumbs and drop-ins sitting in this contract
    // Can also manually bridge back anyFRAX
    // If do_swap is true, it will swap out canTokens in this contract for anyTokens in the canToken contracts
    function selfBridge(uint256 token_type, uint256 token_amount, bool do_swap) external onlyByOwnGov {
        require(token_type == 0 || token_type == 1 || token_type == 2, 'Invalid token type');

        _receiveBack(address(this), token_type, token_amount, true, do_swap);
    }

    // AMOs should only be giving back canonical tokens
    function receiveBackViaAMO(address canonical_token_address, uint256 token_amount, bool do_bridging) external validCanonicalToken(canonical_token_address) validAMO(msg.sender) {
        // Pull in the tokens from the AMO
        TransferHelper.safeTransferFrom(canonical_token_address, msg.sender, address(this), token_amount);

        // Get the token type
        uint256 token_type = getTokenType(canonical_token_address); 

        _receiveBack(msg.sender, token_type, token_amount, do_bridging, true);
    }

    // Optionally bridge
    function _receiveBack(address from_address, uint256 token_type, uint256 token_amount, bool do_bridging, bool do_swap) internal {


        if (do_bridging) {
            // Swap canTokens for bridgeable anyTokens, if necessary
            if (token_type == 0) {
                // FRAX
                // Swap the canonical tokens out for bridgeable anyTokens
                if (do_swap) _swapCanonicalForAny(0, token_amount);
            }
            else if (token_type == 1){
                // FXS
                // Swap the canonical tokens out for bridgeable anyTokens
                if (do_swap) _swapCanonicalForAny(1, token_amount);
            }

            // Defaults to sending to this contract's address on the other side
            address address_to_send_to = address(this);

            // See if there is an overriden destination
            if (destination_address_override != address(0)) address_to_send_to = destination_address_override;

            // Can be overridden
            _bridgingLogic(token_type, address_to_send_to, token_amount);
        }

        // Account for the lent balances
        if (token_type == 0){
            if (token_amount >= frax_lent_balances[from_address]) frax_lent_balances[from_address] = 0;
            else frax_lent_balances[from_address] -= token_amount;

            if (token_amount >= frax_lent_sum) frax_lent_sum = 0;
            else frax_lent_sum -= token_amount;

            if (do_bridging) frax_bridged_back_sum += token_amount;
        }
        else if (token_type == 1){
            if (token_amount >= fxs_lent_balances[from_address]) fxs_lent_balances[from_address] = 0;
            else fxs_lent_balances[from_address] -= token_amount;

            if (token_amount >= fxs_lent_sum) fxs_lent_sum = 0;
            else fxs_lent_sum -= token_amount;

            if (do_bridging) fxs_bridged_back_sum += token_amount;
        }
        else {
            if (token_amount >= collat_lent_balances[from_address]) collat_lent_balances[from_address] = 0;
            else collat_lent_balances[from_address] -= token_amount;

            if (token_amount >= collat_lent_sum) collat_lent_sum = 0;
            else collat_lent_sum -= token_amount;

            if (do_bridging) collat_bridged_back_sum += token_amount;
        }
    }

    // Meant to be overriden
    function _bridgingLogic(uint256 token_type, address address_to_send_to, uint256 token_amount) internal virtual {
        revert("Need bridging logic");
    }

    /* ========== LENDING FUNCTIONS ========== */

    // Lend out canonical FRAX
    function lendFraxToAMO(address destination_amo, uint256 frax_amount) external onlyByOwnGov validAMO(destination_amo) {
        // Track the balances
        frax_lent_balances[destination_amo] += frax_amount;
        frax_lent_sum += frax_amount;

        // Transfer
        TransferHelper.safeTransfer(address(canFRAX), destination_amo, frax_amount);
    }

    // Lend out canonical FXS
    function lendFxsToAMO(address destination_amo, uint256 fxs_amount) external onlyByOwnGov validAMO(destination_amo) {
        // Track the balances
        fxs_lent_balances[destination_amo] += fxs_amount;
        fxs_lent_sum += fxs_amount;

        // Transfer
        TransferHelper.safeTransfer(address(canFXS), destination_amo, fxs_amount);
    }

    // Lend out collateral
    function lendCollatToAMO(address destination_amo, uint256 collat_amount) external onlyByOwnGov validAMO(destination_amo) {
        // Track the balances
        collat_lent_balances[destination_amo] += collat_amount;
        collat_lent_sum += collat_amount;

        // Transfer
        TransferHelper.safeTransfer(address(collateral_token), destination_amo, collat_amount);
    }


    /* ========== SWAPPING, GIVING, MINTING, AND BURNING ========== */
    
    // ----------------- SWAPPING -----------------

    // Swap anyToken for canToken [GOVERNANCE CALLABLE]
    function swapAnyForCanonical(uint256 token_type, uint256 token_amount) external onlyByOwnGov {
        _swapAnyForCanonical(token_type, token_amount);
    }

    // Swap anyToken for canToken [INTERNAL]
    function _swapAnyForCanonical(uint256 token_type, uint256 token_amount) internal {
        if (token_type == 0) {
            // FRAX
            // Approve and swap
            anyFRAX.approve(address(canFRAX), token_amount);
            canFRAX.exchangeOldForCanonical(address(anyFRAX), token_amount);
        }
        else {
            // FXS
            // Approve and swap
            anyFXS.approve(address(canFXS), token_amount);
            canFXS.exchangeOldForCanonical(address(anyFXS), token_amount);
        }
    }

    // Swap canToken for anyToken [GOVERNANCE CALLABLE]
    function swapCanonicalForAny(uint256 token_type, uint256 token_amount) external onlyByOwnGov {
        _swapCanonicalForAny(token_type, token_amount);
    }

    // Swap anyToken for canToken [INTERNAL]
    function _swapCanonicalForAny(uint256 token_type, uint256 token_amount) internal {
        if (token_type == 0) {
            // FRAX
            // Approve and swap
            canFRAX.approve(address(canFRAX), token_amount);
            canFRAX.exchangeCanonicalForOld(address(anyFRAX), token_amount);
        }
        else {
            // FXS
            // Approve and swap
            canFXS.approve(address(canFXS), token_amount);
            canFXS.exchangeCanonicalForOld(address(anyFXS), token_amount);
        }
    }

    // ----------------- GIVING -----------------

    // Give anyToken to the canToken contract
    function giveAnyToCan(uint256 token_type, uint256 token_amount) external onlyByOwnGov {
        if (token_type == 0) {
            // FRAX
            // Transfer
            TransferHelper.safeTransfer(address(anyFRAX), address(canFRAX), token_amount);
        }
        else {
            // FXS
            // Transfer
            TransferHelper.safeTransfer(address(anyFXS), address(canFXS), token_amount);
        }
    }

    // ----------------- FRAX -----------------

    function mintCanonicalFrax(uint256 frax_amount) external onlyByOwnGov {
        canFRAX.minter_mint(address(this), frax_amount);
    }

    function burnCanonicalFrax(uint256 frax_amount) external onlyByOwnGov {
        canFRAX.minter_burn(frax_amount);
    }

    // ----------------- FXS -----------------

    function mintCanonicalFxs(uint256 fxs_amount) external onlyByOwnGov {
        canFXS.minter_mint(address(this), fxs_amount);
    }

    function burnCanonicalFxs(uint256 fxs_amount) external onlyByOwnGov {
        canFXS.minter_burn(fxs_amount);
    }


    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    function collectBridgeTokens(uint256 token_type, address bridge_token_address, uint256 token_amount) external onlyByOwnGov {
        if (token_type == 0) {
            canFRAX.withdrawBridgeTokens(bridge_token_address, token_amount);
        }
        else if (token_type == 1) {
            canFXS.withdrawBridgeTokens(bridge_token_address, token_amount);
        }
        else {
            revert("Invalid token_type");
        }
    }
    
    // Adds an AMO 
    function addAMO(address amo_address, bool is_eoa) external onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");

        if (is_eoa) {
            eoa_amos[amo_address] = true;
        }
        else {
            (uint256 frax_val_e18, uint256 fxs_val_e18, uint256 collat_val_e18, uint256 total_val_e18) = ICrossChainAMO(amo_address).allDollarBalances();
            require(frax_val_e18 >= 0 && fxs_val_e18 >= 0 && collat_val_e18 >= 0 && total_val_e18 >= 0, "Invalid AMO");
        }

        require(amos[amo_address] == false, "Address already exists");
        amos[amo_address] = true; 
        amos_array.push(amo_address);

        frax_lent_balances[amo_address] = 0;
        fxs_lent_balances[amo_address] = 0;
        collat_lent_balances[amo_address] = 0;

        emit AMOAdded(amo_address);
    }

    // Removes an AMO
    function removeAMO(address amo_address) external onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");
        require(amos[amo_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete amos[amo_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < amos_array.length; i++){ 
            if (amos_array[i] == amo_address) {
                amos_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit AMORemoved(amo_address);
    }
    
    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function setOracleAddress(address _new_cc_oracle_address) external onlyByOwnGov {
        cross_chain_oracle = ICrossChainOracle(_new_cc_oracle_address);
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }

    function setBridgeInfo(
        address _frax_bridge_address, 
        address _fxs_bridge_address, 
        address _collateral_bridge_address, 
        address _destination_address_override, 
        string memory _non_evm_destination_address
    ) external onlyByOwnGov {
        // Make sure there are valid bridges
        require(
            _frax_bridge_address != address(0) && 
            _fxs_bridge_address != address(0) &&
            _collateral_bridge_address != address(0)
        , "Invalid bridge address");

        // Set bridge addresses
        bridge_addresses = [_frax_bridge_address, _fxs_bridge_address, _collateral_bridge_address];
        
        // Overridden cross-chain destination address
        destination_address_override = _destination_address_override;

        // Set bytes32 / non-EVM address on the other chain, if applicable
        non_evm_destination_address = _non_evm_destination_address;
        
        emit BridgeInfoChanged(_frax_bridge_address, _fxs_bridge_address, _collateral_bridge_address, _destination_address_override, _non_evm_destination_address);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }


    /* ========== EVENTS ========== */

    event AMOAdded(address amo_address);
    event AMORemoved(address amo_address);
    event RecoveredERC20(address token, uint256 amount);
    event BridgeInfoChanged(address frax_bridge_address, address fxs_bridge_address, address collateral_bridge_address, address destination_address_override, string non_evm_destination_address);
}


// File contracts/Bridges/BSC/CrossChainBridgeBacker_BSC_AnySwap.sol



contract CrossChainBridgeBacker_BSC_AnySwap is CrossChainBridgeBacker {
    constructor (
        address _owner,
        address _timelock_address,
        address _cross_chain_oracle_address,
        address[5] memory _token_addresses,
        address[3] memory _bridge_addresses,
        address _destination_address_override,
        string memory _non_evm_destination_address,
        string memory _name
    ) 
    CrossChainBridgeBacker(_owner, _timelock_address, _cross_chain_oracle_address, _token_addresses, _bridge_addresses, _destination_address_override, _non_evm_destination_address, _name)
    {}

    // Override with logic specific to this chain
    function _bridgingLogic(uint256 token_type, address address_to_send_to, uint256 token_amount) internal override {
        // [BSC]
        if (token_type == 0){
            // anyFRAX -> L1 FRAX
            // Swapout
            // AnySwap Bridge
            anyFRAX.Swapout(token_amount, address_to_send_to);
        }
        else if (token_type == 1) {
            // anyFXS -> L1 FXS
            // Swapout
            // AnySwap Bridge
            anyFXS.Swapout(token_amount, address_to_send_to);
        }
        else {
            // Binance Bridge
            revert("Collateral bridging disabled");
        }
    }
}


// File contracts/Misc_AMOs/apeswap/IApePair.sol


/*
 * ApeSwapFinance 
 * App:             https://apeswap.finance
 * Medium:          https://medium.com/@ape_swap    
 * Twitter:         https://twitter.com/ape_swap 
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

interface IApePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/Misc_AMOs/apeswap/IApeRouter.sol


interface IApeRouter {
  function WETH (  ) external view returns ( address );
  function addLiquidity ( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB, uint256 liquidity );
  function addLiquidityETH ( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH, uint256 liquidity );
  function factory (  ) external view returns ( address );
  function getAmountIn ( uint256 amountOut, uint256 reserveIn, uint256 reserveOut ) external pure returns ( uint256 amountIn );
  function getAmountOut ( uint256 amountIn, uint256 reserveIn, uint256 reserveOut ) external pure returns ( uint256 amountOut );
  function getAmountsIn ( uint256 amountOut, address[] calldata path ) external view returns ( uint256[] memory amounts );
  function getAmountsOut ( uint256 amountIn, address[] calldata path ) external view returns ( uint256[] memory amounts );
  function quote ( uint256 amountA, uint256 reserveA, uint256 reserveB ) external pure returns ( uint256 amountB );
  function removeLiquidity ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB );
  function removeLiquidityETH ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH );
  function removeLiquidityETHSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountETH );
  function removeLiquidityETHWithPermit ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountToken, uint256 amountETH );
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountETH );
  function removeLiquidityWithPermit ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountA, uint256 amountB );
  function swapETHForExactTokens ( uint256 amountOut, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  function swapExactETHForTokens ( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  function swapExactETHForTokensSupportingFeeOnTransferTokens ( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external;
  function swapExactTokensForETH ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  function swapExactTokensForETHSupportingFeeOnTransferTokens ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external;
  function swapExactTokensForTokens ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  function swapExactTokensForTokensSupportingFeeOnTransferTokens ( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external;
  function swapTokensForExactETH ( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
  function swapTokensForExactTokens ( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline ) external returns ( uint256[] memory amounts );
}


// File contracts/Misc_AMOs/__CROSSCHAIN/BSC/ApeSwapLiquidityAMO.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== ApeSwapLiquidityAMO =======================
// ====================================================================
// Provides Uniswap V2-style liquidity
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian








contract ApeSwapLiquidityAMO is Owned {
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    CrossChainCanonicalFRAX private canFRAX;
    CrossChainCanonicalFXS private canFXS;
    CrossChainBridgeBacker_BSC_AnySwap public cc_bridge_backer;
    ERC20 private collateral_token;
    address public canonical_frax_address;
    address public canonical_fxs_address;
    address public collateral_token_address;

    // Important addresses
    address public timelock_address;
    address public custodian_address;

    // Router
    IApeRouter public router = IApeRouter(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);

    // Positions
    address[] public frax_fxs_pair_addresses_array;
    mapping(address => bool) public frax_fxs_pair_addresses_allowed;

    // Slippages
    uint256 public add_rem_liq_slippage = 20000; // 2.0%

    // Constants
    uint256 public missing_decimals;
    uint256 private PRICE_PRECISION = 1e6;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address _owner_address,
        address _custodian_address,
        address _canonical_frax_address,
        address _canonical_fxs_address,
        address _collateral_token_address,
        address _cc_bridge_backer_address,
        address[] memory _initial_pairs
    ) Owned(_owner_address) {
        // Core addresses
        canonical_frax_address = _canonical_frax_address;
        canonical_fxs_address = _canonical_fxs_address;
        collateral_token_address = _collateral_token_address;

        // Core instances
        canFRAX = CrossChainCanonicalFRAX(_canonical_frax_address);
        canFXS = CrossChainCanonicalFXS(_canonical_fxs_address);
        collateral_token = ERC20(_collateral_token_address);
        cc_bridge_backer = CrossChainBridgeBacker_BSC_AnySwap(_cc_bridge_backer_address);

        // Set the custodian
        custodian_address = _custodian_address;

        // Get the timelock addresse from the minter
        timelock_address = cc_bridge_backer.timelock_address();

        // Get the missing decimals for the collateral
        missing_decimals = uint(18) - collateral_token.decimals();

        // Set the initial pairs
        for (uint256 i = 0; i < _initial_pairs.length; i++){ 
            _addTrackedLP(_initial_pairs[i]);
        }
    }

    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[17] memory allocations) {
        // Get the FXS price
        uint256 fxs_price = cc_bridge_backer.cross_chain_oracle().getPrice(canonical_fxs_address);
        
        // Loop through the lp tokens
        uint256[] memory lp_tallies = new uint256[](4); // 0 = FRAX, 1 = FXS, 2 = Collateral, 3 = USD value
        for (uint i = 0; i < frax_fxs_pair_addresses_array.length; i++){ 
            address pair_address = frax_fxs_pair_addresses_array[i];
            if (frax_fxs_pair_addresses_allowed[pair_address]) {
                // Instantiate the pair
                IApePair the_pair = IApePair(pair_address);

                // Get the pair info
                uint256[4] memory lp_info_pack = lpTokenInfo(pair_address);
                
                // Get the lp token balance
                uint256 lp_token_balance = the_pair.balanceOf(address(this));

                // Get the FRAX and FXS balances
                uint256 frax_amt = (lp_info_pack[0] * lp_token_balance) / 1e18;
                uint256 fxs_amt = (lp_info_pack[1] * lp_token_balance) / 1e18;
                uint256 collat_amt = (lp_info_pack[2] * lp_token_balance) / 1e18;

                // Add to the tallies
                lp_tallies[0] += frax_amt;
                lp_tallies[1] += fxs_amt;
                lp_tallies[2] += collat_amt;

                // Get the USD value
                if (lp_info_pack[3] == 0 || lp_info_pack[3] == 2){
                    // If FRAX is in the pair, just double the FRAX balance since it is 50/50
                    lp_tallies[3] += (frax_amt * 2);
                }
                else {
                    // Otherwise, double the value of the FXS component
                    lp_tallies[3] += ((fxs_amt * fxs_price) / PRICE_PRECISION) * 2;
                }

            }
        }

        // FRAX
        allocations[0] = canFRAX.balanceOf(address(this)); // Free FRAX
        allocations[1] = lp_tallies[0]; // FRAX in LP
        allocations[2] = allocations[0] + allocations[1]; // Total FRAX

        // FXS
        allocations[3] = canFXS.balanceOf(address(this)); // Free FXS, native E18
        allocations[4] = (allocations[3] * fxs_price) / PRICE_PRECISION; // Free FXS USD value
        allocations[5] = lp_tallies[1]; // FXS in LP, native E18
        allocations[6] = (allocations[5] * fxs_price) / PRICE_PRECISION; // FXS in LP USD value
        allocations[7] = allocations[3] + allocations[5]; // Total FXS, native E18
        allocations[8] = allocations[4] + allocations[6]; // Total FXS USD Value

        // Collateral
        allocations[9] = collateral_token.balanceOf(address(this)); // Free Collateral, native precision
        allocations[10] = (allocations[9] * (10 ** missing_decimals)); // Free Collateral USD value
        allocations[11] = lp_tallies[2]; // Collateral in LP, native precision
        allocations[12] = (allocations[11] * (10 ** missing_decimals)); // Collateral in LP USD value
        allocations[13] = allocations[9] + allocations[11]; // Total Collateral, native precision
        allocations[14] = allocations[10] + allocations[12]; // Total Collateral USD Value

        // LP
        allocations[15] = lp_tallies[3]; // Total USD value in all LPs

        // Totals
        allocations[16] = allocations[2] + allocations[8] + allocations[14]; // Total USD value in entire AMO, including FXS
    }

    function showTokenBalances() public view returns (uint256[3] memory tkn_bals) {
        tkn_bals[0] = canFRAX.balanceOf(address(this)); // canFRAX
        tkn_bals[1] = canFXS.balanceOf(address(this)); // canFXS
        tkn_bals[2] = collateral_token.balanceOf(address(this)); // collateral_token
    }
    
    // [0] = FRAX per LP token
    // [1] = FXS per LP token
    // [2] = Collateral per LP token
    // [3] = pair_type
    function lpTokenInfo(address pair_address) public view returns (uint256[4] memory return_info) {
        // Instantiate the pair
        IApePair the_pair = IApePair(pair_address);

        // Get the reserves
        uint256[] memory reserve_pack = new uint256[](3); // [0] = FRAX, [1] = FXS, [2] = Collateral
        (uint256 reserve0, uint256 reserve1, ) = (the_pair.getReserves());
        {
            // Get the underlying tokens in the LP
            address token0 = the_pair.token0();
            address token1 = the_pair.token1();

            // Test token0
            if (token0 == canonical_frax_address) reserve_pack[0] = reserve0;
            else if (token0 == canonical_fxs_address) reserve_pack[1] = reserve0;
            else if (token0 == collateral_token_address) reserve_pack[2] = reserve0;

            // Test token1
            if (token1 == canonical_frax_address) reserve_pack[0] = reserve1;
            else if (token1 == canonical_fxs_address) reserve_pack[1] = reserve1;
            else if (token1 == collateral_token_address) reserve_pack[2] = reserve1;
        }

        // Get the token rates
        return_info[0] = (reserve_pack[0] * 1e18) / (the_pair.totalSupply());
        return_info[1] = (reserve_pack[1] * 1e18) / (the_pair.totalSupply());
        return_info[2] = (reserve_pack[2] * 1e18) / (the_pair.totalSupply());

        // Set the pair type (used later)
        if (return_info[0] > 0 && return_info[1] == 0) return_info[3] = 0; // FRAX/XYZ
        else if (return_info[0] == 0 && return_info[1] > 0) return_info[3] = 1; // FXS/XYZ
        else if (return_info[0] > 0 && return_info[1] > 0) return_info[3] = 2; // FRAX/FXS
        else revert("Invalid pair");
    }

    // Needed by CrossChainBridgeBacker
    function allDollarBalances() public view returns (
        uint256 frax_ttl, 
        uint256 fxs_ttl,
        uint256 col_ttl, // in native decimals()
        uint256 ttl_val_usd_e18
    ) {
        uint256[17] memory allocations = showAllocations();

        return (allocations[2], allocations[7], allocations[13], allocations[16]);
    }

    function borrowed_frax() public view returns (uint256) {
        return cc_bridge_backer.frax_lent_balances(address(this));
    }
    
    function borrowed_fxs() public view returns (uint256) {
        return cc_bridge_backer.fxs_lent_balances(address(this));
    }

    function borrowed_collat() public view returns (uint256) {
        return cc_bridge_backer.collat_lent_balances(address(this));
    }

    function total_profit() public view returns (int256 profit) {
        // Get the FXS price
        uint256 fxs_price = cc_bridge_backer.cross_chain_oracle().getPrice(canonical_fxs_address);

        uint256[17] memory allocations = showAllocations();

        // Handle FRAX
        profit = int256(allocations[2]) - int256(borrowed_frax());

        // Handle FXS
        profit +=  ((int256(allocations[7]) - int256(borrowed_fxs())) * int256(fxs_price)) / int256(PRICE_PRECISION);

        // Handle Collat
        profit += (int256(allocations[13]) - int256(borrowed_collat())) * int256(10 ** missing_decimals);
    }

    // token_there_is_one_of means you want the return amount to be (X other token) per 1 token;
    function pair_reserve_ratio_E18(address pair_address, address token_there_is_one_of) public view returns (uint256) {
        // Instantiate the pair
        IApePair the_pair = IApePair(pair_address);

        // Get the token addresses
        address token0 = the_pair.token0();
        address token1 = the_pair.token1();
        uint256 decimals0 = ERC20(token0).decimals();
        uint256 decimals1 = ERC20(token1).decimals();

        (uint256 reserve0, uint256 reserve1, ) = (the_pair.getReserves());

        uint256 miss_dec = (decimals0 >= decimals1) ? (decimals0 - decimals1) : (decimals1 - decimals0);

        // Put everything into E18. Since one of the pair tokens will always be FRAX or FXS, this is ok to assume.
        if (decimals0 >= decimals1){
            reserve1 *= (10 ** miss_dec);
        }
        else {
            reserve0 *= (10 ** miss_dec);
        }

        // Return the ratio
        if (token0 == token_there_is_one_of){
            return (uint256(1e18) * reserve0) / reserve1;
        }
        else if (token1 == token_there_is_one_of){
            return (uint256(1e18) * reserve1) / reserve0;
        }
        else revert("Token not in pair");
    }
   
    /* ========== Swap ========== */

    // Swap tokens directly
    function swapTokens(
        address from_token_address, 
        uint256 from_in, 
        address to_token_address,
        uint256 to_token_out_min
    ) public onlyByOwnGov returns (uint256[] memory amounts) {
        // Approval
        ERC20(from_token_address).approve(address(router), from_in);

        // Create the path object (compiler doesn't like feeding it in directly)
        address[] memory the_path = new address[](2);
        the_path[0] = from_token_address;
        the_path[1] = to_token_address;

        // Swap
        amounts = router.swapExactTokensForTokens(
            from_in, 
            to_token_out_min, 
            the_path, 
            address(this), 
            2105300114 // Expiration: a long time from now
        );
    }

    // If you need a specific path
    function swapTokensWithCustomPath(
        address from_token_address, 
        uint256 from_in,
        uint256 end_token_out_min,
        address[] memory path
    ) public onlyByOwnGov returns (uint256[] memory amounts) {
        // Approval
        ERC20(from_token_address).approve(address(router), from_in);

        // Swap
        amounts = router.swapExactTokensForTokens(
            from_in, 
            end_token_out_min, 
            path, 
            address(this), 
            2105300114 // Expiration: a long time from now
        );
    }

    /* ========== Add / Remove Liquidity ========== */

    function addLiquidity(
        address lp_token_address, 
        address tokenA_address, 
        uint256 tokenA_amt, 
        address tokenB_address, 
        uint256 tokenB_amt
    ) public onlyByOwnGov returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(frax_fxs_pair_addresses_allowed[lp_token_address], "LP address not allowed");

        // Approvals
        ERC20(tokenA_address).approve(address(router), tokenA_amt);
        ERC20(tokenB_address).approve(address(router), tokenB_amt);

        // Add liquidity
        (amountA, amountB, liquidity) = router.addLiquidity(
            tokenA_address, 
            tokenB_address, 
            tokenA_amt, 
            tokenB_amt, 
            tokenA_amt - ((tokenA_amt * add_rem_liq_slippage) / PRICE_PRECISION), 
            tokenB_amt - ((tokenB_amt * add_rem_liq_slippage) / PRICE_PRECISION), 
            address(this), 
            2105300114 // Expiration: a long time from now
        );
    }

    function removeLiquidity(
        address lp_token_address, 
        uint256 lp_token_in
    ) public onlyByOwnGov returns (uint256 amountA, uint256 amountB) {
        require(frax_fxs_pair_addresses_allowed[lp_token_address], "LP address not allowed");

        // Approvals
        ERC20(lp_token_address).approve(address(router), lp_token_in);

        // Get the token addresses
        address tokenA = IApePair(lp_token_address).token0();
        address tokenB = IApePair(lp_token_address).token1();

        // Remove liquidity
        (amountA, amountB) = router.removeLiquidity(
            tokenA, 
            tokenB, 
            lp_token_in, 
            0, 
            0, 
            address(this), 
            2105300114 // Expiration: a long time from now
        );
    }

    /* ========== Burns and givebacks ========== */

    function giveFRAXBack(uint256 frax_amount, bool do_bridging) external onlyByOwnGov {
        canFRAX.approve(address(cc_bridge_backer), frax_amount);
        cc_bridge_backer.receiveBackViaAMO(canonical_frax_address, frax_amount, do_bridging);
    }

    function giveFXSBack(uint256 fxs_amount, bool do_bridging) external onlyByOwnGov {
        canFXS.approve(address(cc_bridge_backer), fxs_amount);
        cc_bridge_backer.receiveBackViaAMO(canonical_fxs_address, fxs_amount, do_bridging);
    }

    function giveCollatBack(uint256 collat_amount, bool do_bridging) external onlyByOwnGov {
        collateral_token.approve(address(cc_bridge_backer), collat_amount);
        cc_bridge_backer.receiveBackViaAMO(collateral_token_address, collat_amount, do_bridging);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Any pairs with FRAX and/or FXS must be whitelisted first before adding liquidity
    function _addTrackedLP(address pair_address) internal {
        // Instantiate the pair
        IApePair the_pair = IApePair(pair_address);

        // Make sure either FRAX or FXS is present
        bool frax_present = (the_pair.token0() == canonical_frax_address || the_pair.token1() == canonical_frax_address);
        bool fxs_present = (the_pair.token0() == canonical_fxs_address || the_pair.token1() == canonical_fxs_address);
        require(frax_present || fxs_present, "FRAX or FXS not in pair");

        // Adjust the state variables
        require(frax_fxs_pair_addresses_allowed[pair_address] == false, "LP already exists");
        frax_fxs_pair_addresses_allowed[pair_address] = true; 
        frax_fxs_pair_addresses_array.push(pair_address);
    }

    function addTrackedLP(address pair_address) public onlyByOwnGov {
        _addTrackedLP(pair_address);
    }

    // Remove FRAX and FXS related pairs
    function removeTrackedLP(address pair_address) public onlyByOwnGov {
        // Adjust the state variables
        require(frax_fxs_pair_addresses_allowed[pair_address] == true, "LP not already present");
        frax_fxs_pair_addresses_allowed[pair_address] = false; 
        
        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < frax_fxs_pair_addresses_array.length; i++){ 
            if (frax_fxs_pair_addresses_array[i] == pair_address) {
                frax_fxs_pair_addresses_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function setAMOMinter(address _cc_bridge_backer_address) external onlyByOwnGov {
        cc_bridge_backer = CrossChainBridgeBacker_BSC_AnySwap(_cc_bridge_backer_address);

        // Get the timelock addresses from the minter
        timelock_address = cc_bridge_backer.timelock_address();

        // Make sure the new addresse is not address(0)
        require(timelock_address != address(0), "Invalid timelock");
    }

    function setSlippages(uint256 _add_rem_liq_slippage) external onlyByOwnGov {
        add_rem_liq_slippage = _add_rem_liq_slippage;
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        require(_custodian_address != address(0), "Zero address detected");
        custodian_address = _custodian_address;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }
}