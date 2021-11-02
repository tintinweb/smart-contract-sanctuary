/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT


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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract GovToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) public {}
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }
}

interface IMasterChef {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of GOVs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGOVPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGOVPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. GOVs to distribute per block.
        uint256 lastRewardBlock; // Last block number that GOVs distribution occurs.
        uint256 accGOVPerShare; // Accumulated GOVs per share, times 1e12. See below.
    }

    function GOV()
        external
        view
        returns (GovToken);

    // Block number when bonus GOV period ends.
    function bonusEndBlock()
        external
        view
        returns(uint256);

    // GOV tokens created per block.
    function GOVPerBlock()
        external
        view
        returns(uint256);

    // Bonus muliplier for early GOV makers.
    function BONUS_MULTIPLIER()
        external
        view
        returns(uint256);

    // unused
    function migrator()
        external
        view
        returns(address);

    // Info of each pool.
    function poolInfo(uint256)
        external
        view
        returns (PoolInfo memory);

    // Info of each user that stakes LP tokens.
    function userInfo(uint256, address)
        external
        view
        returns (UserInfo memory);

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    function totalAllocPoint()
        external
        view
        returns(uint256);

    // The block number when GOV mining starts.
    function startBlock()
        external
        view
        returns (uint256);

    function poolExists(IERC20) external view returns (bool);

    // total deposits in a pool
    function balanceOf(uint256)
        external
        view
        returns (uint256);

    // pool rewards locked for future claim
    function isLocked(uint256)
        external
        view
        returns (bool);

    // total locked rewards for a user
    function lockedRewards(address)
        external
        view
        returns (uint256);

    function isPaused()
        external
        view
        returns(bool);

    function poolLength()
        external
        view
        returns (uint256);

    function owner()
        external
        view
        returns(address);

    function addExternalReward(uint256 _amount)
        external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function getMultiplierNow()
        external
        view
        returns (uint256);

    function getMultiplierPrecise(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    // View function to see pending GOVs on frontend.
    function pendingGOV(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools()
        external;

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid)
        external;

    // Deposit LP tokens to MasterChef for GOV allocation.
    function deposit(uint256 _pid, uint256 _amount)
        external;

    function claimReward(uint256 _pid)
        external;

    function compoundReward(uint256 _pid)
        external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount)
        external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid)
        external;

    // Update dev address by the previous dev.
    function dev(address _devaddr)
        external;

    // Custom logic - helpers
    function getPoolInfos() external view returns(PoolInfo[] memory);

    function getOptimisedUserInfos(address _user)
        external
        view
        returns(uint256[4][] memory);

    function getUserInfos(address _wallet)
        external
        view
        returns(UserInfo[] memory);

    function getPendingGOV(address _user)
        external
        view
        returns(uint256[] memory);

    function altRewardsDebt(address _user)
        external
        view
        returns(uint256);

    function addAltReward()
        external
        payable;

    function pendingAltRewards(address _user)
        external
        view
        returns (uint256);

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Withdraw(address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AddExternalReward(
        address indexed sender,
        uint256 indexed pid,
        uint256 amount
    );
}

interface GovTokenLike {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

contract MintCoordinator_BSC is Ownable {

    GovTokenLike public constant govToken = GovTokenLike(0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF);

    mapping (address => bool) public minters;

    constructor() public {
        // adding MasterChef
        minters[0x1FDCA2422668B961E162A8849dc0C2feaDb58915] = true;
    }

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");
        govToken.mint(_to, _amount);
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        govToken.transferOwnership(newOwner);
    }

    function addMinter(address addr) public onlyOwner {
        minters[addr] = true;
    }

    function removeMinter(address addr) public onlyOwner {
        minters[addr] = false;
    }
}

contract Upgradeable is Ownable {
    address public implementation;
}

