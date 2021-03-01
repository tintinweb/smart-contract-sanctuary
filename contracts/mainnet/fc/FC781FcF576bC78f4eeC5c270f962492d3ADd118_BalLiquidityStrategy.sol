/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/interfaces/kaya/ISmartPool.sol


pragma solidity ^0.6.12;
interface ISmartPool{

    function joinPool(uint256 amount) external;

    function exitPool(uint256 amount) external;

    function transferCash(address to,uint256 amount)external;

    function token()external view returns(address);

    function assets()external view returns(uint256);
}

// File: contracts/interfaces/kaya/IController.sol


pragma solidity ^0.6.12;
interface IController {

    function invest(address, uint256) external;

    function exec(
        address _strategy,
        bool _useToken,
        uint256 _useAmount,
        string memory _signature,
        bytes memory _data) external;

    function harvest(uint256) external;

    function harvestAll(address _vault)external;

    function assets() external view returns (uint256);

    function vaults(address) external view returns(address);

    function strategies(address) external view returns(address);

    function inRegister() external view returns (bool);
}

// File: contracts/interfaces/balancer/IBPool.sol


pragma solidity ^0.6.12;

interface IBPool {

    function isPublicSwap() external view returns (bool);
    function isFinalized() external view returns (bool);
    function isBound(address t) external view returns (bool);
    function getNumTokens() external view returns (uint);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getController() external view returns (address);

    function setSwapFee(uint swapFee) external;
    function setController(address manager) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    ) external returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);

    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) external pure returns (uint spotPrice);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint poolAmountIn);

}

// File: contracts/interfaces/balancer/IBFactory.sol


pragma solidity ^0.6.12;

interface IBFactory {

    function isBPool(address pool) external view returns (bool);
    function newBPool() external returns (address);

}

// File: contracts/interfaces/uniswap-v2/IUniswapV2Pair.sol


pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// File: contracts/libraries/UniswapV2Library.sol


pragma solidity ^0.6.12;




library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/interfaces/uniswap-v2/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interfaces/uniswap-v2/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/libraries/UniswapV2ExpandLibrary.sol


pragma solidity ^0.6.12;




library UniswapV2ExpandLibrary{
    using SafeERC20 for IERC20;

    IUniswapV2Router02 constant public route=IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function sortTokens(address tokenA, address tokenB) internal pure returns (address,address) {
       return UniswapV2Library.sortTokens(tokenA,tokenB);
    }

    function pairFor(address tokenA, address tokenB) internal pure returns (address) {
        return UniswapV2Library.pairFor(route.factory(),tokenA,tokenB);
    }

    function getReserves(address tokenA, address tokenB) internal view returns (uint,uint) {
        return UniswapV2Library.getReserves(route.factory(),tokenA,tokenB);
    }

    function quote(uint amountA,uint reserveA, uint reserveB) internal pure returns (uint) {
        return UniswapV2Library.quote(amountA,reserveA,reserveB);
    }

    function getAmountIn(address inputToken,address outputToken,uint256 amountOut)internal view returns(uint256){
        (uint reserveA, uint reserveB) = getReserves(inputToken, outputToken);
        return UniswapV2Library.getAmountIn(amountOut,reserveA,reserveB);
    }

    function getAmountOut(address inputToken,address outputToken,uint256 amountIn)internal view returns(uint256){
        (uint reserveA, uint reserveB) = getReserves(inputToken, outputToken);
        return UniswapV2Library.getAmountOut(amountIn,reserveA,reserveB);
    }

    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory) {
        return UniswapV2Library.getAmountsOut(route.factory(),amountIn,path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory) {
        return UniswapV2Library.getAmountsIn(route.factory(),amountOut,path);
    }

    function swap(address to,address inputToken,address outputToken,uint256 amountIn,uint256 amountOut) internal{
        IUniswapV2Pair pair=IUniswapV2Pair(pairFor(inputToken,outputToken));
        IERC20(inputToken).safeTransfer(address(pair), amountIn);
        (address token0,) = sortTokens(inputToken, outputToken);
        (uint amount0Out, uint amount1Out) = inputToken == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out,amount1Out, to, new bytes(0));
    }


}

// File: contracts/libraries/ExpandMath.sol


pragma solidity ^0.6.12;

// a library for performing various math operations

