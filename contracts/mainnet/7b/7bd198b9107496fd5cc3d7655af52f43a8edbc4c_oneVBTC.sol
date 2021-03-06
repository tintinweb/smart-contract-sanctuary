/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
    function totalSupply() public view override virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override virtual returns (uint256) {
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


pragma solidity >=0.6.0;

// interface for the oneToken
interface OneToken {
    function getOneTokenUsd() external view returns (uint256);
}

// interface for CollateralOracle
interface IOracleInterface {
    function getLatestPrice() external view returns (uint256);
    function update() external;
    function changeInterval(uint256 seconds_) external;
    function priceChangeMax(uint256 change_) external;
}

/// @title An overcollateralized stablecoin using vBTC
/// @author Masanobu Fukuoka
contract oneVBTC is ERC20("oneVBTC", "oneVBTC"), Ownable, ReentrancyGuard {
   using SafeMath for uint256;

    uint256 public MAX_RESERVE_RATIO; // At 100% reserve ratio, each oneVBTC is backed 1-to-1 by $1 of existing stable coins
    uint256 private constant DECIMALS = 9;
    uint256 public lastRefreshReserve; // The last time the reserve ratio was updated by the contract
    uint256 public minimumRefreshTime; // The time between reserve ratio refreshes

    address public stimulus; // oneVBTC builds a stimulus fund in vBTC.
    uint256 public stimulusDecimals; // used to calculate oracle rate of Uniswap Pair

    address public oneTokenOracle; // oracle for the oneVBTC stable coin
    bool public oneTokenOracleHasUpdate; //if oneVBTC token oracle requires update
    address public stimulusOracle;  // oracle for a stimulus 
    bool public stimulusOracleHasUpdate; //if stimulus oracle requires update

    // Only governance should cause the coin to go fully agorithmic by changing the minimum reserve
    // ratio.  For now, we will set a conservative minimum reserve ratio.
    uint256 public MIN_RESERVE_RATIO;
    uint256 public MIN_DELAY;

    // Makes sure that you can't send coins to a 0 address and prevents coins from being sent to the
    // contract address. I want to protect your funds!
    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _oneBalances;
    mapping(address => uint256) private _lastCall;  // used as a record to prevent flash loan attacks
    mapping (address => mapping (address => uint256)) private _allowedOne; // allowance to spend one

    address public gov; // who has admin rights over certain functions
    address public pendingGov;  // allows you to transfer the governance to a different user - they must accept it!
    uint256 public reserveStepSize; // step size of update of reserve rate (e.g. 5 * 10 ** 8 = 0.5%)
    uint256 public reserveRatio;    // a number between 0 and 100 * 10 ** 9.
                                    // 0 = 0%
                                    // 100 * 10 ** 9 = 100%

    // map of acceptable collaterals
    mapping (address => bool) public acceptedCollateral;
    mapping (address => uint256) public collateralMintFee; // minting fee for different collaterals (100 * 10 ** 9 = 100% fee)
    address[] public collateralArray; // array of collateral - used to iterate while updating certain things like oracle intervals for TWAP

    // modifier to allow auto update of TWAP oracle prices
    // also updates reserves rate programatically
    modifier updateProtocol() {
        if (address(oneTokenOracle) != address(0)) {

            // this is always updated because we always need stablecoin oracle price
            if (oneTokenOracleHasUpdate) IOracleInterface(oneTokenOracle).update();

            if (stimulusOracleHasUpdate) IOracleInterface(stimulusOracle).update();

            for (uint i = 0; i < collateralArray.length; i++){
                if (acceptedCollateral[collateralArray[i]] && !oneCoinCollateralOracle[collateralArray[i]]) IOracleInterface(collateralOracle[collateralArray[i]]).update();
            }

            // update reserve ratio if enough time has passed
            if (block.timestamp - lastRefreshReserve >= minimumRefreshTime) {
                // $Z / 1 one token
                if (getOneTokenUsd() > 1 * 10 ** 9) {
                    setReserveRatio(reserveRatio.sub(reserveStepSize));
                } else {
                    setReserveRatio(reserveRatio.add(reserveStepSize));
                }

                lastRefreshReserve = block.timestamp;
            }
        }

        _;
    }

    // events for off-chain record keeping
    event NewPendingGov(address oldPendingGov, address newPendingGov);
    event NewGov(address oldGov, address newGov);
    event NewReserveRate(uint256 reserveRatio);
    event Mint(address stimulus, address receiver, address collateral, uint256 collateralAmount, uint256 stimulusAmount, uint256 oneAmount);
    event Withdraw(address stimulus, address receiver, address collateral, uint256 collateralAmount, uint256 stimulusAmount, uint256 oneAmount);
    event NewMinimumRefreshTime(uint256 minimumRefreshTime);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data);

    modifier onlyIchiGov() {
        require(msg.sender == gov, "ACCESS: only Ichi governance");
        _;
    }

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));  // shortcut for calling transfer
    mapping (address => uint256) public collateralDecimals;     // needed to be able to convert from different collaterals
    mapping (address => bool) public oneCoinCollateralOracle;   // if true, we query the one token contract's usd price
    mapping (address => bool) public previouslySeenCollateral;  // used to allow users to withdraw collateral, even if the collateral has since been deprecated
                                                                // previouslySeenCollateral lets the contract know if a collateral has been used before - this also
                                                                // prevents attacks where uses add a custom address as collateral, but that custom address is actually 
                                                                // their own malicious smart contract. Read peckshield blog for more info.
    mapping (address => address) public collateralOracle;       // address of the Collateral-ETH Uniswap Price
    mapping (address => bool) public collateralOracleHasUpdate; // if collatoral oracle requires an update

    // default to 0
    uint256 public mintFee;
    uint256 public withdrawFee;

    // fee to charge when minting oneVBTC - this will go into collateral
    event MintFee(uint256 fee_);
    // fee to charge when redeeming oneVBTC - this will go into collateral
    event WithdrawFee(uint256 fee_);

    // set governance access to only oneVBTC - USDC pool multisig (elected after rewards)
    modifier oneLPGov() {
        require(msg.sender == lpGov, "ACCESS: only oneLP governance");
        _;
    }

    address public lpGov;
    address public pendingLPGov;

    event NewPendingLPGov(address oldPendingLPGov, address newPendingLPGov);
    event NewLPGov(address oldLPGov, address newLPGov);
    event NewMintFee(address collateral, uint256 oldFee, uint256 newFee);

    mapping (address => uint256) private _burnedStablecoin; // maps user to burned oneVBTC

    // important: make sure changeInterval is a function to allow the interval of update to change
    function addCollateral(address collateral_, uint256 collateralDecimal_, address oracleAddress_, bool oneCoinOracle, bool oracleHasUpdate)
        external
        oneLPGov
    {
        // only add collateral once
        if (!previouslySeenCollateral[collateral_]) collateralArray.push(collateral_);

        previouslySeenCollateral[collateral_] = true;
        acceptedCollateral[collateral_] = true;
        oneCoinCollateralOracle[collateral_] = oneCoinOracle;
        collateralDecimals[collateral_] = collateralDecimal_;
        collateralOracle[collateral_] = oracleAddress_;
        collateralMintFee[collateral_] = 0;
        collateralOracleHasUpdate[collateral_]= oracleHasUpdate;
    }


    function setCollateralMintFee(address collateral_, uint256 fee_)
        external
        oneLPGov
    {
        require(acceptedCollateral[collateral_], "invalid collateral");
        require(fee_ <= 100 * 10 ** 9, "Fee must be valid");
        emit NewMintFee(collateral_, collateralMintFee[collateral_], fee_);
        collateralMintFee[collateral_] = fee_;
    }

    // step size = how much the reserve rate updates per update cycle
    function setReserveStepSize(uint256 stepSize_)
        external
        oneLPGov
    {
        reserveStepSize = stepSize_;
    }

    // changes the oracle for a given collaterarl
    function setCollateralOracle(address collateral_, address oracleAddress_, bool oneCoinOracle_, bool oracleHasUpdate)
        external
        oneLPGov
    {
        require(acceptedCollateral[collateral_], "invalid collateral");
        oneCoinCollateralOracle[collateral_] = oneCoinOracle_;
        collateralOracle[collateral_] = oracleAddress_;
        collateralOracleHasUpdate[collateral_] = oracleHasUpdate;
    }

    // removes a collateral from minting. Still allows withdrawals however
    function removeCollateral(address collateral_)
        external
        oneLPGov
    {
        acceptedCollateral[collateral_] = false;
    }

    // used for querying
    function getBurnedStablecoin(address _user)
        public
        view
        returns (uint256)
    {
        return _burnedStablecoin[_user];
    }

    // returns 10 ** 9 price of collateral
    function getCollateralUsd(address collateral_) public view returns (uint256) {
        require(previouslySeenCollateral[collateral_], "must be an existing collateral");

        if (oneCoinCollateralOracle[collateral_]) return OneToken(collateral_).getOneTokenUsd();
        
        return IOracleInterface(collateralOracle[collateral_]).getLatestPrice();
    }

    function globalCollateralValue() public view returns (uint256) {
        uint256 totalCollateralUsd = 0;

        for (uint i = 0; i < collateralArray.length; i++){
            // Exclude null addresses
            if (collateralArray[i] != address(0)){
                totalCollateralUsd += IERC20(collateralArray[i]).balanceOf(address(this)).mul(10 ** 9).div(10 ** collateralDecimals[collateralArray[i]]).mul(getCollateralUsd(collateralArray[i])).div(10 ** 9); // add stablecoin balance
            }

        }
        return totalCollateralUsd;
    }

    // return price of oneVBTC in 10 ** 9 decimal
    function getOneTokenUsd()
        public
        view
        returns (uint256)
    {
        return IOracleInterface(oneTokenOracle).getLatestPrice();
    }

    /**
     * @return The total number of oneVBTC.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        override
        view
        returns (uint256)
    {
        return _oneBalances[who];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override
        validRecipient(to)
        updateProtocol()
        returns (bool)
    {
        _oneBalances[msg.sender] = _oneBalances[msg.sender].sub(value);
        _oneBalances[to] = _oneBalances[to].add(value);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedOne[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        validRecipient(to)
        updateProtocol()
        returns (bool)
    {
        _allowedOne[from][msg.sender] = _allowedOne[from][msg.sender].sub(value);

        _oneBalances[from] = _oneBalances[from].sub(value);
        _oneBalances[to] = _oneBalances[to].add(value);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        validRecipient(spender)
        updateProtocol()
        returns (bool)
    {
        _allowedOne[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedOne[msg.sender][spender] = _allowedOne[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedOne[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedOne[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedOne[msg.sender][spender] = 0;
        } else {
            _allowedOne[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedOne[msg.sender][spender]);
        return true;
    }

    function setOneTokenOracle(address oracle_, bool hasUpdate)
        external
        oneLPGov
        returns (bool)
    {
        oneTokenOracle = oracle_;
        oneTokenOracleHasUpdate = hasUpdate;

        return true;
    }

    function setStimulusOracle(address oracle_, bool hasUpdate)
        external
        oneLPGov
        returns (bool)
    {
        stimulusOracle = oracle_;
        stimulusOracleHasUpdate = hasUpdate;

        return true;
    }

    function setStimulusPriceChangeMax(uint256 change_)
        external
        oneLPGov
        returns (bool)
    {
        IOracleInterface(stimulusOracle).priceChangeMax(change_);

        return true;
    }

    // oracle rate is 10 ** 9 decimals
    // returns $Z / Stimulus
    function getStimulusUSD()
        public
        view
        returns (uint256)
    {
        return IOracleInterface(stimulusOracle).getLatestPrice();
       
    }

    // minimum amount of block time (seconds) required for an update in reserve ratio
    function setMinimumRefreshTime(uint256 val_)
        external
        oneLPGov
        returns (bool)
    {
        require(val_ != 0, "minimum refresh time must be valid");

        minimumRefreshTime = val_;

        // change collateral array
        for (uint i = 0; i < collateralArray.length; i++){
            if (acceptedCollateral[collateralArray[i]] && !oneCoinCollateralOracle[collateralArray[i]] && collateralOracleHasUpdate[collateralArray[i]]) IOracleInterface(collateralOracle[collateralArray[i]]).changeInterval(val_);
        }

        if (oneTokenOracleHasUpdate) IOracleInterface(oneTokenOracle).changeInterval(val_);

        if (stimulusOracleHasUpdate) IOracleInterface(stimulusOracle).changeInterval(val_);

        // change all the oracles (collateral, stimulus, oneToken)

        emit NewMinimumRefreshTime(val_);
        return true;
    }

    constructor(
        uint256 reserveRatio_,
        address stimulus_,
        uint256 stimulusDecimals_
    )
        public
    {
        _setupDecimals(uint8(9));
        stimulus = stimulus_;
        minimumRefreshTime = 3600 * 1; // 1 hour by default
        stimulusDecimals = stimulusDecimals_;
        reserveStepSize = 2 * 10 ** 8;  // 0.2% by default
        MIN_RESERVE_RATIO = 95 * 10 ** 9;
        MAX_RESERVE_RATIO = 100 * 10 ** 9;
        MIN_DELAY = 3;             // 3 blocks
        withdrawFee = 45 * 10 ** 7; // 0.45% fee at first, remains in collateral
        gov = msg.sender;
        lpGov = msg.sender;
        reserveRatio = reserveRatio_;

        uint256 firstMint = 1000 * 10 ** 9;  //mint 1000 to create LP

        _totalSupply = firstMint; //mint 1000 to create LP

        _oneBalances[msg.sender] = firstMint;
        emit Transfer(address(0x0), msg.sender, firstMint);
    }

    function setMinimumReserveRatio(uint256 val_)
        external
        oneLPGov
    {
        MIN_RESERVE_RATIO = val_;
        if (MIN_RESERVE_RATIO > reserveRatio) setReserveRatio(MIN_RESERVE_RATIO);
    }

    function setMaximumReserveRatio(uint256 val_)
        external
        oneLPGov
    {
        MAX_RESERVE_RATIO = val_;
        if (MAX_RESERVE_RATIO < reserveRatio) setReserveRatio(MAX_RESERVE_RATIO);
    }

    function setMinimumDelay(uint256 val_)
        external
        oneLPGov
    {
        MIN_DELAY = val_;
    }

    // LP pool governance ====================================
    function setPendingLPGov(address pendingLPGov_)
        external
        oneLPGov
    {
        address oldPendingLPGov = pendingLPGov;
        pendingLPGov = pendingLPGov_;
        emit NewPendingLPGov(oldPendingLPGov, pendingLPGov_);
    }

    function acceptLPGov()
        external
    {
        require(msg.sender == pendingLPGov, "!pending");
        address oldLPGov = lpGov; // that
        lpGov = pendingLPGov;
        pendingLPGov = address(0);
        emit NewGov(oldLPGov, lpGov);
    }

    // over-arching protocol level governance  ===============
    function setPendingGov(address pendingGov_)
        external
        onlyIchiGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    function acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }
    // ======================================================

    // calculates how much you will need to send in order to mint oneVBTC, depending on current market prices + reserve ratio
    // oneAmount: the amount of oneVBTC you want to mint
    // collateral: the collateral you want to use to pay
    // also works in the reverse direction, i.e. how much collateral + stimulus to receive when you burn One
    function consultOneDeposit(uint256 oneAmount, address collateral)
        public
        view
        returns (uint256, uint256)
    {
        require(oneAmount != 0, "must use valid oneAmount");
        require(acceptedCollateral[collateral], "must be an accepted collateral");

        uint256 stimulusUsd = getStimulusUSD();     // 10 ** 9

        // convert to correct decimals for collateral
        uint256 collateralAmount = oneAmount.mul(reserveRatio).div(MAX_RESERVE_RATIO).mul(10 ** collateralDecimals[collateral]).div(10 ** DECIMALS);
        collateralAmount = collateralAmount.mul(10 ** 9).div(getCollateralUsd(collateral));

        if (address(oneTokenOracle) == address(0)) return (collateralAmount, 0);

        uint256 stimulusAmountInOneStablecoin = oneAmount.mul(MAX_RESERVE_RATIO.sub(reserveRatio)).div(MAX_RESERVE_RATIO);

        uint256 stimulusAmount = stimulusAmountInOneStablecoin.mul(10 ** 9).div(stimulusUsd).mul(10 ** stimulusDecimals).div(10 ** DECIMALS); // must be 10 ** stimulusDecimals

        return (collateralAmount, stimulusAmount);
    }

    function consultOneWithdraw(uint256 oneAmount, address collateral)
        public
        view
        returns (uint256, uint256)
    {
        require(oneAmount != 0, "must use valid oneAmount");
        require(previouslySeenCollateral[collateral], "must be an accepted collateral");

        uint256 collateralAmount = oneAmount.sub(oneAmount.mul(withdrawFee).div(100 * 10 ** DECIMALS)).mul(10 ** collateralDecimals[collateral]).div(10 ** DECIMALS);
        collateralAmount = collateralAmount.mul(10 ** 9).div(getCollateralUsd(collateral));

        return (collateralAmount, 0);
    }

    // @title: deposit collateral + stimulus token
    // collateral: address of the collateral to deposit (USDC, DAI, TUSD, etc)
    function mint(
        uint256 oneAmount,
        address collateral
    )
        public
        payable
        nonReentrant
        updateProtocol()
    {
        require(acceptedCollateral[collateral], "must be an accepted collateral");
        require(oneAmount != 0, "must mint non-zero amount");

        // wait 3 blocks to avoid flash loans
        require((_lastCall[msg.sender] + MIN_DELAY) <= block.number, "action too soon - please wait a few more blocks");

        // validate input amounts are correct
        (uint256 collateralAmount, uint256 stimulusAmount) = consultOneDeposit(oneAmount, collateral);
        require(collateralAmount <= IERC20(collateral).balanceOf(msg.sender), "sender has insufficient collateral balance");
        require(stimulusAmount <= IERC20(stimulus).balanceOf(msg.sender), "sender has insufficient stimulus balance");

        // checks passed, so transfer tokens
        SafeERC20.safeTransferFrom(IERC20(collateral), msg.sender, address(this), collateralAmount);
        SafeERC20.safeTransferFrom(IERC20(stimulus), msg.sender, address(this), stimulusAmount);

        oneAmount = oneAmount.sub(oneAmount.mul(mintFee).div(100 * 10 ** DECIMALS));                            // apply mint fee
        oneAmount = oneAmount.sub(oneAmount.mul(collateralMintFee[collateral]).div(100 * 10 ** DECIMALS));      // apply collateral fee

        _totalSupply = _totalSupply.add(oneAmount);
        _oneBalances[msg.sender] = _oneBalances[msg.sender].add(oneAmount);

        emit Transfer(address(0x0), msg.sender, oneAmount);

        _lastCall[msg.sender] = block.number;

        emit Mint(stimulus, msg.sender, collateral, collateralAmount, stimulusAmount, oneAmount);
    }

    // fee_ should be 10 ** 9 decimals (e.g. 10% = 10 * 10 ** 9)
    function editMintFee(uint256 fee_)
        external
        onlyIchiGov
    {
        require(fee_ <= 100 * 10 ** 9, "Fee must be valid");
        mintFee = fee_;
        emit MintFee(fee_);
    }

    // fee_ should be 10 ** 9 decimals (e.g. 10% = 10 * 10 ** 9)
    function editWithdrawFee(uint256 fee_)
        external
        onlyIchiGov
    {
        withdrawFee = fee_;
        emit WithdrawFee(fee_);
    }

    /// burns stablecoin and increments _burnedStablecoin mapping for user
    ///         user can claim collateral in a 2nd step below
    function withdraw(
        uint256 oneAmount,
        address collateral
    )
        public
        nonReentrant
        updateProtocol()
    {
        require(oneAmount != 0, "must withdraw non-zero amount");
        require(oneAmount <= _oneBalances[msg.sender], "insufficient balance");
        require(previouslySeenCollateral[collateral], "must be an existing collateral");
        require((_lastCall[msg.sender] + MIN_DELAY) <= block.number, "action too soon - please wait a few blocks");

        // burn oneAmount
        _totalSupply = _totalSupply.sub(oneAmount);
        _oneBalances[msg.sender] = _oneBalances[msg.sender].sub(oneAmount);

        _burnedStablecoin[msg.sender] = _burnedStablecoin[msg.sender].add(oneAmount);

        _lastCall[msg.sender] = block.number;
        emit Transfer(msg.sender, address(0x0), oneAmount);
    }

    // 2nd step for withdrawal of collateral
    // this 2 step withdrawal is important for prevent flash-loan style attacks
    // flash-loan style attacks try to use loops/complex arbitrage strategies to
    // drain collateral so adding a 2-step process prevents any potential attacks
    // because all flash-loans must be repaid within 1 tx and 1 block

    /// @notice If you are interested, I would recommend reading: https://slowmist.medium.com/
    ///         also https://cryptobriefing.com/50-million-lost-the-top-19-defi-cryptocurrency-hacks-2020/
    function withdrawFinal(address collateral, uint256 amount)
        public
        nonReentrant
        updateProtocol()
    {
        require(previouslySeenCollateral[collateral], "must be an existing collateral");
        require((_lastCall[msg.sender] + MIN_DELAY) <= block.number, "action too soon - please wait a few blocks");

        uint256 oneAmount = _burnedStablecoin[msg.sender];
        require(oneAmount != 0, "insufficient oneVBTC to redeem");
        require(amount <= oneAmount, "insufficient oneVBTC to redeem");

        _burnedStablecoin[msg.sender] = _burnedStablecoin[msg.sender].sub(amount);

        // send collateral - fee (convert to collateral decimals too)
        uint256 collateralAmount = amount.sub(amount.mul(withdrawFee).div(100 * 10 ** DECIMALS)).mul(10 ** collateralDecimals[collateral]).div(10 ** DECIMALS);
        collateralAmount = collateralAmount.mul(10 ** 9).div(getCollateralUsd(collateral));

        uint256 stimulusAmount = 0;

        // check enough reserves - don't want to burn one coin if we cannot fulfill withdrawal
        require(collateralAmount <= IERC20(collateral).balanceOf(address(this)), "insufficient collateral reserves - try another collateral");

        SafeERC20.safeTransfer(IERC20(collateral), msg.sender, collateralAmount);

        _lastCall[msg.sender] = block.number;

        emit Withdraw(stimulus, msg.sender, collateral, collateralAmount, stimulusAmount, amount);
    }

    // internal function used to set the reserve ratio of the token
    // must be between MIN / MAX Reserve Ratio, which are constants
    // cannot be 0
    function setReserveRatio(uint256 newRatio_)
        internal
    {
        require(newRatio_ >= 0, "positive reserve ratio");

        if (newRatio_ <= MAX_RESERVE_RATIO && newRatio_ >= MIN_RESERVE_RATIO) {
            reserveRatio = newRatio_;
            emit NewReserveRate(reserveRatio);
        }
    }

    /// @notice easy function transfer ETH (not WETH)
    function safeTransferETH(address to, uint value)
        public
        oneLPGov
    {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    /// @notice easy funtion to move stimulus to a new location
    //  location: address to send to
    //  amount: amount of stimulus to send (use full decimals)
    function moveStimulus(
        address location,
        uint256 amount
    )
        public
        oneLPGov
    {
        SafeERC20.safeTransfer(IERC20(stimulus), location, amount);
    }

    // can execute any abstract transaction on this smart contrat
    // target: address / smart contract you are interracting with
    // value: msg.value (amount of eth in WEI you are sending. Most of the time it is 0)
    // signature: the function signature (name of the function and the types of the arguments).
    //            for example: "transfer(address,uint256)", or "approve(address,uint256)"
    // data: abi-encodeded byte-code of the parameter values you are sending. See "./encode.js" for Ether.js library function to make this easier
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable oneLPGov returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "oneVBTC::executeTransaction: Transaction execution reverted.");

        return returnData;
    }

}