/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

/**
UniLend Finance FlashLoan Contract
*/

pragma solidity 0.6.2;


// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
contract ReentrancyGuard {
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

/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Unilend fee IFlashLoanReceiver.
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract UnilendFDonation {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint public defaultReleaseRate;
    bool public disableSetCore;
    mapping(address => uint) public releaseRate;
    mapping(address => uint) public lastReleased;
    address public core;
    
    constructor() public {
        core = msg.sender;
        defaultReleaseRate = 11574074074075; // ~1% / day
    }
    
    
    modifier onlyCore {
        require(
            core == msg.sender,
            "Not Permitted"
        );
        _;
    }
    
    
    event NewDonation(address indexed donator, uint amount);
    event Released(address indexed to, uint amount);
    event ReleaseRate(address indexed token, uint rate);
    
    
    
    function balanceOfToken(address _token) external view returns(uint) {
        return IERC20(_token).balanceOf(address(this));
    }
    
    function getReleaseRate(address _token) public view returns (uint) {
        if(releaseRate[_token] > 0){
            return releaseRate[_token];
        } 
        else {
            return defaultReleaseRate;
        }
    }
    
    function getCurrentRelease(address _token, uint timestamp) public view returns (uint availRelease){
        uint tokenBalance = IERC20(_token).balanceOf( address(this) );
        
        uint remainingRate = ( timestamp.sub( lastReleased[_token] ) ).mul( getReleaseRate(_token) );
        uint maxRate = 100 * 10**18;
        
        if(remainingRate > maxRate){ remainingRate = maxRate; }
        availRelease = ( tokenBalance.mul( remainingRate )).div(10**20);
    }
    
    
    function donate(address _token, uint amount) external returns(bool) {
        require(amount > 0, "Amount can't be zero");
        releaseTokens(_token);
        
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount);
        
        emit NewDonation(msg.sender, amount);
        
        return true;
    }
    
    function disableSetNewCore() external onlyCore {
        require(!disableSetCore, "Already disabled");
        disableSetCore = true;
    }
    
    function setCoreAddress(address _newAddress) external onlyCore {
        require(!disableSetCore, "SetCoreAddress disabled");
        core = _newAddress;
    }
    
    function setReleaseRate(address _token, uint _newRate) external onlyCore {
        releaseTokens(_token);
        
        releaseRate[_token] = _newRate;
        
        emit ReleaseRate(_token, _newRate);
    }
    
    function releaseTokens(address _token) public {
        uint tokenBalance = IERC20(_token).balanceOf( address(this) );
        
        if(tokenBalance > 0){
            uint remainingRate = ( block.timestamp.sub( lastReleased[_token] ) ).mul( getReleaseRate(_token) );
            uint maxRate = 100 * 10**18;
            
            lastReleased[_token] = block.timestamp;
            
            if(remainingRate > maxRate){ remainingRate = maxRate; }
            uint totalReleased = ( tokenBalance.mul( remainingRate )).div(10**20);
            
            if(totalReleased > 0){
                IERC20(_token).safeTransfer(core, totalReleased);
                
                emit Released(core, totalReleased);
            }
        } 
        else {
            lastReleased[_token] = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
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

contract UFlashLoanPool is ERC20 {
    using SafeMath for uint256;
    
    address public token;
    address payable public core;
    
    
    constructor(
        address _token,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) public {
        token = _token;
        
        core = payable(msg.sender);
    }
    
    modifier onlyCore {
        require(
            core == msg.sender,
            "Not Permitted"
        );
        _;
    }
    
    
    
    function calculateShare(uint _totalShares, uint _totalAmount, uint _amount) internal pure returns (uint){
        if(_totalShares == 0){
            return Math.sqrt(_amount.mul( _amount ));
        } else {
            return (_amount).mul( _totalShares ).div( _totalAmount );
        }
    }
    
    function getShareValue(uint _totalAmount, uint _totalSupply, uint _amount) internal pure returns (uint){
        return ( _amount.mul(_totalAmount) ).div( _totalSupply );
    }
    
    function getShareByValue(uint _totalAmount, uint _totalSupply, uint _valueAmount) internal pure returns (uint){
        return ( _valueAmount.mul(_totalSupply) ).div( _totalAmount );
    }
    
    
    function deposit(address _recipient, uint amount) external onlyCore returns(uint) {
        uint _totalSupply = totalSupply();
        
        uint tokenBalance;
        if(EthAddressLib.ethAddress() == token){
            tokenBalance = address(core).balance;
        } 
        else {
            tokenBalance = IERC20(token).balanceOf(core);
        }
        
        uint ntokens = calculateShare(_totalSupply, tokenBalance.sub(amount), amount);
        
        require(ntokens > 0, 'Insufficient Liquidity Minted');
        
        // MINT uTokens
        _mint(_recipient, ntokens);
        
        return ntokens;
    }
    
    
    function redeem(address _recipient, uint tok_amount) external onlyCore returns(uint) {
        require(tok_amount > 0, 'Insufficient Liquidity Burned');
        require(balanceOf(_recipient) >= tok_amount, "Balance Exceeds Requested");
        
        uint tokenBalance;
        if(EthAddressLib.ethAddress() == token){
            tokenBalance = address(core).balance;
        } 
        else {
            tokenBalance = IERC20(token).balanceOf(core);
        }
        
        uint poolAmount = getShareValue(tokenBalance, totalSupply(), tok_amount);
        
        require(tokenBalance >= poolAmount, "Not enough Liquidity");
        
        // BURN uTokens
        _burn(_recipient, tok_amount);
        
        return poolAmount;
    }
    
    
    function redeemUnderlying(address _recipient, uint amount) external onlyCore returns(uint) {
        uint tokenBalance;
        if(EthAddressLib.ethAddress() == token){
            tokenBalance = address(core).balance;
        } 
        else {
            tokenBalance = IERC20(token).balanceOf(core);
        }
        
        uint tok_amount = getShareByValue(tokenBalance, totalSupply(), amount);
        
        require(tok_amount > 0, 'Insufficient Liquidity Burned');
        require(balanceOf(_recipient) >= tok_amount, "Balance Exceeds Requested");
        require(tokenBalance >= amount, "Not enough Liquidity");
        
        // BURN uTokens
        _burn(_recipient, tok_amount);
        
        return tok_amount;
    }
    
    
    function balanceOfUnderlying(address _address, uint timestamp) public view returns (uint _bal) {
        uint _balance = balanceOf(_address);
        
        if(_balance > 0){
            uint tokenBalance;
            if(EthAddressLib.ethAddress() == token){
                tokenBalance = address(core).balance;
            } 
            else {
                tokenBalance = IERC20(token).balanceOf(core);
            }
            
            address donationAddress = UnilendFlashLoanCore( core ).donationAddress();
            uint _balanceDonation = UnilendFDonation( donationAddress ).getCurrentRelease(token, timestamp);
            uint _totalPoolAmount = tokenBalance.add(_balanceDonation);
            
            _bal = getShareValue(_totalPoolAmount, totalSupply(), _balance);
        } 
    }
    
    
    function poolBalanceOfUnderlying(uint timestamp) public view returns (uint _bal) {
        uint tokenBalance;
        if(EthAddressLib.ethAddress() == token){
            tokenBalance = address(core).balance;
        } 
        else {
            tokenBalance = IERC20(token).balanceOf(core);
        }
        
        if(tokenBalance > 0){
            address donationAddress = UnilendFlashLoanCore( core ).donationAddress();
            uint _balanceDonation = UnilendFDonation( donationAddress ).getCurrentRelease(token, timestamp);
            uint _totalPoolAmount = tokenBalance.add(_balanceDonation);
            
            _bal = _totalPoolAmount;
        } 
    }
}

contract UnilendFlashLoanCore is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    address public admin;
    address payable public distributorAddress;
    address public donationAddress;
    
    mapping(address => address) public Pools;
    mapping(address => address) public Assets;
    uint public poolLength;
    
    
    uint256 private FLASHLOAN_FEE_TOTAL = 5;
    uint256 private FLASHLOAN_FEE_PROTOCOL = 3000;
    
    
    constructor() public {
        admin = msg.sender;
    }
    
    
    /**
    * @dev emitted when a flashloan is executed
    * @param _target the address of the flashLoanReceiver
    * @param _reserve the address of the reserve
    * @param _amount the amount requested
    * @param _totalFee the total fee on the amount
    * @param _protocolFee the part of the fee for the protocol
    * @param _timestamp the timestamp of the action
    **/
    event FlashLoan(
        address indexed _target,
        address indexed _reserve,
        uint256 _amount,
        uint256 _totalFee,
        uint256 _protocolFee,
        uint256 _timestamp
    );
    
    event PoolCreated(address indexed token, address pool, uint);
    
    /**
    * @dev emitted during a redeem action.
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event RedeemUnderlying(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on deposit
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event Deposit(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev only lending pools configurator can use functions affected by this modifier
    **/
    modifier onlyAdmin {
        require(
            admin == msg.sender,
            "The caller must be a admin"
        );
        _;
    }
    
    /**
    * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
    * is not zero.
    * @param _amount the amount provided
    **/
    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        require(_amount > 0, "Amount must be greater than 0");
        _;
    }
    
    receive() payable external {}
    
    /**
    * @dev returns the fee applied to a flashloan and the portion to redirect to the protocol, in basis points.
    **/
    function getFlashLoanFeesInBips() public view returns (uint256, uint256) {
        return (FLASHLOAN_FEE_TOTAL, FLASHLOAN_FEE_PROTOCOL);
    }
    
    /**
    * @dev gets the bulk uToken contract address for the reserves
    * @param _reserves the array of reserve address
    * @return the address of the uToken contract
    **/
    function getPools(address[] calldata _reserves) external view returns (address[] memory) {
        address[] memory _addresss = new address[](_reserves.length);
        address[] memory _reserves_ = _reserves;
        
        for (uint i=0; i<_reserves_.length; i++) {
            _addresss[i] = Pools[_reserves_[i]];
        }
        
        return _addresss;
    }
    
    
    /**
    * @dev balance of underlying asset for user address
    * @param _reserve reserve address
    * @param _address user address
    * @param timestamp timestamp of query
    **/
    function balanceOfUnderlying(address _reserve, address _address, uint timestamp) public view returns (uint _bal) {
        if(Pools[_reserve] != address(0)){
            _bal = UFlashLoanPool(Pools[_reserve]).balanceOfUnderlying(_address, timestamp);
        }
    }
    
    /**
    * @dev balance of underlying asset for pool
    * @param _reserve reserve address
    * @param timestamp timestamp of query
    **/
    function poolBalanceOfUnderlying(address _reserve, uint timestamp) public view returns (uint _bal) {
        if(Pools[_reserve] != address(0)){
            _bal = UFlashLoanPool(Pools[_reserve]).poolBalanceOfUnderlying(timestamp);
        }
    }
    
    
    /**
    * @dev set new admin for contract.
    * @param _admin the address of new admin
    **/
    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "UnilendV1: ZERO ADDRESS");
        admin = _admin;
    }
    
    /**
    * @dev set new distributor address.
    * @param _address new address
    **/
    function setDistributorAddress(address payable _address) external onlyAdmin {
        require(_address != address(0), "UnilendV1: ZERO ADDRESS");
        distributorAddress = _address;
    }
    
    /**
    * @dev disable changing donation pool donation address.
    **/
    function setDonationDisableNewCore() external onlyAdmin {
        UnilendFDonation(donationAddress).disableSetNewCore();
    }
    
    /**
    * @dev set new core address for donation pool.
    * @param _newAddress new address
    **/
    function setDonationCoreAddress(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "UnilendV1: ZERO ADDRESS");
        UnilendFDonation(donationAddress).setCoreAddress(_newAddress);
    }
    
    /**
    * @dev set new release rate from donation pool for token
    * @param _reserve reserve address
    * @param _newRate new rate of release
    **/
    function setDonationReleaseRate(address _reserve, uint _newRate) external onlyAdmin {
        require(_reserve != address(0), "UnilendV1: ZERO ADDRESS");
        UnilendFDonation(donationAddress).setReleaseRate(_reserve, _newRate);
    }
    
    /**
    * @dev set new flash loan fees.
    * @param _newFeeTotal total fee
    * @param _newFeeProtocol protocol fee
    **/
    function setFlashLoanFeesInBips(uint _newFeeTotal, uint _newFeeProtocol) external onlyAdmin returns (bool) {
        require(_newFeeTotal > 0 && _newFeeTotal < 10000, "UnilendV1: INVALID TOTAL FEE RANGE");
        require(_newFeeProtocol > 0 && _newFeeProtocol < 10000, "UnilendV1: INVALID PROTOCOL FEE RANGE");
        
        FLASHLOAN_FEE_TOTAL = _newFeeTotal;
        FLASHLOAN_FEE_PROTOCOL = _newFeeProtocol;
        
        return true;
    }
    

    /**
    * @dev transfers to the user a specific amount from the reserve.
    * @param _reserve the address of the reserve where the transfer is happening
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _reserve, address payable _user, uint256 _amount) internal {
        require(_user != address(0), "UnilendV1: USER ZERO ADDRESS");
        
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call{value: _amount, gas: 50000}("");
            require(result, "Transfer of ETH failed");
        }
    }
    
    /**
    * @dev transfers to the protocol fees of a flashloan to the fees collection address
    * @param _token the address of the token being transferred
    * @param _amount the amount being transferred
    **/
    function transferFlashLoanProtocolFeeInternal(address _token, uint256 _amount) internal {
        if (_token != EthAddressLib.ethAddress()) {
            ERC20(_token).safeTransfer(distributorAddress, _amount);
        } else {
            (bool result, ) = distributorAddress.call{value: _amount, gas: 50000}("");
            require(result, "Transfer of ETH failed");
        }
    }
    
    
    /**
    * @dev allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned. NOTE There are security concerns for developers of flashloan receiver contracts
    * that must be kept into consideration.
    * @param _receiver The address of the contract receiving the funds. The receiver should implement the IFlashLoanReceiver interface.
    * @param _reserve the address of the principal reserve
    * @param _amount the amount requested for this flashloan
    **/
    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params)
        external
        nonReentrant
        onlyAmountGreaterThanZero(_amount)
    {
        //check that the reserve has enough available liquidity
        uint256 availableLiquidityBefore = _reserve == EthAddressLib.ethAddress()
            ? address(this).balance
            : IERC20(_reserve).balanceOf(address(this));

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        (uint256 totalFeeBips, uint256 protocolFeeBips) = getFlashLoanFeesInBips();
        //calculate amount fee
        uint256 amountFee = _amount.mul(totalFeeBips).div(10000);

        //protocol fee is the part of the amountFee reserved for the protocol - the rest goes to depositors
        uint256 protocolFee = amountFee.mul(protocolFeeBips).div(10000);
        require(
            amountFee > 0 && protocolFee > 0,
            "The requested amount is too small for a flashLoan."
        );

        //get the FlashLoanReceiver instance
        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);

        //transfer funds to the receiver
        transferToUser(_reserve, payable(_receiver), _amount);

        //execute action of the receiver
        receiver.executeOperation(_reserve, _amount, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = _reserve == EthAddressLib.ethAddress()
            ? address(this).balance
            : IERC20(_reserve).balanceOf(address(this));

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
        
        transferFlashLoanProtocolFeeInternal(_reserve, protocolFee);

        //solium-disable-next-line
        emit FlashLoan(_receiver, _reserve, _amount, amountFee, protocolFee, block.timestamp);
    }
    
    
    
    
    
    /**
    * @dev deposits The underlying asset into the reserve. A corresponding amount of the overlying asset (uTokens) is minted.
    * @param _reserve the address of the reserve
    * @param _amount the amount to be deposited
    **/
    function deposit(address _reserve, uint _amount) external 
        payable
        nonReentrant
        onlyAmountGreaterThanZero(_amount)
    returns(uint mintedTokens) {
        require(Pools[_reserve] != address(0), 'UnilendV1: POOL NOT FOUND');
        
        UnilendFDonation(donationAddress).releaseTokens(_reserve);
        
        address _user = msg.sender;
        
        if (_reserve != EthAddressLib.ethAddress()) {
            require(msg.value == 0, "User is sending ETH along with the ERC20 transfer.");
            
            uint reserveBalance = IERC20(_reserve).balanceOf(address(this));
            
            ERC20(_reserve).safeTransferFrom(_user, address(this), _amount);
            
            _amount = ( IERC20(_reserve).balanceOf(address(this)) ).sub(reserveBalance);
        } else {
            require(msg.value >= _amount, "The amount and the value sent to deposit do not match");

            if (msg.value > _amount) {
                //send back excess ETH
                uint256 excessAmount = msg.value.sub(_amount);
                
                (bool result, ) = _user.call{value: excessAmount, gas: 50000}("");
                require(result, "Transfer of ETH failed");
            }
        }
        
        mintedTokens = UFlashLoanPool(Pools[_reserve]).deposit(msg.sender, _amount);
        
        emit Deposit(_reserve, msg.sender, _amount, block.timestamp);
    }
    
    
    /**
    * @dev Redeems the uTokens for underlying assets.
    * @param _reserve the address of the reserve
    * @param _amount the amount uTokens to be redeemed
    **/
    function redeem(address _reserve, uint _amount) external returns(uint redeemTokens) {
        require(Pools[_reserve] != address(0), 'UnilendV1: POOL NOT FOUND');
        
        UnilendFDonation(donationAddress).releaseTokens(_reserve);
        
        redeemTokens = UFlashLoanPool(Pools[_reserve]).redeem(msg.sender, _amount);
        
        //transfer funds to the user
        transferToUser(_reserve, payable(msg.sender), redeemTokens);
        
        emit RedeemUnderlying(_reserve, msg.sender, redeemTokens, block.timestamp);
    }
    
    /**
    * @dev Redeems the underlying amount of assets.
    * @param _reserve the address of the reserve
    * @param _amount the underlying amount to be redeemed
    **/
    function redeemUnderlying(address _reserve, uint _amount) external returns(uint token_amount) {
        require(Pools[_reserve] != address(0), 'UnilendV1: POOL NOT FOUND');
        
        UnilendFDonation(donationAddress).releaseTokens(_reserve);
        
        token_amount = UFlashLoanPool(Pools[_reserve]).redeemUnderlying(msg.sender, _amount);
        
        //transfer funds to the user
        transferToUser(_reserve, payable(msg.sender), _amount);
        
        emit RedeemUnderlying(_reserve, msg.sender, _amount, block.timestamp);
    }
    
    
    
    /**
    * @dev Creates pool for asset.
    * This function is executed by the overlying uToken contract in response to a redeem action.
    * @param _reserve the address of the reserve
    **/
    function createPool(address _reserve) public returns (address) {
        require(Pools[_reserve] == address(0), 'UnilendV1: POOL ALREADY CREATED');
        
        ERC20 asset = ERC20(_reserve);
        
        string memory uTokenName;
        string memory uTokenSymbol;
        
        if(_reserve == EthAddressLib.ethAddress()){
            uTokenName = string(abi.encodePacked("UnilendV1 - ETH"));
            uTokenSymbol = string(abi.encodePacked("uETH"));
        } 
        else {
            uTokenName = string(abi.encodePacked("UnilendV1 - ", asset.name()));
            uTokenSymbol = string(abi.encodePacked("u", asset.symbol()));
        }
        
        UFlashLoanPool _poolMeta = new UFlashLoanPool(_reserve, uTokenName, uTokenSymbol);
        
        address _poolAddress = address(_poolMeta);
        
        Pools[_reserve] = _poolAddress;
        Assets[_poolAddress] = _reserve;
        
        poolLength++;
        
        emit PoolCreated(_reserve, _poolAddress, poolLength);
        
        return _poolAddress;
    }
    
    /**
    * @dev Creates donation contract (one-time).
    **/
    function createDonationContract() external returns (address) {
        require(donationAddress == address(0), 'UnilendV1: DONATION ADDRESS ALREADY CREATED');
        
        UnilendFDonation _donationMeta = new UnilendFDonation();
        donationAddress = address(_donationMeta);
        
        return donationAddress;
    }
}