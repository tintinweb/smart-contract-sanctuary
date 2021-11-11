/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-09
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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

pragma solidity ^0.6.0;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

pragma solidity ^0.6.0;


interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (IERC20);
    function lpToken() external view returns (IERC20);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function harvest() external;
    function retireStrat() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
    function setBoosted(bool) external;
    function isBoosted() external view returns (bool);
    function setBoostContract(address) external;
}

pragma solidity ^0.6.0;

interface IBoost {
    function stake(uint256, address) external;
    function withdraw(uint256, address) external;
    function getReward(address) external;
    function rewards(address) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.6.0;

contract VampVaultMultiV3 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct StratCandidate {
        address implementation;
        uint proposedTime;
    }
    
    struct UserInfo {
        uint256 depositHarvest; //when deposited
        uint256 depositAmount;  //how much deposited
    }
    
    
    //pid references the pool ID 
    //This number is needed to know which strategy to send the LP into
    //Interfaced users[msg.sender][pid]
    mapping (address => mapping (uint256 => UserInfo)) users;
    //Interfaced strategoes[pid]
    IStrategy[] public strategies;

    //Interfaced harvestAmounts[pid][harvestNumber]
    mapping (uint256 => uint256[]) public harvestAmounts;    //Total amount of reward token harvested that harvest
    //Interfaced harvestPerLP[pid][harvestNumber]
    mapping (uint256 => uint256[]) public harvestPerLP;      //Amount of reward tokens per LP that harvest

    address public reward;
    
    
    mapping (uint256 => address) public boostContract;
    
    // The last proposed strategy to switch to.
    StratCandidate public stratCandidate;
    // The strategy currently in use by the vault.
    //IStrategy public strategy;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public constant approvalDelay = 0;
    
    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event Deposit(address user, uint256 amt);
    event Withdraw(address user, uint256 amt);

    /**
     * @param _rewardToken the address of the reward.
     */
    constructor (
        address _rewardToken
    ) public {
        reward = _rewardToken;
    }
    
    /*
    ==================================
    ===== STRAT >> VAULT DEPOSIT ===== 
    ==================================
    */
    //Tells the vault how much has been made from this harvest
    //We write on chain the amount that has been harvested (for analytics mostly)
    //We write on chain the amount that has been harvested per LP token (for claiming)
    function depositRewards(uint256 pid, uint256 amt) external onlyStrategy(pid) {
        //uint256[] storage harvAmt = harvestAmounts[pid];
        //uint256[] storage harvPerLP = harvestPerLP[pid];
        //harvAmt.push(amt);
        harvestAmounts[pid].push(amt);
        //uint256 rewardPerLP = amt.div(balanceOfStakedLP(pid));
        //harvPerLP.push(amt.div(balanceOfStakedLP(pid)));
        harvestPerLP[pid].push(balanceOfStakedLP(pid)); //Write down how much LP we have staked during this harvest
    }
    
    /*
    =================
    ===== CLAIM ===== 
    =================
    */
    //Sends the owed funds to the depositor
    //"Simulates" each harvest for that user by looping through and calculating their portion of the rewards
    //Their LP amount remains the same between claim and deposit since we force a claim on deposit or withdraw
    function claim(uint256 pid) public {
        // Simulate each harvest
        uint256 totalReward = claimable(pid, msg.sender);
        IERC20(reward).safeTransfer(msg.sender, totalReward);    //Probably need a check here?
        users[msg.sender][pid].depositHarvest = harvestAmounts[pid].length;  //Set the new deposit date to the latest harvest to reset rewards
        claimBoost(pid);
    }
    
    function claimBoost(uint256 pid) internal {
        if(isStratBoosted(pid)) {
            IBoost(boostContract[pid]).getReward(msg.sender);
        }
    }
    
    //Returns how much a depositor is owed
    //Simulates every harvest the user was deposited in and returns the reward count
    function claimable(uint256 pid, address _depositor) public view returns (uint256) {
        uint256 totalReward = 0;
        uint256 bal = getUserDepositAmt(pid, _depositor);
        for (uint256 i = getUserDepositHarvest(pid, _depositor); i < harvestPerLP[pid].length; i++) {
            uint256 rewardsHarvested = harvestAmounts[pid][i];  //total amount of rewards harvested this harvest
            uint256 totalLPHarvested = harvestPerLP[pid][i];    //total amount of LP in the vault during this harvest
            uint256 userPortion = 0;
            if (totalLPHarvested != 0 && rewardsHarvested != 0) {
                userPortion = (bal.mul(rewardsHarvested)).div(totalLPHarvested);
            }
            totalReward = totalReward.add(userPortion);
        }
        //Should never happen, however we don't want to stick funds if it does
        if(totalReward > getRewardBal()) {
            totalReward = getRewardBal();
        }
        return totalReward;
    }
    
