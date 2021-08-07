/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// File: @openzeppelin\contracts\math\SafeMath.sol

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: ..\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: ..\node_modules\@openzeppelin\contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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

// File: ..\node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// File: contracts\OwnableContract.sol

pragma solidity 0.6.6;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts\ChickToken.sol

pragma solidity 0.6.6;




contract ChickToken is ERC20("loserchick", "CHICK"), OwnableContract{

    using SafeMath for uint256;

    address public teamAddr;

    address public boardAddr;

    uint256 public dayIndex = 0;
    mapping(uint256 => uint256) public burnAmountPerDay;

    mapping(address => uint256) public addUpSwapCchickCountPerUser;

    uint256 public totalSwapCount = 0;

    uint256 public chickSwapCchickIndex = 0;

    event ChickSwapCchick(address userAddress, uint256 amount, uint256 index);

    constructor(address _teamAddr, address _boardAddr) public {
        teamAddr = _teamAddr;
        boardAddr = _boardAddr;

        _setupDecimals(18);
        _mint(msg.sender, uint256(13333333).mul(1e18));
    }

    function updateBurnAmount(uint256 amount) internal{
        dayIndex = now / 86400;
        burnAmountPerDay[dayIndex] = amount.add(burnAmountPerDay[dayIndex]);
    }

    function getBurnAmountPerDay(uint256 _dayIndex) public view returns(uint256){
        return burnAmountPerDay[_dayIndex];
    }

    function getAddUpSwapCchickCountPerUser(address userAddr) public view returns(uint256){
        return addUpSwapCchickCountPerUser[userAddr];
    }

    function chickSwapCchick(uint256 floatAmount) public{
        require(floatAmount != 0, 'floatAmount cannot be zero');               
        addUpSwapCchickCountPerUser[msg.sender] = floatAmount.add(addUpSwapCchickCountPerUser[msg.sender]);

        uint256 amount = floatAmount.mul(1e18);

        uint256 teamAmount = amount.div(10);  // 10 %
        _transfer(msg.sender, teamAddr, teamAmount);

        uint256 boardAmount = amount.div(5);  // 20 %
        _transfer(msg.sender, boardAddr, boardAmount);
        
        uint256 burnAmount = amount.mul(7).div(10); // 70 %
        _burn(msg.sender, burnAmount);

        updateBurnAmount(burnAmount);

        totalSwapCount = totalSwapCount.add(floatAmount);

        chickSwapCchickIndex++;

        emit ChickSwapCchick(msg.sender, floatAmount, chickSwapCchickIndex);
    }

    function updateTeamAddr(address _teamAddr) public onlyOwner{
        teamAddr = _teamAddr;
    }

    function updateBoardAddr(address _boardAddr) public onlyOwner{
        boardAddr = _boardAddr;
    }
}

// File: contracts\EggToken.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;