contract MasterChef_BSC is Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The GOV TOKEN!
    GovToken public GOV;
    // Dev address.
    address public devaddr;
    // Block number when bonus GOV period ends.
    uint256 public bonusEndBlock;
    // GOV tokens created per block.
    uint256 public GOVPerBlock;
    // Bonus muliplier for early GOV makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // unused
    address public migrator;
    // Info of each pool.
    IMasterChef.PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => IMasterChef.UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GOV mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    uint256 internal constant GOV_POOL_ID = 7;
    event AddExternalReward(
        address indexed sender,
        uint256 indexed pid,
        uint256 amount
    );

    MintCoordinator_BSC public constant coordinator = MintCoordinator_BSC(0x68d57B33Fe3B691Ef96dFAf19EC8FA794899f2ac);

    mapping(IERC20 => bool) public poolExists;

    modifier nonDuplicated(IERC20 _lpToken) {
        require(!poolExists[_lpToken], "pool exists");
        _;
    }

    // total deposits in a pool
    mapping(uint256 => uint256) public balanceOf;

    // pool rewards locked for future claim
    mapping(uint256 => bool) public isLocked;

    // total locked rewards for a user
    mapping(address => uint256) internal _lockedRewards;


    bool public notPaused;

    modifier checkNoPause() {
        require(notPaused || msg.sender == owner(), "paused");
        _;
    }

    // vestingStamp for a user
    mapping(address => uint256) public userStartVestingStamp;

    //default value if userStartVestingStamp[user] == 0
    uint256 public startVestingStamp;

    uint256 public vestingDuration; // 15768000 6 months (6 * 365 * 24 * 60 * 60)


    event AddAltReward(
        address indexed sender,
        uint256 indexed pid,
        uint256 amount
    );

    event ClaimAltRewards(
        address indexed user,
        uint256 amount
    );

    //Mapping pid -- accumulated bnbPerGov
    mapping(uint256 => uint256[]) public altRewardsRounds;   // Old

    //user => lastClaimedRound
    mapping(address => uint256) public userAltRewardsRounds; // Old

    //pid -- altRewardsPerShare
    mapping(uint256 => uint256) public altRewardsPerShare;

    //pid -- (user -- altRewardsPerShare)
    mapping(uint256 => mapping(address => uint256)) public userAltRewardsPerShare;

    uint256 internal constant  IBZRX_POOL_ID = 5;

    function initialize(
        GovToken _GOV,
        address _devaddr,
        uint256 _GOVPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public onlyOwner {
        require(address(GOV) == address(0), "unauthorized");
        GOV = _GOV;
        devaddr = _devaddr;
        GOVPerBlock = _GOVPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function setVestingDuration(uint256 _vestingDuration)
        external
        onlyOwner
    {
        vestingDuration = _vestingDuration;
    }

    function setStartVestingStamp(uint256 _startVestingStamp)
        external
        onlyOwner
    {
        startVestingStamp = _startVestingStamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate)
        public
        onlyOwner
        nonDuplicated(_lpToken)
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExists[_lpToken] = true;
        poolInfo.push(
            IMasterChef.PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGOVPerShare: 0
            })
        );
    }

    // Update the given pool's GOV allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        public
        onlyOwner
    {
        if (_withUpdate) {
            massUpdatePools();
        }

        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0) && poolExists[pool.lpToken], "pool not exists");
        totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
            _allocPoint
        );
        pool.allocPoint = _allocPoint;

        if (block.number < pool.lastRewardBlock) {
            pool.lastRewardBlock = startBlock;
        }
    }

    function transferTokenOwnership(address newOwner)
        public
        onlyOwner
    {
        GOV.transferOwnership(newOwner);
    }

    function setStartBlock(uint256 _startBlock)
        public
        onlyOwner
    {
        startBlock = _startBlock;
    }

    function setLocked(uint256 _pid, bool _toggle)
        public
        onlyOwner
    {
        isLocked[_pid] = _toggle;
    }

    function setGOVPerBlock(uint256 _GOVPerBlock)
        public
        onlyOwner
    {
        massUpdatePools();
        GOVPerBlock = _GOVPerBlock;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return getMultiplierPrecise(_from, _to).div(1e18);
    }

    function getMultiplierNow()
        public
        view
        returns (uint256)
    {
        return getMultiplierPrecise(block.number - 1, block.number);
    }

    function getMultiplierPrecise(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _getDecliningMultipler(_from, _to, startBlock);
    }

    function _getDecliningMultipler(uint256 _from, uint256 _to, uint256 _bonusStartBlock)
        internal
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(1e18);
        /*
        // _periodBlocks = 864000 = 60 * 60 * 24 * 30 / 3 = blocks_in_30_days
        uint256 _bonusEndBlock = _bonusStartBlock + 864000;

        // multiplier = 7.64e18 = BONUS_MULTIPLIER * 191 / 250 * 10^18
        // declinePerBlock = 7685185185185 = (7.64e18 - 1e18) / _periodBlocks

        uint256 _startMultipler;
        uint256 _endMultipler;
        uint256 _avgMultiplier;

        if (_to <= _bonusEndBlock) {
            _startMultipler = SafeMath.sub(7.64e18,
                _from.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _endMultipler = SafeMath.sub(7.64e18,
                _to.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _avgMultiplier = (_startMultipler + _endMultipler) / 2;

            return _to.sub(_from).mul(_avgMultiplier);
        } else if (_from >= _bonusEndBlock) {
            return _to.sub(_from).mul(1e18);
        } else {

            _startMultipler = SafeMath.sub(7.64e18,
                _from.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _endMultipler = 1e18;

            _avgMultiplier = (_startMultipler + _endMultipler) / 2;

            return _bonusEndBlock.sub(_from).mul(_avgMultiplier).add(
                    _to.sub(_bonusEndBlock).mul(1e18)
                );
        }*/
    }
    
    function _pendingGOV(uint256 _pid, address _user)
        internal
        view
        returns (uint256)
    {
        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        IMasterChef.UserInfo storage user = userInfo[_pid][_user];
        uint256 accGOVPerShare = pool.accGOVPerShare.mul(1e18);
        uint256 lpSupply = balanceOf[_pid];
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplierPrecise(pool.lastRewardBlock, block.number);
            uint256 GOVReward =
                multiplier.mul(GOVPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accGOVPerShare = accGOVPerShare.add(
                GOVReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accGOVPerShare).div(1e30).sub(user.rewardDebt);
    }


    function pendingAltRewards(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        return _pendingAltRewards(pid, _user);
    }

    //Splitted by pid in case if we want to distribute altRewards to other pids like bzrx
    function _pendingAltRewards(uint256 pid, address _user)
        internal
        view
        returns (uint256)
    {
        uint256 userSupply = userInfo[pid][_user].amount;
        uint256 _altRewardsPerShare = altRewardsPerShare[pid];
        if (_altRewardsPerShare == 0)
            return 0;

        if (userSupply == 0)
            return 0;

        uint256 _userAltRewardsPerShare = userAltRewardsPerShare[pid][_user];

        //Handle the backcapability,
        //when all user claim altrewards at least once we can remove this check
        if(_userAltRewardsPerShare == 0 && pid == GOV_POOL_ID){
            //Or didnt claim or didnt migrate

            //check if migrate
            uint256 _lastClaimedRound = userAltRewardsRounds[_user];
            //Never claimed yet
            if (_lastClaimedRound != 0) {
                _lastClaimedRound -= 1; //correct index to start from 0
                _userAltRewardsPerShare = altRewardsRounds[GOV_POOL_ID][_lastClaimedRound];
            }
        }

        return (_altRewardsPerShare.sub(_userAltRewardsPerShare)).mul(userSupply).div(1e12);
    }

    // View function to see pending GOVs on frontend.
    function pendingGOV(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return _pendingGOV(_pid, _user);
    }

    function unlockedRewards(address _user)
        public
        view
        returns (uint256)
    {
        uint256 _locked = _lockedRewards[_user];
        if(_locked == 0) {
            return 0;
        }

        return calculateUnlockedRewards(_locked, now, userStartVestingStamp[_user]);
    }

    function calculateUnlockedRewards(uint256 _locked, uint256 currentStamp, uint256 _userStartVestingStamp)
        public
        view
        returns (uint256)
    {
        //Vesting is not started
        if(startVestingStamp == 0 || vestingDuration == 0){
            return 0;
        }

        if(_userStartVestingStamp == 0) {
            _userStartVestingStamp = startVestingStamp;
        }
        uint256 _cliffDuration = currentStamp.sub(_userStartVestingStamp);
        if(_cliffDuration >= vestingDuration)
            return _locked;

        return _cliffDuration.mul(_locked.div(vestingDuration)); // _locked.div(vestingDuration) is unlockedPerSecond
    }

    function lockedRewards(address _user)
        public
        view
        returns (uint256)
    {
        return _lockedRewards[_user].sub(unlockedRewards(_user));
    }

    function togglePause(bool _isPaused) external onlyOwner {
        notPaused = !_isPaused;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public checkNoPause {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function massMigrateToBalanceOf() public onlyOwner {
        require(!notPaused, "!paused");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            balanceOf[pid] = poolInfo[pid].lpToken.balanceOf(address(this));
        }
        massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public checkNoPause {
        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = balanceOf[_pid];
        uint256 _GOVPerBlock = GOVPerBlock;
        uint256 _allocPoint = pool.allocPoint;
        if (lpSupply == 0 || _GOVPerBlock == 0 || _allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplierPrecise(pool.lastRewardBlock, block.number);
        uint256 GOVReward =
            multiplier.mul(_GOVPerBlock).mul(_allocPoint).div(
                totalAllocPoint
            );
        coordinator.mint(devaddr, GOVReward.div(1e19));
        coordinator.mint(address(this), GOVReward.div(1e18));
        pool.accGOVPerShare = pool.accGOVPerShare.add(
            GOVReward.div(1e6).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Anyone can contribute GOV to a given pool
    function addExternalReward(uint256 _amount) public checkNoPause {
        IMasterChef.PoolInfo storage pool = poolInfo[GOV_POOL_ID];
        require(block.number > pool.lastRewardBlock, "rewards not started");

        uint256 lpSupply = balanceOf[GOV_POOL_ID];
        require(lpSupply != 0, "no deposits");

        updatePool(GOV_POOL_ID);

        GOV.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.accGOVPerShare = pool.accGOVPerShare.add(
            _amount.mul(1e12).div(lpSupply)
        );

        emit AddExternalReward(msg.sender, GOV_POOL_ID, _amount);
    }

    // Anyone can contribute native token rewards to GOV pool stakers
    function addAltReward() public payable checkNoPause {
        IMasterChef.PoolInfo storage pool = poolInfo[IBZRX_POOL_ID];
        require(block.number > pool.lastRewardBlock, "rewards not started");

        uint256 lpSupply = balanceOf[IBZRX_POOL_ID];
        require(lpSupply != 0, "no deposits");

        updatePool(IBZRX_POOL_ID);

        altRewardsPerShare[IBZRX_POOL_ID] = altRewardsPerShare[IBZRX_POOL_ID]
            .add(msg.value.mul(1e12).div(lpSupply));

        emit AddAltReward(msg.sender, IBZRX_POOL_ID, msg.value);
    }

    // Deposit LP tokens to MasterChef for GOV allocation.
    function deposit(uint256 _pid, uint256 _amount) public checkNoPause {
        poolInfo[_pid].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _deposit(_pid, _amount);
    }

    function _deposit(uint256 _pid, uint256 _amount) internal {
        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        IMasterChef.UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 userAmount = user.amount;
        uint256 pending;
        uint256 pendingAlt;

        if (userAmount != 0) {
            pending = userAmount
                .mul(pool.accGOVPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
        }


        if (_pid == GOV_POOL_ID || _pid == IBZRX_POOL_ID) {
            pendingAlt = _pendingAltRewards(_pid, msg.sender);
            //Update userAltRewardsPerShare even if user got nothing in the current round
            userAltRewardsPerShare[_pid][msg.sender] = altRewardsPerShare[_pid];
        }

        if (_amount != 0) {
            balanceOf[_pid] = balanceOf[_pid].add(_amount);
            userAmount = userAmount.add(_amount);
            emit Deposit(msg.sender, _pid, _amount);
        }
        user.rewardDebt = userAmount.mul(pool.accGOVPerShare).div(1e12);
        user.amount = userAmount;
        //user vestingStartStamp recalculation is done in safeGOVTransfer
        safeGOVTransfer(_pid, pending);
        if (pendingAlt != 0) {
            sendValueIfPossible(msg.sender, pendingAlt);
        }
    }

    function claimReward(uint256 _pid) public checkNoPause {
        _deposit(_pid, 0);
    }

    function compoundReward(uint256 _pid) public checkNoPause {
        uint256 balance = GOV.balanceOf(msg.sender);
        _deposit(_pid, 0);

        // locked pools are ignored since they auto-compound
        if (!isLocked[_pid]) {
            balance = GOV.balanceOf(msg.sender).sub(balance);
            if (balance != 0)
                deposit(GOV_POOL_ID, balance);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public checkNoPause {
        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        IMasterChef.UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 userAmount = user.amount;
        require(_amount != 0 && userAmount >= _amount, "withdraw: not good");
        updatePool(_pid);

        uint256 pending = userAmount
            .mul(pool.accGOVPerShare)
            .div(1e12)
            .sub(user.rewardDebt);

        uint256 pendingAlt;
        IERC20 lpToken = pool.lpToken;
        if (_pid == GOV_POOL_ID || _pid == IBZRX_POOL_ID) {
            uint256 availableAmount = userAmount.sub(lockedRewards(msg.sender));
            if (_amount > availableAmount) {
                _amount = availableAmount;
            }

            pendingAlt = _pendingAltRewards(_pid, msg.sender);
            //Update userAltRewardsPerShare even if user got nothing in the current round
            userAltRewardsPerShare[_pid][msg.sender] = altRewardsPerShare[_pid];
        }

        balanceOf[_pid] = balanceOf[_pid].sub(_amount);
        userAmount = userAmount.sub(_amount);
        user.rewardDebt = userAmount.mul(pool.accGOVPerShare).div(1e12);
        user.amount = userAmount;

        lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        //user vestingStartStamp recalculation is done in safeGOVTransfer
        safeGOVTransfer(_pid, pending);
        if (pendingAlt != 0) {
            sendValueIfPossible(msg.sender, pendingAlt);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public checkNoPause {
        IMasterChef.PoolInfo storage pool = poolInfo[_pid];
        IMasterChef.UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 _amount = user.amount;
        uint256 pendingAlt;
        IERC20 lpToken = pool.lpToken;
        if (_pid == GOV_POOL_ID || _pid == IBZRX_POOL_ID) {
            uint256 availableAmount = _amount.sub(lockedRewards(msg.sender));
            if (_amount > availableAmount) {
                _amount = availableAmount;
            }
            pendingAlt = _pendingAltRewards(_pid, msg.sender);
            //Update userAltRewardsPerShare even if user got nothing in the current round
            userAltRewardsPerShare[_pid][msg.sender] = altRewardsPerShare[_pid];
        }

        lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
        balanceOf[_pid] = balanceOf[_pid].sub(_amount);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGOVPerShare).div(1e12);

        if (pendingAlt != 0) {
            sendValueIfPossible(msg.sender, pendingAlt);
        }
    }

    function safeGOVTransfer(uint256 _pid, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        uint256 GOVBal = GOV.balanceOf(address(this));
        if (_amount > GOVBal) {
            _amount = GOVBal;
        }

        if (isLocked[_pid]) {
            uint256 _locked = _lockedRewards[msg.sender];
            _lockedRewards[msg.sender] = _locked.add(_amount);

            userStartVestingStamp[msg.sender] = calculateVestingStartStamp(now, userStartVestingStamp[msg.sender], _locked, _amount);
            _deposit(GOV_POOL_ID, _amount);
        } else {
            GOV.transfer(msg.sender, _amount);
        }
    }

    //This function will be internal after testing,
    function calculateVestingStartStamp(uint256 currentStamp, uint256 _userStartVestingStamp, uint256 _lockedAmount, uint256 _depositAmount)
        public
        view
        returns(uint256)
    {
        //VestingStartStamp will be distributed between
        //_userStartVestingStamp (min) and currentStamp (max) depends on _lockedAmount and _depositAmount

        //To avoid calculation on limit values
        if(_lockedAmount == 0) return startVestingStamp;
        if(_depositAmount >= _lockedAmount) return currentStamp;
        if(_depositAmount == 0) return _userStartVestingStamp;

        //Vesting is not started, set 0 as default value
        if(startVestingStamp == 0 || vestingDuration == 0){
            return 0;
        }

        if(_userStartVestingStamp == 0) {
            _userStartVestingStamp = startVestingStamp;
        }
        uint256 cliffDuration = currentStamp.sub(_userStartVestingStamp);
        uint256 depositShare = _depositAmount.mul(1e12).div(_lockedAmount);
        return _userStartVestingStamp.add(cliffDuration.mul(depositShare).div(1e12));
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


    // Custom logic - helpers
    function getPoolInfos() external view returns(IMasterChef.PoolInfo[] memory poolInfos) {
        uint256 length = poolInfo.length;
        poolInfos = new IMasterChef.PoolInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfos[pid] = poolInfo[pid];
        }
    }

    function getOptimisedUserInfos(address _user) external view returns(uint256[4][] memory userInfos) {
        uint256 length = poolInfo.length;
        userInfos = new uint256[4][](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            userInfos[pid][0] = userInfo[pid][_user].amount;
            userInfos[pid][1] = _pendingGOV(pid, _user);
            userInfos[pid][2] = isLocked[pid] ? 1 : 0;
            userInfos[pid][3] = (pid == GOV_POOL_ID ||  pid == IBZRX_POOL_ID) ? _pendingAltRewards(pid, _user) : 0;
        }
    }

    function getUserInfos(address _wallet) external view returns(IMasterChef.UserInfo[] memory userInfos) {
        uint256 length = poolInfo.length;
        userInfos = new IMasterChef.UserInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            userInfos[pid] = userInfo[pid][_wallet];
        }
    }

    function getPendingGOV(address _user) external view returns(uint256[] memory pending) {
        uint256 length = poolInfo.length;
        pending = new uint256[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            pending[pid] = _pendingGOV(pid, _user);
        }
    }

    function sendValueIfPossible(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) {
            (success, ) = devaddr.call{ value: amount }("");
            if (success)
                emit ClaimAltRewards(devaddr, amount);
        } else {
            emit ClaimAltRewards(recipient, amount);
        }
    }

    //Should be called only once after migration to new calculation
    function setInitialAltRewardsPerShare()
        external
        onlyOwner
    {
        uint256 index = altRewardsRounds[GOV_POOL_ID].length;
        if(index == 0) {
            return;
        }
        uint256 _currentRound = altRewardsRounds[GOV_POOL_ID].length;
        uint256 currentAccumulatedAltRewards = altRewardsRounds[GOV_POOL_ID][_currentRound-1];

        altRewardsPerShare[GOV_POOL_ID] = currentAccumulatedAltRewards;
    }
}