library ExpandMath {

    uint256 internal constant BONE = 10**18;

    // Add two numbers together checking for overflows
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    // subtract two numbers and return diffecerence when it underflows
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    // Subtract two numbers checking for underflows
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    // Multiply two 18 decimals numbers
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    // Divide two 18 decimals numbers
    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

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

// File: contracts/storage/GovIdentityStorage.sol


pragma solidity ^0.6.12;


library GovIdentityStorage {

  bytes32 public constant govSlot = keccak256("GovIdentityStorage.storage.location");

  struct Identity{
    address governance;
    address strategist;
    address rewards;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov_slot := loc
    }
  }
}

// File: contracts/GovIdentity.sol


pragma solidity ^0.6.12;


contract GovIdentity {

    constructor() public {
        _build();
    }

    function _build() internal{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = msg.sender;
        identity.strategist = msg.sender;
        identity.rewards = msg.sender;
    }
    modifier onlyGovernance() {
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        require(msg.sender == identity.governance, "GovIdentity.onlyGovernance: !governance");
        _;
    }

    modifier onlyStrategistOrGovernance() {
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        require(msg.sender == identity.strategist || msg.sender == identity.governance, "GovIdentity.onlyGovernance: !governance and !strategist");
        _;
    }

    function setRewards(address _rewards) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.rewards = _rewards;
    }

    function setStrategist(address _strategist) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.strategist = _strategist;
    }

    function setGovernance(address _governance) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = _governance;
    }

    function getRewards() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.rewards ;
    }

    function getStrategist() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.strategist;
    }

    function getGovernance() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.governance;
    }

}

// File: contracts/strategies/BalLiquidityStrategy.sol


pragma solidity ^0.6.12;