contract EggToken is ERC20("LoserchickEgg", "EGG"), OwnableContract{

    using SafeMath for uint256;

    uint256 public constant MAX_TOTAL_SUPPLY  = 7000000 * 1e18;

    uint256 public dayIndex = 0;

    uint256 public perUserPerDayLimit;
    uint256 public marketPerDayLimit;

    uint256 public addUpClaimCount;
    uint256 public addUpBurnCount;

    address public signer1;
    address public signer2;

    mapping(uint256 => bool) public claimedOrderId;

    mapping(uint256 => mapping(address => uint256)) public userClaimCountPerDay; // Maximum per user per day.
    
    mapping(uint256 => uint256) public marketClaimCountPerDay; // Maximum market per day.

    mapping(uint256 => uint256) public burnAmountPerDay;

    uint256[4] public cChickSwapChickLimit;

    uint256[4] public ceggSwapEggProportion;

    mapping(address => uint256) public addUpSwapCeggCountPerUser;

    ChickToken public chickToken;

    uint256 public claimIndex = 0;

    event Claim(uint256 orderId, uint256 amount, address userAddress, address signer, uint256 index);
    event AleadyClaim(uint256 orderId, uint256 amount, address userAddress);
    event Burn(address userAddress, uint256 amount);

    constructor(address _chickAddr) public {
        chickToken = ChickToken(_chickAddr);

        mint(msg.sender, 1);
        _setupDecimals(18);
        perUserPerDayLimit = 1000;
        marketPerDayLimit = 100000;

        cChickSwapChickLimit[0] = 10;
        cChickSwapChickLimit[1] = 20;
        cChickSwapChickLimit[2] = 100;
        cChickSwapChickLimit[3] = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        ceggSwapEggProportion[0] = 8; // special case : if  addUpSwapCchickCountPerUser[userAddr] <=10 , the max EGG count is 8 
        
        //  maxEggAmount = chickCount.mul(ceggSwapEggProportion[index]).div(100);
        ceggSwapEggProportion[1] = 60; 
        ceggSwapEggProportion[2] = 50;
        ceggSwapEggProportion[3] = 40;
    }

    function setDev1(address _signer) public onlyOwner {
        signer1 = _signer;
    }

    function setDev2(address _signer) public onlyOwner {
        signer2 = _signer;
    }

    function getUserClaimCountPerDay(uint256 _dayIndex, address userAddr) public view returns(uint256){
        return userClaimCountPerDay[_dayIndex][userAddr];
    }

    function getMarketClaimCountPerDay(uint256 _dayIndex) public view returns(uint256){
        return marketClaimCountPerDay[_dayIndex];
    }

    function getBurnAmountPerDay(uint256 _dayIndex) public view returns(uint256){
        return burnAmountPerDay[_dayIndex];
    }

    function getInCirculationCount() public view returns(uint256){
        return addUpClaimCount.sub(addUpBurnCount);
    }

    function getAwaitMiningCount() public view returns(uint256){
        return MAX_TOTAL_SUPPLY.div(1e18).sub(addUpClaimCount);
    }

    function updateCeggSwapEggProportion(uint256 index, uint256 proportion) public onlyOwner{
        require(index < 4, 'Index cannot be greater than 4 !');
        ceggSwapEggProportion[index] = proportion;
    }

    function updateLimitProportion(uint256 index, uint256 proportion) public onlyOwner{
        require(index < 4, 'Index cannot be greater than 4 !');
        cChickSwapChickLimit[index] = proportion;
    }

    // check to avoid bad base, such as centralized db changed by hacker  
    function checkRestrictions(uint256 userAddUpCchickCount, uint256 userAddUpClaimEggCount) internal view returns(bool){
        require(userAddUpClaimEggCount <= userAddUpCchickCount, 'error: userAddUpClaimEggCount > userAddUpCchickCount');
        uint256 index = 0;
        for(uint256 i = 0; i<cChickSwapChickLimit.length; i++){
            if(userAddUpCchickCount <= cChickSwapChickLimit[i]){
                index = i;
                break;
            }
        }
        uint256 maxEggAmount;
        if(index == 0){
            maxEggAmount = ceggSwapEggProportion[0];
        }else{
            maxEggAmount = userAddUpCchickCount.mul(ceggSwapEggProportion[index]).div(100);
        }

        require(maxEggAmount >= userAddUpClaimEggCount, 'error: maxEggAmount < userAddUpClaimEggCount');
    }

    function batchClaim(uint256[] memory orderId, uint256[] memory floatAmount, bytes[] memory signature) public{
        require(orderId.length == floatAmount.length, "orderId length should eq floatAmount length");
        require(floatAmount.length == signature.length, "floatAmount length should eq signature length");
        updateDay();
        for(uint256 i=0; i<orderId.length; i++){
            claim(orderId[i], floatAmount[i], signature[i]);
        }
    }

    function claim(uint256 orderId, uint256 floatAmount, bytes memory signature) internal{
        if(claimedOrderId[orderId]){
            emit AleadyClaim(orderId, floatAmount, msg.sender);
            return;
        }
        require(userClaimCountPerDay[dayIndex][msg.sender].add(floatAmount) <= perUserPerDayLimit, 'Maximum single day limit exceeded！');
        require(marketClaimCountPerDay[dayIndex].add(floatAmount) <= marketPerDayLimit, 'It has exceeded the maximum market quota！');

        bytes32 hash1 = keccak256(abi.encode(address(this), msg.sender, orderId, floatAmount));

        bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

        address signer = recover(hash2, signature);
        require(signer == signer1 || signer == signer2, "invalid signer");

        uint256 userAddUpcChickCount = chickToken.getAddUpSwapCchickCountPerUser(msg.sender);
        uint256 useAddUpClaimEggCount = floatAmount.add(addUpSwapCeggCountPerUser[msg.sender]);
        checkRestrictions(userAddUpcChickCount, useAddUpClaimEggCount);

        mint(msg.sender, floatAmount);

        claimedOrderId[orderId] = true;
        userClaimCountPerDay[dayIndex][msg.sender] = floatAmount.add(userClaimCountPerDay[dayIndex][msg.sender]);
        marketClaimCountPerDay[dayIndex] = floatAmount.add(marketClaimCountPerDay[dayIndex]);
        addUpSwapCeggCountPerUser[msg.sender] = useAddUpClaimEggCount;

        claimIndex++;

        emit Claim(orderId, floatAmount, msg.sender, signer, claimIndex);
    }

    function mint(address _to, uint256 _amount) internal{
        uint256 intAmount = _amount.mul(1e18);
        uint256 totalSupply = totalSupply();
        require(totalSupply.add(intAmount) <= MAX_TOTAL_SUPPLY,"invalid _amount");
        _mint(_to, intAmount);
    
        addUpClaimCount = addUpClaimCount.add(_amount );
    }

    function burn(uint256 amount) public{
        require(amount != 0, 'burnAmount cannot be zero');
        
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        transfer(deadAddress, amount.mul(1e18));
        emit Burn(msg.sender, amount);

        addUpBurnCount = addUpBurnCount.add(amount);

        updateDay();
        burnAmountPerDay[dayIndex] = amount.add(burnAmountPerDay[dayIndex]);
    }

    function setPerUserPerDayLimit(uint _perUserPerDayLimit) public onlyAdmin {
        perUserPerDayLimit = _perUserPerDayLimit;
    }

    function setMarketPerDayLimit(uint _marketPerDayLimit) public onlyAdmin {
        marketPerDayLimit = _marketPerDayLimit;
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function updateDay() internal{
        dayIndex = now / 86400;
    }
}

// File: contracts\SmashEggs.sol

pragma solidity 0.6.6;





interface SmashEggFunctionInterface{
     function smashEggs(uint256 amount) external;
     event SmashEggsEvent(address userAddr, uint256 eggCount, uint256 chickCount, address[] chickAddrArray, uint256[] tokenIdArray);
     event ActivityEvent(address userAddr, uint256 NFTConut, address NFTAddr);
}

contract SmashEggs is OwnableContract{

    using SafeMath for uint256;

    using SafeERC20 for EggToken;

    struct UserStakeInfo {
        uint256 amount;   
        uint256 stakeBlockNunber; 
    }

    mapping(address => uint256) public userSmashTotalEggCount;
    uint256 public smashEggTotalUserCount = 0;

    mapping(uint256 => mapping(address => bool)) public smashEggUserRecord;
    mapping(uint256 => uint256) public smashEggUserCountPerDay;

    mapping(uint256 => mapping(address => bool)) public stakeEggUserRecord;
    mapping(uint256 => uint256) public stakeEggUserCountPerDay;

    EggToken public eggToken; 
    SmashEggFunctionInterface public smashEggFunctionContract;

    bool public enableUnstakeEgg = false;
    bool public enableSmashEgg = false;

    mapping(address => UserStakeInfo) private userStakeInfo; 

    event EventStakeEgg(address user,  uint256 amount);
    event EventUnstakeEgg(address user,  uint256 amount);
    
    constructor(address _eggToken, address _smashEggFunctionContract) public {
        eggToken = EggToken(_eggToken);
        smashEggFunctionContract = SmashEggFunctionInterface(_smashEggFunctionContract);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "must use EOA");
        _;
    }


    function stakeEgg(uint256 _amount) public  onlyEOA {
        address user = msg.sender; 

        uint256 dayIndex = now / 86400;
        if(!stakeEggUserRecord[dayIndex][user]){
            stakeEggUserCountPerDay[dayIndex] = stakeEggUserCountPerDay[dayIndex] + 1;
            stakeEggUserRecord[dayIndex][user] = true;
            
        }

        UserStakeInfo storage userInfo = userStakeInfo[user];

        userInfo.stakeBlockNunber = block.number;

        uint256 userEggBalanceInt =  eggToken.balanceOf(user);
        uint256 amountInt = _amount.mul(1e18);
        if( _amount > 0  && userEggBalanceInt >= amountInt) {
             eggToken.safeTransferFrom(user, address(this), amountInt);
             userInfo.amount = userInfo.amount.add(_amount);
             emit EventStakeEgg(user, _amount);
        }       
    }

    function unstakeEgg(uint256 _amount) public onlyEOA {
        require(enableUnstakeEgg, 'enableUnstakeEgg is false');
        address user = msg.sender; 
        UserStakeInfo storage userInfo = userStakeInfo[user];
        require(userInfo.amount >= _amount, 'userInfo.amount < _amount');

        userInfo.amount = userInfo.amount.sub(_amount);
        eggToken.safeTransfer(user, _amount.mul(1e18));
        emit EventUnstakeEgg(user, _amount);
    }

    function smashEggs(uint256 _amount) external onlyEOA {        
        require(enableSmashEgg, 'enableSmashEgg is false');
        address user = msg.sender;        
        UserStakeInfo storage userInfo = userStakeInfo[user];
        require(userInfo.amount >= _amount, 'userInfo.amount < _amount');
        require(userInfo.stakeBlockNunber != block.number, 'userInfo.stakeBlockNunber == block.number');

        userInfo.amount = userInfo.amount.sub(_amount);
        eggToken.burn(_amount);

        smashEggFunctionContract.smashEggs(_amount);

        uint256 dayIndex = now / 86400;
        if(!smashEggUserRecord[dayIndex][user]){
            smashEggUserCountPerDay[dayIndex] = smashEggUserCountPerDay[dayIndex] + 1;
            smashEggUserRecord[dayIndex][user] = true;            
        }

        if(userSmashTotalEggCount[user] == 0 ) {
            smashEggTotalUserCount++;
        }

        userSmashTotalEggCount[user] = userSmashTotalEggCount[user].add(_amount);
    }

    function getUserStakeAmount(address _user) public view returns (uint256 _amount) {
        UserStakeInfo memory userInfo = userStakeInfo[_user];
        _amount = userInfo.amount;
    }

    function getUserStakeInfo(address _user) public view returns (uint256 _amount, uint256 _stakeBlockNunber) {
        UserStakeInfo memory userInfo = userStakeInfo[_user];
        _amount = userInfo.amount;
        _stakeBlockNunber = userInfo.stakeBlockNunber;
    }

    function updateEnableUnstakeEgg(bool _enableUnstakeEgg) public onlyAdmin{
        enableUnstakeEgg = _enableUnstakeEgg;
    }

    function updateEnableSmashEgg(bool _enableSmashEgg) public onlyAdmin{
        enableSmashEgg = _enableSmashEgg;
    }

    function updateSmashEggFunctionContract(address _smashEggFunctionContract) public onlyOwner{
        smashEggFunctionContract = SmashEggFunctionInterface(_smashEggFunctionContract);
    }

    function getSmashEggUserCountPerDay(uint256 dayIndex) public view returns(uint256){
        return smashEggUserCountPerDay[dayIndex];
    }

    function getSmashEggUserCountToday() public view returns(uint256){
        uint256 _dayIndex = now / 86400;
        return smashEggUserCountPerDay[_dayIndex];
    }

    function getSmashEggUserCountYesterday() public view returns(uint256){
        uint256 _dayIndex = now / 86400 - 1;
        return smashEggUserCountPerDay[_dayIndex];
    }

    function getStakeEggUserCountPerDay(uint256 dayIndex) public view returns(uint256){
        return stakeEggUserCountPerDay[dayIndex];
    }

    function getStakeEggUserCountToday() public view returns(uint256){
        uint256 _dayIndex = now / 86400;
        return stakeEggUserCountPerDay[_dayIndex];
    }

    function getStakeEggUserCountYesterday() public view returns(uint256){
        uint256 _dayIndex = now / 86400 - 1;
        return stakeEggUserCountPerDay[_dayIndex];
    }

    function getUserSmashTotalEggCount(address _user) public view returns(uint256){
        return userSmashTotalEggCount[_user];
    }
}