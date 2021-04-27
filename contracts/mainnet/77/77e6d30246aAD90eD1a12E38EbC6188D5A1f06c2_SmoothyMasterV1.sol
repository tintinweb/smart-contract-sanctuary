/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



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

// File: openzeppelin-solidity/contracts/utils/Address.sol



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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol



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

// File: openzeppelin-solidity/contracts/math/Math.sol



pragma solidity >=0.6.0 <0.8.0;

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
}

// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



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

// File: openzeppelin-solidity/contracts/utils/Pausable.sol



pragma solidity >=0.6.0 <0.8.0;


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
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// File: contracts/UpgradeableOwnable.sol



pragma solidity >=0.6.0 <0.8.0;


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
contract UpgradeableOwnable {
    bytes32 private constant _OWNER_SLOT = 0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        assert(_OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1));
        _setOwner(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function _setOwner(address newOwner) private {
        bytes32 slot = _OWNER_SLOT;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(slot, newOwner)
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address o) {
        bytes32 slot = _OWNER_SLOT;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            o := sload(slot)
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner(), address(0));
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}

// File: contracts/liquidity-mining/SMTYToken.sol



pragma solidity 0.6.12;




contract SMTYToken is ERC20Pausable, UpgradeableOwnable {

    mapping(address => bool) public isMinter;
    mapping(address => bool) public allowedSender;
    bool public isAllSenderAllowed = true;

    event AddAllowedSender(address indexed sender);
    event RemoveAllowedSender(address indexed sender);
    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);

    // solium-disable-next-line
    constructor() public ERC20("", "") {}

    function initialize()
        external
        onlyOwner
    {
        addMinter(msg.sender);
        addAllowedSender(address(0x0)); // allow mint
    }

    function name() public view virtual override returns (string memory) {
        return "SMTYToken";
    }

    function symbol() public view virtual override returns (string memory) {
        return "SMTY";
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function pause(uint256 flag) public onlyOwner {
        _pause();
    }

    function unpause(uint256 flag) public onlyOwner {
        _unpause();
    }

    function addMinter(address _minter) public onlyOwner {
        isMinter[_minter] = true;
        emit AddMinter(_minter);
    }

    function removeMinter(address _minter) public onlyOwner {
        isMinter[_minter] = false;
        emit RemoveMinter(_minter);
    }

    function addAllowedSender(address _sender) public onlyOwner {
        allowedSender[_sender] = true;
        emit AddAllowedSender(_sender);
    }

    function removeAllowedSender(address _sender) public onlyOwner {
        allowedSender[_sender] = false;
        emit RemoveAllowedSender(_sender);
    }

    function enableAllSenderAllowed(bool _enable) public onlyOwner {
        isAllSenderAllowed = _enable;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);

        require(isAllSenderAllowed || allowedSender[_from], "Sender is not allowed");
    }

    function mint(address _to, uint256 _amount) public {
        require(isMinter[msg.sender], "Only minter can mint");
        _mint(_to, _amount);
    }
}

// File: contracts/liquidity-mining/VotingEscrow.sol



pragma solidity ^0.6.0;