    function getAllClaimable(address _depositor) public view returns (uint256) {
        uint256 c = 0;
        for(uint256 i = 0; i < strategies.length; i++) {
            c = c.add(claimable(i, _depositor));
        }
    }
    
    /*
    ===================
    ===== HARVEST ===== 
    ===================
    */
    
    //Easy function to harvest every strategy in this vault
    function harvestAll() public onlyEOA {
        for (uint256 i = 0; i < strategies.length; i++) {
            harvest(i);
        }
    }
    
    //How to call the harvests of the strategy
    function harvest(uint256 pid) public onlyEOA {
        strategies[pid].harvest(); //calls depositRewards 
    }
    
    /*
    ===================
    ===== DEPOSIT ===== 
    ===================
    */
    
    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll(uint256 pid) external {
        deposit(pid, LPToken(pid).balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint256 pid, uint256 _amount) public nonReentrant {
        strategies[pid].beforeDeposit();   //Doesn't do anything but just in case
        
        UserInfo storage user = users[msg.sender][pid];
        uint256[] storage harvAmt = harvestAmounts[pid];
        uint256[] storage harvPerLP = harvestPerLP[pid];

        if(balanceOfStakedLP(pid) == 0) {
            //Only happens when no one is in the pool to prevent harvesting nothing
            harvAmt.push(0);
            harvPerLP.push(0);
        } else {
            harvest(pid);      //Harvest the pool before you deposit so you're not joining in the middle of a harvest
        }
        // Claim needs to be after the harvest on deposit
        claim(pid);
        user.depositHarvest = harvestAmounts[pid].length;  // Write down on chain what harvest the person has entered at
        user.depositAmount = user.depositAmount.add(_amount);   //Keep track of how much has been deposited
        //Transfer LP to the vault
        LPToken(pid).safeTransferFrom(msg.sender, address(this), _amount);
        //Transfer LP to the strategy
        earn(pid);
        emit Deposit(msg.sender, _amount);
    }
    
    /*
    ====================
    ===== WITHDRAW ===== 
    ====================
    */
    
    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll(uint256 pid) external {
        withdraw(pid, getUserDepositAmt(pid, msg.sender));
    }
    
    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. 
     */
    function withdraw(uint256 pid, uint256 _amount) public {
        UserInfo storage user = users[msg.sender][pid];
        require(user.depositAmount >= _amount, "Not enough deposited"); //make sure they're not overwithdrawing
        harvest(pid);
        claim(pid); // Claim your rewards
        if(isStratBoosted(pid) && (getBoostDeposit(pid, msg.sender) > 0)) {
            IBoost(getBoostContract(pid)).withdraw(_amount, msg.sender);
        } else {
            strategies[pid].withdraw(_amount);  // withdraw the LP tokens from the strategy
        }
        LPToken(pid).safeTransfer(msg.sender, _amount); // send the LP back to the user
        user.depositHarvest = getCurrentHarvestNumber(pid); // reset the user's harvest number to the current harvest
        user.depositAmount = user.depositAmount.sub(_amount, "Can't withdraw from vault"); // subtract the number of lp tokens withdrawn
        emit Withdraw(msg.sender, _amount);
    }
    
    function emergencyWithdraw(uint256 pid, uint256 _amount) public {
        UserInfo storage user = users[msg.sender][pid];
        require(user.depositAmount >= _amount, "Not enough deposited"); //make sure they're not overwithdrawing
        //harvest(pid);
        //claim(pid); // Claim your rewards
        if(isStratBoosted(pid) && (getBoostDeposit(pid, msg.sender) > 0)) {
            IBoost(getBoostContract(pid)).withdraw(_amount, msg.sender);
        } else {
            strategies[pid].withdraw(_amount);  // withdraw the LP tokens from the strategy
        }
        LPToken(pid).safeTransfer(msg.sender, _amount); // send the LP back to the user
        user.depositHarvest = getCurrentHarvestNumber(pid); // reset the user's harvest number to the current harvest
        user.depositAmount = user.depositAmount.sub(_amount, "Can't withdraw from vault"); // subtract the number of lp tokens withdrawn
        emit Withdraw(msg.sender, _amount);
    }
    
    /*
    =====================
    ===== USER INFO ===== 
    =====================
    */
    
    //Get's the harvest number that a user entered the vault at
    //Updates when a user withdraws or deposits into the vault
    //Updates when a user claims their rewards from the vault
    function getUserDepositHarvest(uint256 pid, address addy) public view returns (uint256) {
        return users[addy][pid].depositHarvest;
    }
    
    //Get's the amount of LP tokens the user deposited into the vault
    function getUserDepositAmt(uint256 pid, address addy) public view returns (uint256) {
        return users[addy][pid].depositAmount;
    }
    
    /*
    ======================
    ===== VAULT INFO ===== 
    ======================
    */
    
    //Get's the current harvest number of a pool 
    //Used as the end of the simualtion for claiming
    function getCurrentHarvestNumber(uint256 pid) public view returns (uint256) {
        return harvestAmounts[pid].length;
    }
    
    //Get's the underlying LP token that the strategy needs to use
    function LPToken(uint256 pid) public view returns (IERC20) {
        return IERC20(strategies[pid].lpToken());
    }
    
    //Returns how many of the reward token we have in the contract
    function getRewardBal() public view returns (uint256) {
        return IERC20(reward).balanceOf(address(this));
    }
    
    //Returns how many LP tokens are staked through the vault
    function balanceOfStakedLP(uint256 pid) public view returns (uint256) {
        return strategies[pid].balanceOf();
    }
    
    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the vault contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balanceOfLP(uint256 pid) public view returns (uint256) {
        return LPToken(pid).balanceOf(address(this)).add(IStrategy(strategies[pid]).balanceOf());
    }
    
    /**
     * @dev Custom logic in here for how much the vault allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * want to keep some of the system funds at hand in the vault, instead
     * of putting them to work.
     */
    function available(uint256 pid) public view returns (uint256) {
        return LPToken(pid).balanceOf(address(this));
    }
    
    /*
    ======================
    ===== BOOST INFO ===== 
    ======================
    */
    
    function getAllBoostClaimable(address _depositor) public view returns (uint256) {
        uint256 bc = 0;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(isStratBoosted(i)) {
                bc = bc.add(getBoostClaimable(i, _depositor));
            }
        }
    }
    
