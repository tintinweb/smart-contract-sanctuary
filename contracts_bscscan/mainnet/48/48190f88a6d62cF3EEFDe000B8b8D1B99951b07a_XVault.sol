/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Address.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/SafeERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/ERC20.sol



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

// File: contracts/xVault.sol


pragma solidity 0.6.12;






// interface GuestList {
//   function authorized(address guest, uint256 amount) public returns (bool);
// }

interface Strategy {
  function want() external view returns (address);
  function vault() external view returns (address);
  function estimatedTotalAssets() external view returns (uint256);
  function withdraw(uint256 _amount) external returns (uint256, uint256);
  function migrate(address _newStrategy) external;
}

interface ITreasury {
  function depositToken(address token) external payable;
}


contract XVault is ERC20, ReentrancyGuard {
  using SafeERC20 for ERC20;
  using Address for address;
  using SafeMath for uint256;
  
  address public guardian;
  address public governance;
  address public management;
  ERC20 public immutable token;

  // GuestList guestList;

  struct StrategyParams {
    uint256 performanceFee;     // strategist's fee
    uint256 activation;         // block.timstamp of activation of strategy
    uint256 debtRatio;          // percentage of maximum token amount of total assets that strategy can borrow from the vault
    uint256 rateLimit;          // limit rate per unit time, it controls the amount of token strategy can borrow last harvest
    uint256 lastReport;         // block.timestamp of the last time a report occured
    uint256 totalDebt;          // total outstanding debt that strategy has
    uint256 totalGain;          // Total returns that Strategy has realized for Vault
    uint256 totalLoss;          // Total losses that Strategy has realized for Vault
  }

  uint256 public MAX_BPS = 10000;
  uint256 public SECS_PER_YEAR = 60 * 60 * 24 * 36525 / 100;

  mapping (address => StrategyParams) public strategies;
  uint256 constant MAXIMUM_STRATEGIES = 20;
  address[] public withdrawalQueue;

  bool public emergencyShutdown;
  uint256 private apy = 0;
  
  uint256 private tokenBalance; // token.balanceOf(address(this))
  uint256 public depositLimit;  // Limit of totalAssets the vault can hold
  uint256 public debtRatio;
  uint256 public totalDebt;   // Amount of tokens that all strategies have borrowed
  uint256 public lastReport;  // block.timestamp of last report
  uint256 public immutable activation;  // block.timestamp of contract deployment
  uint256 private lastValuePerShare = 1000000000;

  ITreasury public treasury;    // reward contract where governance fees are sent to
  uint256 public managementFee;
  uint256 public performanceFee;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event UpdateTreasury(ITreasury treasury);
  event UpdateGuardian(address guardian);
  event UpdateManagement(address management);
  event UpdateGuestList(address guestList);
  event UpdateDepositLimit(uint256 depositLimit);
  event UpdatePerformanceFee(uint256 fee);
  event StrategyRemovedFromQueue(address strategy);
  event UpdateManangementFee(uint256 fee);
  event EmergencyShutdown(bool active);
  event UpdateWithdrawalQueue(address[] queue);
  event StrategyAddedToQueue(address strategy);
  event StrategyReported(
    address indexed strategy,
    uint256 gain,
    uint256 loss,
    uint256 totalGain,
    uint256 totalLoss,
    uint256 totalDebt,
    uint256 debtAdded,
    uint256 debtRatio
  );
  event StrategyAdded(
    address indexed strategy,
    uint256 debtRatio,
    uint256 rateLimit,
    uint256 performanceFee
  );
  event StrategyUpdateDebtRatio(
    address indexed strategy, 
    uint256 debtRatio
  );
  event StrategyUpdateRateLimit(
    address indexed strategy,
    uint256 rateLimit
  );
  event StrategyUpdatePerformanceFee(
    address indexed strategy,
    uint256 performanceFee
  );
  event StrategyRevoked(
    address indexed strategy
  );
  event StrategyMigrated(
    address oldStrategy,
    address newStrategy
  );

  constructor(
    address _token,
    address _governance,
    ITreasury _treasury
  ) 
  public ERC20(
    string(abi.encodePacked("Xend ", ERC20(_token).name())),
    string(abi.encodePacked("xv", ERC20(_token).symbol()))
  ){

    token = ERC20(_token);
    guardian = msg.sender;
    governance = _governance;
    management = _governance;
    treasury = _treasury;

    performanceFee = 1000;        // 10% of yield
    managementFee = 200;          // 2% per year
    lastReport = block.timestamp;
    activation = block.timestamp;

    _setupDecimals(ERC20(_token).decimals());
  }

  // function setName(string memory _name) external {
  //   require(msg.sender == governance, "!governance");
  //   name = _name;
  // }

  // function setSymbol(string memory _symbol) external {
  //   require(msg.sender == governance, "!governance");
  //   symbol = _symbol;
  // }

  function setTreasury(ITreasury _treasury) external {
    require(msg.sender == governance, "!governance");
    treasury = _treasury;
    emit UpdateTreasury(_treasury);
  }

  function setGuardian(address _guardian) external {
    require(msg.sender == governance || msg.sender == guardian, "caller must be governance or guardian");
    guardian = _guardian;
    emit UpdateGuardian(_guardian);
  }

  function balance() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setManagement(address _management) external {
    require(msg.sender == governance, "!governance");
    management = _management;
    emit UpdateManagement(_management);
  }

  // function setGuestList(address _guestList) external {
  //   require(msg.sender == governance, "!governance");
  //   guestList = GuestList(_guestList);
  //   emit UpdateGuestList(guestList);
  // }

  function setDepositLimit(uint256 limit) external {
    require(msg.sender == governance, "!governance");
    depositLimit = limit;
    emit UpdateDepositLimit(depositLimit);
  }
  

  function setPerformanceFee(uint256 fee) external {
    require(msg.sender == governance, "!governance");
    require(fee <= MAX_BPS - performanceFee, "performance fee should be smaller than ...");
    performanceFee = fee;
    emit UpdatePerformanceFee(fee);
  }

  function setManagementFee(uint256 fee) external {
    require(msg.sender == governance, "!governance");
    require(fee < MAX_BPS, "management fee should be smaller than ...");
    managementFee = fee;
    emit UpdateManangementFee(fee);
  }

  function setEmergencyShutdown(bool active) external {
    /***
      Activates or deactivates vault

      During Emergency Shutdown, 
      1. User can't deposit into the vault but can withdraw
      2. can't add new strategy
      3. only governance can undo Emergency Shutdown
    */
    require(active != emergencyShutdown, "already active/inactive status");
    
    require(msg.sender == governance || (active && msg.sender == guardian), "caller must be guardian or governance");

    emergencyShutdown = active;
    emit EmergencyShutdown(active);
  }

  /**
   *  @notice
   *    Update the withdrawalQueue.
   *    This may only be called by governance or management.
   *  @param queue The array of addresses to use as the new withdrawal queue. This is order sensitive.
   */
  function setWithdrawalQueue(address[] memory queue) external {
    require(msg.sender == management || msg.sender == governance);
    for (uint i = 0; i < queue.length; i++) {
      assert(strategies[queue[i]].activation > 0);
    }
    withdrawalQueue = queue;
    emit UpdateWithdrawalQueue(queue);
  }

  function getApy() external view returns (uint256) {
    return apy;
  }


  /**
   * Issues `amount` Vault shares to `to`.
   */
  function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256) {
    uint256 shares = 0;
    if (totalSupply() > 0) {
      shares = amount.mul(totalSupply()).div(_totalAssets());
    } else {
      shares = amount;
    }

    _mint(to, shares);

    return shares;
  }

  /**
   * Deposit `_amount` issuing shares to `msg.sender`.
   * If the vault is in emergency shutdown, deposits will not be accepted and this call will fail.
   */
  function deposit(uint256 _amount) public nonReentrant returns (uint256) {
    require(emergencyShutdown != true, "in status of Emergency Shutdown");
    uint256 amount = _amount;
    if (amount == 0) {
      amount = _min(depositLimit.sub(_totalAssets()), token.balanceOf(msg.sender));
    }
    
    require(amount > 0, "deposit amount should be bigger than zero");

    uint256 shares = _issueSharesForAmount(msg.sender, amount);

    token.safeTransferFrom(msg.sender, address(this), amount);
    tokenBalance = tokenBalance.add(amount);
    emit Deposit(msg.sender, amount);

    return shares;
  }

  /**
   * Return the total quantity of assets
   * i.e. current balance of assets + total assets that strategies borrowed from the vault 
   */
  function _totalAssets() internal view returns (uint256) {
    return tokenBalance.add(totalDebt);
  }

  function totalAssets() external view returns (uint256) {
    return _totalAssets();
  }

  function _shareValue(uint256 _share) internal view returns (uint256) {
    // Determine the current value of `shares`
    return _share.mul(_totalAssets()).div(totalSupply());
  }

  function _sharesForAmount(uint256 amount) internal view returns (uint256) {
    // Determine how many shares `amount` of token would receive
    if (_totalAssets() > 0) {
      return amount.mul(totalSupply()).div(_totalAssets());
    } else {
      return 0;
    }
  }

  /**
   * @notice
   *    Determines the total quantity of shares this Vault can provide,
   *    factoring in assets currently residing in the Vault, as well as those deployed to strategies.
   * @dev
   *    If you want to calculate the maximum a user could withdraw up to, need to use this function
   * @return The total quantity of shares this Vault can provide
   */
  function maxAvailableShares() external view returns (uint256) {
    uint256 _shares = _sharesForAmount(token.balanceOf(address(this)));

    for (uint i = 0; i < withdrawalQueue.length; i++) {
      if (withdrawalQueue[i] == address(0)) break;
      _shares = _shares.add(_sharesForAmount(strategies[withdrawalQueue[i]].totalDebt));
    }

    return _shares;
  }

  /**
   * Withdraw the `msg.sender`'s tokens from the vault, redeeming amount `_shares`
   * for an appropriate number of tokens.
   * @param maxShare How many shares to try and redeem for tokens, defaults to all.
   * @param recipient The address to issue the shares in this Vault to, defaults to the caller's address
   * @param maxLoss The maximum acceptble loss to sustain on withdrawal, defaults to 0%.
   * @return The quantity of tokens redeemed for `_shares`.
   */
  function withdraw(
    uint256 maxShare,
    address recipient,
    uint256 maxLoss     // if 1, 0.01%
  ) public nonReentrant returns (uint256) {
    uint256 shares = maxShare;
    if (maxShare == 0) {
      shares = balanceOf(msg.sender);
    }
    if (recipient == address(0)) {
      recipient = msg.sender;
    }

    require(shares <= balanceOf(msg.sender), "share should be smaller than their own");
    
    uint256 value = _shareValue(shares);
    if (value > token.balanceOf(address(this))) {
      
      uint256 totalLoss = 0;
      
      for(uint i = 0; i < withdrawalQueue.length; i++) {
        address strategy = withdrawalQueue[i];
        if (strategy == address(0)) {
          break;
        }
        if (value <= token.balanceOf(address(this))) {
          break;
        }

        uint256 amountNeeded = value.sub(token.balanceOf(address(this)));    // recalculate the needed token amount to withdraw
        amountNeeded = _min(amountNeeded, strategies[strategy].totalDebt);
        if (amountNeeded == 0)
          continue;
        
        (uint256 withdrawn, uint256 loss) = Strategy(strategy).withdraw(amountNeeded);
        tokenBalance = tokenBalance.add(withdrawn);

        if (loss > 0) {
          value = value.sub(loss);
          totalLoss = totalLoss.add(loss);
          strategies[strategy].totalLoss = strategies[strategy].totalLoss.add(loss);
        }
        strategies[strategy].totalDebt = strategies[strategy].totalDebt.sub(withdrawn.add(loss));
        totalDebt = totalDebt.sub(withdrawn.add(loss));
      }

      require(totalLoss <= maxLoss.mul(value.add(totalLoss)).div(MAX_BPS), "revert if totalLoss is more than permitted");
    }

    if (value > token.balanceOf(address(this))) {
      value = token.balanceOf(address(this));
      shares = _sharesForAmount(value);
    }
    
    _burn(msg.sender, shares);
    
    token.safeTransfer(recipient, value);
    tokenBalance = tokenBalance.sub(value);
    emit Withdraw(recipient, value);
    
    return value;
  }

  /**
   * @notice
   *    Add a Strategy to the Vault.
   *    This may only be called by governance.
   * @param _strategy The address of Strategy to add
   * @param _debtRatio The ratio of total assets in the Vault that strategy can manage
   * @param _rateLimit Limit on the increase of debt per unit time since last harvest
   * @param _performanceFee The fee the strategist will receive based on this Vault's performance.
   */
  function addStrategy(address _strategy, uint256 _debtRatio, uint256 _rateLimit, uint256 _performanceFee) public {
    require(_strategy != address(0), "strategy address can't be zero");
    assert(!emergencyShutdown);
    require(msg.sender == governance, "caller must be governance");
    require(_performanceFee <= MAX_BPS - performanceFee, "performance fee should be smaller than ...");
    assert(debtRatio.add(_debtRatio) <= MAX_BPS);
    assert(strategies[_strategy].activation == 0);
    assert(Strategy(_strategy).vault() == address(this));
    assert(Strategy(_strategy).want() == address(token));

    strategies[_strategy] = StrategyParams({
      performanceFee: _performanceFee,
      activation: block.timestamp,
      debtRatio: _debtRatio,
      rateLimit: _rateLimit,
      lastReport: block.timestamp,
      totalDebt: 0,
      totalGain: 0,
      totalLoss: 0
    });

    debtRatio = debtRatio.add(_debtRatio);
    
    emit StrategyAdded(_strategy, _debtRatio, _rateLimit, _performanceFee);

    withdrawalQueue.push(_strategy);

  }

  /**
   * @notice
   *    Change the quantity of assets `strategy` may manage.
   *    This may be called by governance or management
   * @param _strategy The strategy to update
   * @param _debtRatio The quantity of assets `strategy` may now manage
   */
  function updateStrategyDebtRatio(address _strategy, uint256 _debtRatio) external {
    assert(msg.sender == management || msg.sender == governance);
    assert(strategies[_strategy].activation > 0);
    debtRatio = debtRatio.sub(strategies[_strategy].debtRatio);
    strategies[_strategy].debtRatio = _debtRatio;
    debtRatio = debtRatio.add(_debtRatio);
    assert(debtRatio <= MAX_BPS);
    emit StrategyUpdateDebtRatio(_strategy, _debtRatio);
  }

  /**
   * @notice
   *    Change the quantity of assets per block this Vault may deposit to or withdraw from `strategy`.
   *    This may only be called by governance or management.
   * @param _strategy The strategy to update
   * @param _rateLimit Limit on the increase of debt per unit time since the last harvest
   */
  function updateStrategyRateLimit(address _strategy, uint256 _rateLimit) external {
    assert(msg.sender == management || msg.sender == governance);
    assert(strategies[_strategy].activation > 0);
    strategies[_strategy].rateLimit = _rateLimit;
    emit StrategyUpdateRateLimit(_strategy, _rateLimit);
  }

  /**
   * @notice 
   *    Change the fee the strategist will receive based on this Vault's performance
   *    This may only be called by goverance.
   * @param _strategy The strategy to update
   * @param _performanceFee The new fee the strategist will receive
   */
  function updateStrategyPerformanceFee(address _strategy, uint256 _performanceFee) external {
    assert(msg.sender == governance);
    assert(performanceFee <= MAX_BPS - performanceFee);
    assert(strategies[_strategy].activation > 0);
    strategies[_strategy].performanceFee = _performanceFee;
    emit StrategyUpdatePerformanceFee(_strategy, _performanceFee);
  }

  /**
   *  @notice
   *    Add `strategy` to `withdrawalQueue`.
   *    This may only be called by governance or management.
   *  @dev
   *    The Strategy will be appended to `withdrawalQueue`, call `setWithdrawalQueue` to change the order.
   *  @param _strategy The Strategy to add.
   */
  function addStrategyToQueue(address _strategy) external {
    assert(msg.sender == management || msg.sender == governance);
    assert(strategies[_strategy].activation > 0);
    assert(withdrawalQueue.length < MAXIMUM_STRATEGIES);
    for (uint i = 0; i < withdrawalQueue.length; i++) {
      assert(withdrawalQueue[i] != _strategy);
    }
    withdrawalQueue.push(_strategy);
    emit StrategyAddedToQueue(_strategy);
  }

  /**
   * @notice
   *    Remove `strategy` from `withdrawalQueue`
   *    This may only be called by governance or management.
   * @param _strategy The Strategy to remove
   */
  function removeStrategyFromQueue(address _strategy) external {
    require(msg.sender == management || msg.sender == governance);
    
    for (uint i = 0; i < withdrawalQueue.length; i++) {
      
      if (withdrawalQueue[i] == _strategy) {
        withdrawalQueue[i] = withdrawalQueue[withdrawalQueue.length - 1];
        withdrawalQueue.pop();
        emit StrategyRemovedFromQueue(_strategy);
      }
    
    }
  }

  /**
   * @notice
   *    Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits.
   *    This may only be called by governance, the guardian, or the Strategy itself.
   * @param _strategy The strategy to revoke
   */
  function revokeStrategy(address _strategy) public {
    require(msg.sender == _strategy || msg.sender == governance || msg.sender == guardian, "should be one of 3 admins");
    _revokeStrategy(_strategy);
  }

  function _revokeStrategy(address _strategy) internal {
    assert(strategies[_strategy].debtRatio > 0);
    debtRatio = debtRatio.sub(strategies[_strategy].debtRatio);
    strategies[_strategy].debtRatio = 0;
    emit StrategyRevoked(_strategy);
  }

  /**
   *  @notice
   *    Migrate a Strategy, including all assets from `oldVersion` to `newVersion`.
   *    This may only be called by governance.
   *  @param oldVersion The existing Strategy to migrate from.
   *  @param newVersion The new Strategy to migrate to.
   */
  function migrateStrategy(address oldVersion, address newVersion) external {
    assert(msg.sender == governance);
    assert(newVersion != address(0));
    assert(strategies[oldVersion].activation > 0);
    assert(strategies[newVersion].activation == 0);

    StrategyParams memory strategy = strategies[oldVersion];
    _revokeStrategy(oldVersion);
    debtRatio = debtRatio.add(strategy.debtRatio);
    strategies[oldVersion].totalDebt = 0;

    strategies[newVersion] = StrategyParams({
      performanceFee: strategy.performanceFee,
      activation: block.timestamp,
      debtRatio: strategy.debtRatio,
      rateLimit: strategy.rateLimit,
      lastReport: block.timestamp,
      totalDebt: strategy.totalDebt,
      totalGain: 0,
      totalLoss: 0
    });

    Strategy(oldVersion).migrate(newVersion);
    emit StrategyMigrated(oldVersion, newVersion);

    for (uint i = 0; i < withdrawalQueue.length; i++) {
      if (withdrawalQueue[i] == oldVersion) {
        withdrawalQueue[i] = newVersion;
        return;
      }
    }
  }

  /**
   * @notice
   *    Provide an accurate expected value for the return this `strategy`
   * @param _strategy The Strategy to determine the expected return for. Defaults to caller.
   * @return
   *    The anticipated amount `strategy` should make on its investment since its last report.
   */
  function expectedReturn(address _strategy) external view returns (uint256) {
    _expectedReturn(_strategy);
  }

  function _expectedReturn(address _strategy) internal view returns (uint256) {
    uint256 delta = block.timestamp - strategies[_strategy].lastReport;
    if (delta > 0) {
      return strategies[_strategy].totalGain.mul(delta).div(block.timestamp - strategies[_strategy].activation);
    } else {
      return 0;
    }
  }

  function availableDepositLimit() external view returns (uint256) {
    if (depositLimit > _totalAssets()) {
      return depositLimit.sub(_totalAssets());
    } else {
      return 0;
    }
  }

  /**
   * @notice Gives the price for a single Vault share.
   * @return The value of a single share.
   */
  function pricePerShare() external view returns (uint256) {
    if (totalSupply() == 0) {
      // return 10 ** decimals();      // price of 1:1
      return _totalAssets() > (uint256(10) ** decimals()) ? _totalAssets() : uint256(10) ** decimals();
    } else {
      return _shareValue(uint256(10) ** decimals());
    }
  }

  /**
   * @notice
   *    Determines if `strategy` is past its debt limit and if any tokens
   *    should be withdrawn to the Vault.
   * @param _strategy The Strategy to check. Defaults to the caller.
   * @return The quantity of tokens to withdraw.
   */
  function debtOutstanding(address _strategy) external view returns (uint256) {
    return _debtOutstanding(_strategy);
  }

  /**
   * Returns assets amount of strategy that is past its debt limit
   */
  function _debtOutstanding(address _strategy) internal view returns (uint256) {
    uint256 strategy_debtLimit = strategies[_strategy].debtRatio.mul(_totalAssets()).div(MAX_BPS);
    uint256 strategy_totalDebt = strategies[_strategy].totalDebt;

    if (emergencyShutdown) {      // if emergency status, return current debt
      return strategy_totalDebt;
    } else if (strategy_totalDebt <= strategy_debtLimit) {
      return 0;
    } else {
      return strategy_totalDebt.sub(strategy_debtLimit);
    }
  }

  function _assessFees(address _strategy, uint256 gain) internal {
    // issue new shares to cover fees
    // as a result, it reduces share token price by fee amount

    uint256 governance_fee = _totalAssets().mul(block.timestamp.sub(lastReport)).mul(managementFee).div(MAX_BPS).div(SECS_PER_YEAR);
    uint256 strategist_fee = 0;

    if (gain > 0) {     // apply strategy fee only if there's profit. if loss or no profit, it didn't get applied
      strategist_fee = gain.mul(strategies[_strategy].performanceFee).div(MAX_BPS);
      governance_fee = governance_fee.add(gain.mul(performanceFee).div(MAX_BPS));
    }

    uint256 totalFee = governance_fee + strategist_fee;
    if (totalFee > 0) {
      uint256 reward = _issueSharesForAmount(address(this), totalFee);
      
      if (strategist_fee > 0) {
        uint256 strategist_reward = strategist_fee.mul(reward).div(totalFee);
        _transfer(address(this), _strategy, strategist_reward);
      }
      if (balanceOf(address(this)) > 0) {
        _approve(address(this), address(treasury), balanceOf(address(this)));
        treasury.depositToken(address(this));
      }
    }
  }

  function _reportLoss(address _strategy, uint256 loss) internal {
    uint256 _totalDebt = strategies[_strategy].totalDebt;
    require(_totalDebt >= loss, "loss can't be bigger than deposited debt");

    strategies[_strategy].totalLoss = strategies[_strategy].totalLoss.add(loss);
    strategies[_strategy].totalDebt = _totalDebt.sub(loss);

    uint256 _debtRatio = strategies[_strategy].debtRatio;
    strategies[_strategy].debtRatio = _debtRatio.sub(_min(loss.mul(MAX_BPS).div(_totalAssets()), _debtRatio));     // reduce debtRatio if loss happens

    totalDebt = totalDebt.sub(loss);
  }

  /**
   * @notice
   *    Amount of tokens in Vault a Strategy has access to as a credit line.
   *    This will check the Strategy's debt limit, as well as the tokens
   *    available in the Vault, and determine the maximum amount of tokens
   *    (if any) the Strategy may draw on.
   * @param _strategy The Strategy to check. Defaults to caller.
   * @return The quantity of tokens available for the Strategy to draw on.
   */
  function creditAvailable(address _strategy) external view returns (uint256) {
    return _creditAvailable(_strategy);
  }

  function _creditAvailable(address _strategy) internal view returns (uint256) {
    if (emergencyShutdown) {
      return 0;
    }

    uint256 vault_totalAssets = _totalAssets();
    uint256 vault_debtLimit = debtRatio.mul(vault_totalAssets).div(MAX_BPS);
    uint256 vault_totalDebt = totalDebt;

    uint256 strategy_debtLimit = strategies[_strategy].debtRatio.mul(vault_totalAssets).div(MAX_BPS);
    uint256 strategy_totalDebt = strategies[_strategy].totalDebt;
    uint256 strategy_rateLimit = strategies[_strategy].rateLimit;
    uint256 strategy_lastReport = strategies[_strategy].lastReport;

    if (strategy_debtLimit <= strategy_totalDebt || vault_debtLimit <= vault_totalDebt) {
      return 0;
    }

    uint256 _available = strategy_debtLimit.sub(strategy_totalDebt);
    _available = _min(_available, vault_debtLimit.sub(vault_totalDebt));

    // if available token amount is bigger than the limit per report period, adjust it.
    uint256 delta = block.timestamp.sub(strategy_lastReport);      // time difference between current time and last report(i.e. harvest)
    if (strategy_rateLimit > 0 && _available >= strategy_rateLimit.mul(delta)) {
      _available = strategy_rateLimit.mul(delta);
    }

    return _min(_available, token.balanceOf(address(this)));
  }

  /**
   * @notice
   *    Reports the amount of assets the calling Strategy has free
   *    The performance fee, strategist's fee are determined here
   *    Returns outstanding debt
   * @param gain Amount Strategy has realized as a gain on it's investment since its
   *    last report, and is free to be given back to Vault as earnings
   * @param loss Amount Strategy has realized as a loss on it's investment since its
   *    last report, and should be accounted for on the Vault's balance sheet
   * @param _debtPayment Amount Strategy has made available to cover outstanding debt
   * @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
   */
  function report(uint256 gain, uint256 loss, uint256 _debtPayment) external returns (uint256) {
    require(strategies[msg.sender].activation > 0, "strategy should be active");
    require(token.balanceOf(msg.sender) >= gain.add(_debtPayment), "insufficient token balance of strategy");

    if (loss > 0) {
      _reportLoss(msg.sender, loss);
    }

    _assessFees(msg.sender, gain);

    strategies[msg.sender].totalGain = strategies[msg.sender].totalGain.add(gain);

    uint256 debt = _debtOutstanding(msg.sender);
    uint256 debtPayment = _min(_debtPayment, debt);

    if (debtPayment > 0) {
      strategies[msg.sender].totalDebt = strategies[msg.sender].totalDebt.sub(debtPayment);
      totalDebt = totalDebt.sub(debtPayment);
      debt = debt.sub(debtPayment);
    }

    // get the available tokens to borrow from the vault
    uint256 credit = _creditAvailable(msg.sender);

    if (credit > 0) {
      strategies[msg.sender].totalDebt = strategies[msg.sender].totalDebt.add(credit);
      totalDebt = totalDebt.add(credit);
    }

    uint256 totalAvailable = gain.add(debtPayment);
    if (totalAvailable < credit) {
      token.transfer(msg.sender, credit.sub(totalAvailable));
      tokenBalance = tokenBalance.sub(credit.sub(totalAvailable));
    } else if (totalAvailable > credit) {
      token.transferFrom(msg.sender, address(this), totalAvailable.sub(credit));
      tokenBalance = tokenBalance.add(totalAvailable.sub(credit));
    }
    // else (if totalAvailable == credit), it is already balanced so do nothing.

    // Update APY
    if (totalSupply() == 0) {
      apy = 0;
    } else {
      uint256 valuePerShare = _totalAssets().mul(1000000000).div(totalSupply());
      if (valuePerShare > lastValuePerShare) {
        apy = valuePerShare.sub(lastValuePerShare).mul(365 days).div(block.timestamp.sub(lastReport)).mul(1000).div(lastValuePerShare);
      } else {
        apy = 0;
      }
      lastValuePerShare = valuePerShare;
    }
    

    // Update reporting time
    strategies[msg.sender].lastReport = block.timestamp;
    lastReport = block.timestamp;

    emit StrategyReported(
      msg.sender,
      gain,
      loss,
      strategies[msg.sender].totalGain,
      strategies[msg.sender].totalLoss,
      strategies[msg.sender].totalDebt,
      credit,
      strategies[msg.sender].debtRatio
    );

    if (strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
      // this block is used for getting penny
      // if Strategy is rovoked or exited for emergency, it could have some token that wan't withdrawn
      // this is different from debt
      return Strategy(msg.sender).estimatedTotalAssets();
    } else {
      return debt;
    }

  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}