contract VotingEscrow is IERC20, UpgradeableOwnable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _smty;
    IERC20 public _syUSD;
    address public _collector;

    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public constant MAX_TIME = 1460 days;

    struct LockData {
        uint256 amount;
        uint256 end;
    }
    mapping (address => LockData) private _locks;
    uint256 public _totalLockedSMTY;

    uint256 private _accRewardPerBalance;
    mapping (address => uint256) private _rewardDebt;

    // Variable for earning with locks
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }
    mapping(address => LockedBalance[]) _userEarnings;
    // Duration that rewards are streamed over
    uint256 public constant REWARDS_DURATION = 86400 * 7;
    // Duration of lock/earned penalty period
    uint256 public constant LOCK_DURATION = REWARDS_DURATION * 13;
    struct Balances {
        uint256 earned;
        uint256 penaltyEarningDebt;
    }
    mapping(address => Balances) private  _userBalances;
    uint256 private _accPenaltyEarningPerBalance;
    bool public _distributePenaltyEarning = false;  // burn or redistribute penalty of earning

    event LockCreate(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event LockExtend(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event LockIncreaseAmount(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event Withdraw(address indexed user, uint256 amount);
    event EarningAdd(address indexed user, uint256 amount);
    event EarningWithdraw(address indexed user, uint256 amount, uint256 penaltyAmount);

    // solium-disable-next-line
    constructor() public {}

    /*
     * Owner methods
     */
    function initialize(IERC20 smty, IERC20 syUSD, address collector) external onlyOwner {
        _name = "Voting Escrow Smoothy Token";
        _symbol = "veSMTY";
        _decimals = 18;
        _smty = smty;
        _syUSD = syUSD;
        _collector = collector;
        _distributePenaltyEarning = true;
    }

    // veSMTY ERC20 interface
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        return false;
    }

    function allowance(
        address owner,
        address spender
    )
        public view virtual override returns (uint256)
    {
        return 0;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public virtual override returns (bool)
    {
        return false;
    }

    function amountOf(address account) public view returns (uint256) {
        return _locks[account].amount;
    }

    function endOf(address account) public view returns (uint256) {
        return _locks[account].end;
    }

    function maxEnd() public view returns (uint256) {
        return block.timestamp + MAX_TIME;
    }

    function createLock(uint256 amount, uint256 end) external {
        _createLock(amount, end, block.timestamp);
    }

    function _createLock(uint256 amount, uint256 end, uint256 timestamp) internal claimReward(true, true) {
        LockData storage lock = _locks[msg.sender];

        require(lock.amount == 0, "must no locked");
        require(end <= timestamp + MAX_TIME, "end too long");
        require(end > timestamp, "end too short");
        require(amount != 0, "amount must be non-zero");

        _smty.safeTransferFrom(msg.sender, address(this), amount);
        _totalLockedSMTY = _totalLockedSMTY + amount;

        lock.amount = amount;
        lock.end = end;

        _updateBalance(msg.sender, (end - timestamp).mul(amount).div(MAX_TIME));

        emit LockCreate(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function addAmount(uint256 amount) external {
        _addAmount(amount, block.timestamp);
    }

    function _addAmount(uint256 amount, uint256 timestamp) internal claimReward(true, true) {
        LockData storage lock = _locks[msg.sender];

        require(lock.amount != 0, "must locked");
        require(lock.end > timestamp, "must not expired");
        require(amount != 0, "_amount must be nonzero");

        _smty.safeTransferFrom(msg.sender, address(this), amount);
        _totalLockedSMTY = _totalLockedSMTY + amount;

        lock.amount = lock.amount.add(amount);
        _updateBalance(
            msg.sender,
            _balances[msg.sender].add((lock.end - timestamp).mul(amount).div(MAX_TIME))
        );

        emit LockIncreaseAmount(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function extendLock(uint256 end) external {
        _extendLock(end, block.timestamp);
    }

    function _extendLock(uint256 end, uint256 timestamp) internal claimReward(true, true) {
        LockData storage lock = _locks[msg.sender];
        require(lock.amount != 0, "must locked");
        require(lock.end < end, "new end must be longer");
        require(end <= timestamp + MAX_TIME, "end too long");

        // calculate equivalent lock duration
        uint256 duration = _balances[msg.sender].mul(MAX_TIME).div(lock.amount);
        duration += (end - lock.end);
        if (duration > MAX_TIME) {
            duration = MAX_TIME;
        }

        lock.end = end;
        _updateBalance(msg.sender, duration.mul(lock.amount).div(MAX_TIME));

        emit LockExtend(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function withdraw() external {
        _withdraw(block.timestamp);
    }

    function _withdraw(uint256 timestamp) internal claimReward(true, true) {
        LockData storage lock = _locks[msg.sender];

        require(lock.end <= timestamp, "must expired");

        uint256 amount = lock.amount;
        _smty.safeTransfer(msg.sender, amount);
        _totalLockedSMTY = _totalLockedSMTY - amount;

        lock.amount = 0;
        _updateBalance(msg.sender, 0);

        emit Withdraw(msg.sender, amount);
    }

    function setDistributePenaltyEarning(bool dist) external onlyOwner {
        _distributePenaltyEarning = dist;
    }

    /*
     * Add earning from other accounts, which will be locked for 3 months.
     * Early exit is allowed, by 50% will be penalty.
     */
    function addEarning(address user, uint256 amount) external {
        _addPendingEarning(user, amount);
        _smty.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _addPendingEarning(address user, uint256 amount) internal {
        Balances storage bal = _userBalances[user];
        bal.earned = bal.earned.add(amount);

        uint256 unlockTime = block.timestamp.div(REWARDS_DURATION).mul(REWARDS_DURATION).add(LOCK_DURATION);
        LockedBalance[] storage earnings = _userEarnings[user];
        uint256 idx = earnings.length;

        if (idx == 0 || earnings[idx-1].unlockTime < unlockTime) {
            earnings.push(LockedBalance({amount: amount, unlockTime: unlockTime}));
        } else {
            earnings[idx-1].amount = earnings[idx-1].amount.add(amount);
        }
        emit EarningAdd(user, amount);
    }

    // Withdraw staked tokens
    // First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
    // incurs a 50% penalty which will be burnt
    function withdrawEarning(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        Balances storage bal = _userBalances[msg.sender];
        uint256 penaltyAmount = 0;

        uint256 remaining = amount;
        bal.earned = bal.earned.sub(remaining);
        for (uint i = 0; ; i++) {
            uint256 earnedAmount = _userEarnings[msg.sender][i].amount;
            if (earnedAmount == 0) {
                continue;
            }
            if (penaltyAmount == 0 && _userEarnings[msg.sender][i].unlockTime > block.timestamp) {
                penaltyAmount = remaining;
                require(bal.earned >= remaining, "Insufficient balance after penalty");
                bal.earned = bal.earned.sub(remaining);
                if (bal.earned == 0) {
                    delete _userEarnings[msg.sender];
                    break;
                }
                remaining = remaining.mul(2);
            }
            if (remaining <= earnedAmount) {
                _userEarnings[msg.sender][i].amount = earnedAmount.sub(remaining);
                break;
            } else {
                delete _userEarnings[msg.sender][i];
                remaining = remaining.sub(earnedAmount);
            }
        }

        _smty.safeTransfer(msg.sender, amount);
        if (_distributePenaltyEarning && (_totalSupply != 0)) {
            _accPenaltyEarningPerBalance = _accPenaltyEarningPerBalance.add(penaltyAmount.mul(1e18).div(_totalSupply));
        }
        emit EarningWithdraw(msg.sender, amount, penaltyAmount);
    }

    // Final balance received and penalty balance paid by user upon calling exit
    function withdrawableEarning(
        address user
    )
        public
        view
        returns (uint256 amount, uint256 penaltyAmount)
    {
        Balances storage bal = _userBalances[user];
        if (bal.earned > 0) {
            uint256 amountWithoutPenalty;
            uint256 length = _userEarnings[user].length;
            for (uint i = 0; i < length; i++) {
                uint256 earnedAmount = _userEarnings[user][i].amount;
                if (earnedAmount == 0) {
                    continue;
                }
                if (_userEarnings[user][i].unlockTime > block.timestamp) {
                    break;
                }
                amountWithoutPenalty = amountWithoutPenalty.add(earnedAmount);
            }

            // add 1 wei in case for off by one issue
            penaltyAmount = bal.earned.sub(amountWithoutPenalty).div(2) + 1;
        }
        amount = bal.earned.sub(penaltyAmount);
        return (amount, penaltyAmount);
    }

    // solium-disable-next-line no-empty-blocks
    function claim() external claimReward(true, false) {
    }

    // solium-disable-next-line no-empty-blocks
    function vestEarning() external claimReward(false, true) {
    }

    function _updateBalance(address account, uint256 newBalance) internal {
        _totalSupply = _totalSupply.sub(_balances[account]).add(newBalance);
        _balances[account] = newBalance;
    }

    function collectReward() public {
        uint256 newReward = _syUSD.balanceOf(_collector);
        if (newReward == 0) {
            return;
        }

        _syUSD.safeTransferFrom(_collector, address(this), newReward);
        _accRewardPerBalance = _accRewardPerBalance.add(newReward.mul(1e18).div(_totalSupply));
    }

    function pendingReward() public view returns (uint256 pending) {
        if (_balances[msg.sender] > 0) {
            uint256 newReward = _syUSD.balanceOf(_collector);
            uint256 newAccRewardPerBalance = _accRewardPerBalance.add(newReward.mul(1e18).div(_totalSupply));
            pending = _balances[msg.sender].mul(newAccRewardPerBalance).div(1e18).sub(_rewardDebt[msg.sender]);
        }
    }

    function pendingEarning() public view returns (uint256 pending) {
        if (_balances[msg.sender] > 0) {
            pending = _balances[msg.sender].mul(_accPenaltyEarningPerBalance).div(1e18).sub(_userBalances[msg.sender].penaltyEarningDebt);
        }
    }

    modifier claimReward(bool claimFee, bool vestEarn) {
        uint256 veBal = _balances[msg.sender];
        if (veBal > 0) {
            if (claimFee) {
                collectReward();
                uint256 pending = veBal.mul(_accRewardPerBalance).div(1e18).sub(_rewardDebt[msg.sender]);
                _syUSD.safeTransfer(msg.sender, pending);
            }

            if (vestEarn) {
                uint256 pending = veBal.mul(_accPenaltyEarningPerBalance).div(1e18)
                    .sub(_userBalances[msg.sender].penaltyEarningDebt);

                if (pending != 0) {
                    _addPendingEarning(msg.sender, pending);
                }
            }
        }

        _; // _balances[msg.sender] may changed.

        if (!claimFee || !vestEarn) {
            require(veBal == _balances[msg.sender], "veSMTY balance changed");
        } else {
            veBal = _balances[msg.sender];
        }

        if (claimFee) {
            _rewardDebt[msg.sender] = veBal.mul(_accRewardPerBalance).div(1e18);
        }
        if (vestEarn) {
            _userBalances[msg.sender].penaltyEarningDebt = veBal.mul(_accPenaltyEarningPerBalance)
                .div(1e18);
        }
    }
}

// File: contracts/liquidity-mining/SmoothyMasterV1.sol



pragma solidity 0.6.12;










contract SmoothyMasterV1 is UpgradeableOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 workingAmount; // actual amount * ve boost * lockup bonus
        uint256 smtyRewardDebt; // Reward debt.
        uint256 lockEnd;
        uint256 lockDuration;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool.
        uint256 lastRewardTime;   // Last block timestamp that SMTYs distribution occurs.
        uint256 accSMTYPerShare;  // Accumulated SMTYs per share, times 1e18. See below.
        uint256 workingSupply;    // Total supply of working amount

        mapping (address => UserInfo) userInfo;
    }

    // The SMTY TOKEN!
    SMTYToken public smty;
    VotingEscrow public veSMTY;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The time when SMTY mining starts.
    uint256 public startTime;
    bool public mintSMTY;
    bool public veBoostEnabled;

    uint256 public constant MAX_TIME = 730 days; // 2 years
    uint256 public constant MAX_EXTRA_BOOST = 3e18; // 1x to 4x
    uint256 public constant SECONDS_PER_EPOCH = 365 days; // 1 year
    uint256 public constant GENESIS_REWARD_PER_SECOND = 6000000e18 / SECONDS_PER_EPOCH; // 6% + 6% for the first year

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event WorkingAmountUpdate(
        address indexed user,
        uint256 indexed pid,
        uint256 newWorkingAmount,
        uint256 newWorkingSupply
    );
    event LockCreate(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockEnd, uint256 lockDuration);
    event LockExtend(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockEnd, uint256 lockDuration);
    event LockAdd(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockEnd, uint256 lockDuration);
    event LockIncreaseAmount(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 lockEnd,
        uint256 lockDuration
    );

    // solium-disable-next-line
    constructor() public {
    }

    function initialize(
        SMTYToken _smty,
        VotingEscrow _veSMTY,
        uint256 _startTime,
        bool _mintSMTY
    )
        external
        onlyOwner
    {
        smty = _smty;
        veSMTY = _veSMTY;
        startTime = _startTime;
        mintSMTY = _mintSMTY;
        veBoostEnabled = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    )
        public
        onlyOwner
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accSMTYPerShare: 0,
            workingSupply: 0
        }));
    }

    // Update the given pool's SMTY allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    )
        public
        onlyOwner
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // enable veBoost
    function setVEBoostEnabled(bool _enabled) external onlyOwner {
        veBoostEnabled = _enabled;
    }

    // Return block rewards over the given _from (inclusive) to _to (inclusive) block.
    function getSmtyBlockReward(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 to = _to;
        uint256 from = _from;
        if (from < startTime) {
            from = startTime;
        }

        if (from > to) {
            return 0;
        }

        uint256 epochBegin = startTime;
        uint256 epochEnd = epochBegin + SECONDS_PER_EPOCH - 1;
        uint256 rewardPerBlock = GENESIS_REWARD_PER_SECOND;
        uint256 totalRewards = 0;
        while (to >= epochBegin) {
            uint256 left = Math.max(epochBegin, from);
            uint256 right = Math.min(epochEnd, to);
            if (right >= left) {
                totalRewards += (right - left + 1) * rewardPerBlock;
            }

            rewardPerBlock = rewardPerBlock * 3 / 4; // 75% of previous epoch
            epochBegin = epochEnd + 1;
            epochEnd = epochBegin + SECONDS_PER_EPOCH - 1;
        }
        return totalRewards;
    }

    // View function to see pending SMTYs on frontend.
    function pendingSMTY(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[_user];
        uint256 accSMTYPerShare = pool.accSMTYPerShare;
        uint256 workingSupply = pool.workingSupply;
        if (block.timestamp > pool.lastRewardTime && workingSupply != 0) {
            uint256 smtyReward = getSmtyBlockReward(pool.lastRewardTime + 1, block.timestamp).mul(
                pool.allocPoint).div(totalAllocPoint);
            accSMTYPerShare = accSMTYPerShare.add(smtyReward.mul(1e18).div(workingSupply));
        }
        return user.workingAmount.mul(accSMTYPerShare).div(1e18).sub(user.smtyRewardDebt);
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
        _updatePool(_pid, block.timestamp);
    }

    function _updatePool(uint256 _pid, uint256 _timestamp) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (_timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 workingSupply = pool.workingSupply;
        if (workingSupply == 0) {
            pool.lastRewardTime = _timestamp;
            return;
        }
        uint256 smtyReward = getSmtyBlockReward(pool.lastRewardTime + 1, _timestamp).mul(
            pool.allocPoint).div(totalAllocPoint);
        if (mintSMTY) {
            smty.mint(address(this), smtyReward);
        }
        pool.accSMTYPerShare = pool.accSMTYPerShare.add(smtyReward.mul(1e18).div(workingSupply));

        pool.lastRewardTime = _timestamp;
    }

    modifier claimSmty(uint256 _pid, address _account, uint256 _timestamp) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[_account];
        _updatePool(_pid, _timestamp);
        if (user.workingAmount > 0) {
            uint256 smtyPending = user.workingAmount.mul(pool.accSMTYPerShare).div(1e18).sub(user.smtyRewardDebt);

            IERC20(smty).safeApprove(address(veSMTY), smtyPending);
            veSMTY.addEarning(_account, smtyPending);
            emit Claim(_account, _pid, smtyPending);
        }

        _; // amount/boost may be changed

        _updateWorkingAmount(_pid, _account);
        user.smtyRewardDebt = user.workingAmount.mul(pool.accSMTYPerShare).div(1e18);
    }

    function _updateWorkingAmount(
        uint256 _pid,
        address _account
    ) internal
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[_account];

        uint256 lim = user.amount.mul(4) / 10;

        uint256 votingBalance = veSMTY.balanceOf(_account);
        uint256 totalBalance = veSMTY.totalSupply();

        if (totalBalance != 0 && veBoostEnabled) {
            uint256 lsupply = pool.lpToken.totalSupply();
            lim = lim.add(lsupply.mul(votingBalance).div(totalBalance).mul(6) / 10);
        }

        uint256 veAmount = Math.min(user.amount, lim);

        uint256 timelockBoost = user.lockDuration.mul(MAX_EXTRA_BOOST).div(MAX_TIME).add(1e18);
        uint256 newWorkingAmount = veAmount.mul(timelockBoost).div(1e18);

        pool.workingSupply = pool.workingSupply.sub(user.workingAmount).add(newWorkingAmount);
        user.workingAmount = newWorkingAmount;

        emit WorkingAmountUpdate(_account, _pid, user.workingAmount, pool.workingSupply);
    }

    /*
     * Deposit without lock.
     */
    function deposit(uint256 _pid, uint256 _amount) external claimSmty(_pid, msg.sender, block.timestamp) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        require(user.lockDuration == 0, "must be unlocked");

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    function createLock(uint256 _pid, uint256 _amount, uint256 _end) external {
        _createLock(_pid, _amount, _end, block.timestamp);
    }

    function _createLock(
        uint256 _pid,
        uint256 _amount,
        uint256 _end,
        uint256 _timestamp
    )
        internal
        claimSmty(_pid, msg.sender, _timestamp)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        require(user.lockDuration == 0, "must be unlocked");
        require(_end > _timestamp, "end too short");
        require(_end <= _timestamp + MAX_TIME, "end too long");

        if (_amount != 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.lockEnd = _end;
        user.lockDuration = _end.sub(_timestamp);

        emit LockCreate(msg.sender, _pid, user.amount, user.lockEnd, user.lockDuration);
    }

    function extendLock(uint256 _pid, uint256 _end) external {
        _extendLock(_pid, _end, block.timestamp);
    }

    function _extendLock(
        uint256 _pid,
        uint256 _end,
        uint256 _timestamp
    )
        internal
        claimSmty(_pid, msg.sender, _timestamp)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        require(user.lockDuration != 0, "must be locked");
        require(_end <= _timestamp + MAX_TIME, "end too long");
        require(_end > user.lockEnd, "new end must be greater");
        require(user.amount != 0, "user amount must be non-zero");

        user.lockDuration = Math.min(user.lockDuration.add(_end.sub(user.lockEnd)), MAX_TIME);
        user.lockEnd = _end;

        emit LockExtend(msg.sender, _pid, user.amount, user.lockEnd, user.lockDuration);
    }

    function increaseAmount(uint256 _pid, uint256 _amount) external {
        _increaseAmount(_pid, _amount, block.timestamp);
    }

    function _increaseAmount(
        uint256 _pid,
        uint256 _amount,
        uint256 _timestamp
    )
        internal
        claimSmty(_pid, msg.sender, _timestamp)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        require(user.lockDuration != 0, "must be locked");
        require(user.lockEnd > _timestamp, "must be non-expired");
        require(_amount != 0, "_amount must be nonzero");

        // Update duration according to new amount
        uint256 newAmount = user.amount.add(_amount);
        uint256 m0 = user.lockDuration.mul(user.amount);
        uint256 m1 = user.lockEnd.sub(_timestamp).mul(_amount);
        uint256 newDuration = m0.add(m1).div(newAmount);
        user.lockDuration = newDuration;
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = newAmount;

        emit LockIncreaseAmount(msg.sender, _pid, user.amount, user.lockEnd, user.lockDuration);
    }

    function withdraw(uint256 _pid) external {
        _withdraw(_pid, block.timestamp);
    }

    function _withdraw(uint256 _pid, uint256 _timestamp) internal claimSmty(_pid, msg.sender, _timestamp) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        require(user.lockEnd < _timestamp, "must be expired");

        uint256 amount = user.amount;
        user.amount = 0;
        user.lockDuration = 0; // mark it as unlocked

        pool.lpToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, _pid, amount);
    }

    // solium-disable-next-line
    function claim(uint256 _pid, address _account) public claimSmty(_pid, _account, block.timestamp) {
    }

    // Safe smty transfer function, just in case if rounding error causes pool to not have enough SMTYs.
    function safeSMTYTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 smtyBal = smty.balanceOf(address(this));
            if (_amount > smtyBal) {
                smty.transfer(_to, smtyBal);
            } else {
                smty.transfer(_to, _amount);
            }
        }
    }

    function getUserInfo(uint256 _pid) public view returns(uint, uint, uint, uint, uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = pool.userInfo[msg.sender];

        return (user.amount, user.workingAmount, user.smtyRewardDebt, user.lockEnd, user.lockDuration);
    }
}