    function getBoostClaimable(uint256 pid, address _depositor) public view returns (uint256) {
        return IBoost(getBoostContract(pid)).rewards(_depositor);
    }
    
    function getBoostContract(uint256 pid) public view returns (address) {
        return boostContract[pid];
    } 
    
    function getBoostDeposit(uint256 pid, address _depositor) public view returns (uint256) {
        return IBoost(getBoostContract(pid)).balanceOf(_depositor);
    }

    function isStratBoosted(uint256 pid) public view returns (bool) {
        return strategies[pid].isBoosted();
    }

    function setStratBoosted(bool _boost, uint256 pid) public onlyOwner {
        strategies[pid].setBoosted(_boost);
    }
    
    function setBoostContract(address _boostCon, bool _boost, uint256 pid) public onlyOwner {
        setStratBoosted(_boost, pid);
        boostContract[pid] = _boostCon;
        //strategies[pid].setBoostContract(_boostCon);
        //Add in the boostContract to strategy here
    }
    /*
    ======================
    ===== STRATEGIES ===== 
    ======================
    */
    
    // Add a new strategy to the vault
    // Used for adding in a new farm to deposit
    function addStrategy(address strategy) public onlyOwner {
        strategies.push(IStrategy(strategy));
    }
    
    /** 
     * @dev Sets the candidate for the new strat to use with this vault.
     * @param _implementation The address of the candidate strategy.  
     * There can only be 1 proposed strat at a time
     * We decide which strat gets upgraded through the upgradeStrat function
     */
    function proposeStrat(address _implementation) public onlyOwner {
        require(address(this) == IStrategy(_implementation).vault(), "Proposal not valid for this Vault");
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         });

        emit NewStratCandidate(_implementation);
    }
    
    /** 
     * @dev It switches the active strat for the strat candidate. After upgrading, the 
     * candidate implementation is set to the 0x00 address, and proposedTime to a time 
     * happening in +100 years for safety. 
     */
    function upgradeStrat(uint256 pid) public onlyOwner {
        require(stratCandidate.implementation != address(0), "There is no candidate");
        require(stratCandidate.proposedTime.add(approvalDelay) < block.timestamp, "Delay has not passed");

        emit UpgradeStrat(stratCandidate.implementation);

        strategies[pid].retireStrat();
        strategies[pid] = IStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;

        earn(pid);
    }
    /*
    =================
    ===== EXTRA ===== 
    =================
    */
    
     /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function earn(uint256 pid) public {
        uint _bal = LPToken(pid).balanceOf(address(this));
        if(isStratBoosted(pid)) {
            LPToken(pid).safeTransfer(address(boostContract[pid]), _bal);
            IBoost(getBoostContract(pid)).stake(_bal, msg.sender);
        } else {
            LPToken(pid).safeTransfer(address(strategies[pid]), _bal);
            strategies[pid].deposit();
        }
    }
    
    
    // Check to make sure we're not stealing people's funds or rewards
    // Only usable if someone decides to send random tokens to the contract
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 i = 0;
        for(i = 0; i < strategies.length; i++) {
            require(_token != address(LPToken(i)), "!token");
        }
        require(_token != address(reward), "!reward");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
    
    /*
    ====================
    ===== MODIFIER ===== 
    ====================
    */
    
    //Only used for the depositRewards so no one breaks anything
    modifier onlyStrategy(uint256 pid) {
        require(msg.sender == address(strategies[pid]), "!strategy");
        _;
    }
    
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }
}