contract BalLiquidityStrategy is ERC20, GovIdentity {

    using SafeERC20 for IERC20;
    using Address for address;
    using ExpandMath for uint256;

    uint256 constant public INIT_NUM=1;
    uint256 constant public INIT_NUM_VALUE=INIT_NUM*(1e18);

    uint256[] public weights;
    uint256[] public amounts;
    address[] public tokens;

    IController public controller;
    IBPool public bPool;

    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public bFactory = address(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);

    constructor(
        address _controller,
        address[] memory _tokens,
        uint256[] memory _weights,
        uint256[] memory _amounts)
    public
    ERC20('Share Token', 'ST'){
        require(_tokens.length == _weights.length && _weights.length == _amounts.length, 'Strategy: Parameter error');
        tokens = _tokens;
        weights = _weights;
        amounts = _amounts;
        controller = IController(_controller);
    }

    function getTokens()public view returns(address[] memory){
       return tokens;
    }

    function getWeights()public view returns(uint256[] memory){
        return weights;
    }
    function pullToken(address _token)internal returns(uint256 amount){
        IERC20 token = IERC20(_token);
        amount = token.balanceOf(msg.sender);
        if(amount>0){
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function clearToken(address to,address _token) internal {
        uint256 amountIn = IERC20(WETH).balanceOf(address(this));
        if (amountIn > 0 && WETH != _token) {
            uint256 amountOut = UniswapV2ExpandLibrary.getAmountOut(WETH, _token, amountIn);
            UniswapV2ExpandLibrary.swap(address(this), WETH, _token, amountIn, amountOut);
        }
        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    function swapToWeth(address _token, uint256 amountIn) internal returns(uint256 amountOut){
        amountOut=amountIn;
        if (amountIn > 0 && WETH != _token) {
            amountOut = UniswapV2ExpandLibrary.getAmountOut(_token, WETH, amountIn);
            UniswapV2ExpandLibrary.swap(address(this), _token, WETH, amountIn, amountOut);
        }
    }

    function swapToToken(address _token, uint256 amountOut) internal returns(uint256 amountIn){
        amountIn=amountOut;
        if (amountOut > 0 && WETH != _token) {
            amountIn = UniswapV2ExpandLibrary.getAmountIn(WETH, _token, amountOut);
            UniswapV2ExpandLibrary.swap(address(this), WETH, _token, amountIn, amountOut);
        }
    }

    function syncTokens()internal{
        tokens=bPool.getCurrentTokens();
        uint256 totalSupply = totalSupply();
        for(uint256 i=0;i<tokens.length;i++){
            weights[i]=bPool.getDenormalizedWeight(tokens[i]);
            uint256 tbal = IERC20(tokens[i]).balanceOf(address(bPool));
            uint256 initAmount = tbal.bdiv(totalSupply).mul(INIT_NUM);
            amounts[i]=initAmount;
        }
    }

    function vaultInfo() internal view returns (address, address){
        address _vault = controller.vaults(address(this));
        address _token = ISmartPool(_vault).token();
        return (_vault, _token);
    }

    function calcOneShareAmount(uint256 direction) internal view returns (uint256 oneShareWethAmount, uint256[] memory oneShareAmounts){
        uint256 totalSupply = totalSupply().sub(INIT_NUM_VALUE);
        oneShareAmounts=new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 oneShareAmount;
            if (totalSupply == 0) {
                oneShareAmount = amounts[i];
            } else {
                uint256 tbal = IERC20(tokens[i]).balanceOf(address(bPool));
                oneShareAmount = tbal.bdiv(totalSupply);
            }
            oneShareAmounts[i] = oneShareAmount;
            if (tokens[i] != WETH) {
                if(direction==0){
                    oneShareAmount=UniswapV2ExpandLibrary.getAmountIn(WETH,tokens[i], oneShareAmount);
                }else{
                    oneShareAmount=UniswapV2ExpandLibrary.getAmountOut(tokens[i], WETH, oneShareAmount);
                }
            }
            oneShareWethAmount = oneShareWethAmount.add(oneShareAmount);
        }
    }

    function init() external {
        require(address(bPool) == address(0), 'Strategy.init: already initialised');
        require(msg.sender == address(controller), 'Strategy.init: !controller');
        bPool = IBPool(IBFactory(bFactory).newBPool());
        (,address _vaultToken) = vaultInfo();
        uint256 amountIn=pullToken(_vaultToken);
        swapToWeth(_vaultToken,amountIn);
        for (uint256 i = 0; i < tokens.length; i++) {
            swapToToken(tokens[i],amounts[i]);
            //Approve the balancer pool
            IERC20(tokens[i]).safeApprove(address(bPool), uint256(-1));
            // Bind tokens
            bPool.bind(tokens[i], amounts[i], weights[i]);
        }
        clearToken(msg.sender,_vaultToken);
        _mint(address(this), INIT_NUM_VALUE);
    }

    function approveTokens() public {
        require(address(bPool) != address(0), 'Strategy.approveTokens: not initialised');
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token=IERC20(tokens[i]);
            if(token.allowance(address(this),address(bPool))>0){
                token.safeApprove(address(bPool), uint256(0));
            }
            token.safeApprove(address(bPool), uint256(-1));
        }
    }

    function bind(address _token, uint256 _amount, uint256 _weight) external {
        require(msg.sender == address(controller), 'Strategy.bind: !controller');
        require(address(bPool) != address(0), 'Strategy.bind: not initialised');
        require(!bPool.isBound(_token), 'Strategy.bind: the token is bound');
        (address _vault,address _vaultToken) = vaultInfo();
        uint256 amountIn= pullToken(_vaultToken);
        swapToWeth(_vaultToken,amountIn);
        swapToToken(_token,_amount);
        IERC20 token=IERC20(_token);
        //Approve the balancer pool
        if(token.allowance(address(this),address(bPool))>0){
            token.safeApprove(address(bPool), uint256(0));
        }
        token.safeApprove(address(bPool), uint256(-1));
        // Bind tokens
        bPool.bind(_token, _amount, _weight);
        syncTokens();
        clearToken(_vault,_vaultToken);
    }

    function rebind(address _token, uint256 _amount, uint256 _weight) external {
        require(msg.sender == address(controller), 'Strategy.rebind: !controller');
        require(address(bPool) != address(0), 'Strategy.rebind: not initialised');
        require(bPool.isBound(_token), 'Strategy.bind: the token is bound');
        (address _vault,address _vaultToken) = vaultInfo();
        uint256 amountIn= pullToken(_vaultToken);
        swapToWeth(_vaultToken,amountIn);
        swapToToken(_token,_amount);
        IERC20 token = IERC20(_token);
        bPool.gulp(_token);
        uint256 oldBalance = token.balanceOf(address(bPool));
        if (_amount > oldBalance) {
            swapToToken(_token,_amount.sub(oldBalance));
            if(token.allowance(address(this),address(bPool))>0){
                token.safeApprove(address(bPool), uint256(0));
            }
            token.safeApprove(address(bPool), uint256(-1));
        }
        bPool.rebind(_token, _amount, _weight);
        syncTokens();
        amountIn = token.balanceOf(address(this));
        swapToWeth(_token, amountIn);
        clearToken(_vault,_vaultToken);
    }

    function unbind(address _token) external {
        require(msg.sender == address(controller), 'Strategy.unbind: !controller');
        require(address(bPool) != address(0), 'Strategy.unbind: not initialised');
        IERC20 token = IERC20(_token);
        bPool.unbind(_token);
        syncTokens();
        uint256 amountIn = token.balanceOf(address(this));
        swapToWeth(_token, amountIn);
        (address _vault,address _vaultToken) = vaultInfo();
        clearToken(_vault,_vaultToken);
    }

    function deposit(uint256 _amount) external {
        require(msg.sender == address(controller), 'Strategy.deposit: !controller');
        (address _vault,address _vaultToken) = vaultInfo();
        require(_amount > 0, 'Strategy.deposit: token balance is zero');
        IERC20 tokenContract = IERC20(_vaultToken);
        require(tokenContract.balanceOf(msg.sender) >= _amount, 'Strategy.deposit: Insufficient balance');
        tokenContract.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 hasWethTotal = swapToWeth(_vaultToken,_amount);
        (uint256 oneShareWethAmount,uint256[] memory oneShareAmounts) = calcOneShareAmount(0);
        uint256 preShareCount = hasWethTotal.div(oneShareWethAmount);
        require(preShareCount > 0, 'Strategy.deposit: Must be greater than 0 amount by pre share Count ');
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amountOut = oneShareAmounts[i].mul(preShareCount);
            swapToToken(tokens[i], amountOut);
            uint256 tbal = IERC20(tokens[i]).balanceOf(address(bPool));
            bPool.rebind(tokens[i], tbal.add(amountOut), weights[i]);
        }
        _mint(address(this), preShareCount.mul(1e18));
        clearToken(_vault,_vaultToken);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == address(controller), 'Strategy.withdraw: !controller');
        require(_amount > 0, 'Strategy.withdraw: Must be greater than 0 amount');
        require(_amount <= available(), 'Strategy.withdraw: Must be less than assets');
        (address _vault,address _vaultToken) = vaultInfo();
        uint256 needWeth = _amount;
        if (WETH != _vaultToken) {
            needWeth = UniswapV2ExpandLibrary.getAmountIn(WETH, _vaultToken, _amount);
        }
        (uint256 oneShareWethAmount,uint256[] memory oneShareAmounts) = calcOneShareAmount(1);
        uint256 preShareCount = needWeth.div(oneShareWethAmount);
        uint256 burnAmount=preShareCount.mul(1e18);
        require(totalSupply().sub(burnAmount) >= INIT_NUM_VALUE, 'Strategy.withdraw: Must be greater than the number of initializations');
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amountIn = oneShareAmounts[i].mul(preShareCount);
            uint256 tbal = IERC20(tokens[i]).balanceOf(address(bPool));
            bPool.rebind(tokens[i], tbal.sub(amountIn), weights[i]);
            swapToWeth(tokens[i], amountIn);
        }
        _burn(address(this), burnAmount);
        clearToken(_vault,_vaultToken);
    }

    function withdraw(address _token) external returns (uint256 balance){
        require(msg.sender == address(controller), 'Strategy.withdraw: !controller');
        IERC20 token=IERC20(_token);
        balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(address(controller), balance);
        }
    }

    function withdrawAll() external {
        require(msg.sender == address(controller), 'Strategy.withdrawAll: !controller');
        require(totalSupply() > INIT_NUM_VALUE, 'Strategy.withdrawAll: Must be greater than the number of initializations');
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amountOut = amounts[i];
            IERC20 token=IERC20(tokens[i]);
            require(token.balanceOf(address(bPool))>=amountOut,'Strategy.withdrawAll: token balance < amountOut');
            bPool.rebind(tokens[i],amountOut,bPool.getDenormalizedWeight(tokens[i]));
            uint256 amountIn = token.balanceOf(address(this));
            swapToWeth(tokens[i], amountIn);
        }
        _burn(address(this), totalSupply().sub(INIT_NUM_VALUE));
        (address _vault,address _vaultToken) = vaultInfo();
        clearToken(_vault,_vaultToken);
    }

    function assets() public view returns (uint256){
        uint256 amountWethOut;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amountIn = IERC20(tokens[i]).balanceOf(address(bPool)).sub(amounts[i]);
            if(amountIn>0){
                if (tokens[i] == WETH) {
                    amountWethOut = amountWethOut.add(amountIn);
                } else {
                    amountWethOut = amountWethOut.add(UniswapV2ExpandLibrary.getAmountOut(tokens[i], WETH, amountIn));
                }
            }
        }
        (,address _token) = vaultInfo();
        if (amountWethOut > 0) {
            return UniswapV2ExpandLibrary.getAmountOut(WETH, _token, amountWethOut);
        } else {
            return 0;
        }
    }

    function available() public view returns (uint256){
        return assets();
    }
}