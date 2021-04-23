/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity 0.6.6;


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
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "REENTRANCY_ERROR");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Interface declarations
/* solhint-disable func-order */
interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
interface IHarvestVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 numberOfShares) external;
}

// SPDX-License-Identifier: MIT
interface IMintNoRewardPool {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function earned(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function userRewardPerTokenPaid(address account)
        external
        view
        returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function getReward() external;
}

// SPDX-License-Identifier: MIT
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
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

// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor()
        public
        ERC20("pAT", "Parachain Auction Token")
    {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
    */
    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "ReceiptToken: Caller is not a minter"
        );
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
    */
    function burn(address from, uint256 amount) public {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "ReceiptToken: Caller is not a burner"
        );
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
/*
  |Strategy Flow| 
      - User shows up with DAI and we deposit it in Havest's Vault. 
      - After this we have fDAI that we add in Harvest's Reward Pool which gives FARM as rewards

    - Withdrawal flow does same thing, but backwards
        - User can obtain extra DAI when withdrawing. 50% of them goes to the user, 50% goes to the treasury in ETH
        - User can obtain FARM tokens when withdrawing. 50% of them goes to the user in DAI, 50% goes to the treasury in ETH 
*/
contract HarvestDAIStableCoin is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserDeposits {
        uint256 timestamp;
        uint256 amountfDai;
    }

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountDai; //how much DAI the user entered with
        uint256 amountfDai; //how much fDAI was obtained after deposit to vault
        uint256 amountReceiptToken; //receipt tokens printed for user; should be equal to amountfDai
        uint256 underlyingRatio; //ratio between obtained fDai and dai
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        uint256 joinTimestamp; //first deposit timestamp; taken into account for lock time
        bool wasUserBlacklisted; //if user was blacklist at deposit time, he is not receiving receipt tokens
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        UserDeposits[] deposits;
        uint256 earnedTokens; //before fees
        uint256 earnedRewards; //before fees
    }
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public blacklisted; //blacklisted users do not receive a receipt token

    uint256 public firstDepositTimestamp; //used to calculate reward per block
    uint256 public totalDeposits;

    uint256 public cap = uint256(1000000); //eth cap
    uint256 public totalDai; //total invested eth
    uint256 public lockTime = 10368000; //120 days

    address payable public feeAddress;
    uint256 public fee = uint256(50);
    uint256 constant feeFactor = uint256(10000);

    ReceiptToken public receiptToken;
    address public dai;
    address public weth;
    address public farmToken;
    address public harvestPoolToken;
    address payable public treasuryAddress;
    IMintNoRewardPool public harvestRewardPool; //deposit fDai
    IHarvestVault public harvestRewardVault; //get fDai
    IUniswapRouter public sushiswapRouter;

    uint256 public ethDust;
    uint256 public treasueryEthDust;

    //events
    event RewardsExchanged(
        address indexed user,
        string exchangeType, //ETH or DAI
        uint256 rewardsAmount,
        uint256 obtainedAmount
    );
    event ExtraTokensExchanged(
        address indexed user,
        uint256 tokensAmount,
        uint256 obtainedEth
    );
    event ObtainedInfo(
        address indexed user,
        uint256 underlying,
        uint256 underlyingReceipt
    );
    event RewardsEarned(address indexed user, uint256 amount);
    event ExtraTokens(address indexed user, uint256 amount);
    event FeeSet(address indexed sender, uint256 feeAmount);
    event FeeAddressSet(address indexed sender, address indexed feeAddress);

    /// @notice Event emitted when blacklist status for an address changes
    event BlacklistChanged(
        string actionType,
        address indexed user,
        bool oldVal,
        bool newVal
    );
    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 amountDai,
        uint256 amountfDai
    );

    /// @notice Event emitted when user withdraws
    event Withdraw(
        address indexed user,
        address indexed origin,
        uint256 amountDai,
        uint256 amountfDai,
        uint256 treasuryAmountEth
    );

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(
        string indexed addressType,
        address indexed oldAddress,
        address indexed newAddress
    );

    //internal
    mapping(address => bool) public approved; //to defend against non whitelisted contracts

    /// @notice Used internally for avoiding "stack-too-deep" error when depositing
    struct DepositData {
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedDai;
        uint256 obtainedfDai;
        uint256 prevfDaiBalance;
    }

    /// @notice Used internally for avoiding "stack-too-deep" error when withdrawing
    struct WithdrawData {
        uint256 prevDustEthBalance;
        uint256 prevfDaiBalance;
        uint256 prevDaiBalance;
        uint256 obtainedfDai;
        uint256 obtainedDai;
        uint256 feeableDai;
        uint256 auctionedEth;
        uint256 auctionedDai;
        uint256 totalDai;
        uint256 rewards;
        uint256 farmBalance;
    }

    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultDAI  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestPoolToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _dai DAI address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _receiptToken Receipt token that is minted and burned
     * @param _feeAddress fee address
     */
    constructor(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestPoolToken,
        address _farmToken,
        address _dai,
        address _weth,
        address payable _treasuryAddress,
        address _receiptToken,
        address payable _feeAddress
    ) public {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        require(_harvestRewardPool != address(0), "POOL_0x0");
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_harvestPoolToken != address(0), "TOKEN_0x0");
        require(_farmToken != address(0), "FARM_0x0");
        require(_dai != address(0), "DAI_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_receiptToken != address(0), "RECEIPT_0x0");
        require(_feeAddress != address(0), "FEE_0x0");

        harvestRewardVault = IHarvestVault(_harvestRewardVault);
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        harvestPoolToken = _harvestPoolToken;
        farmToken = _farmToken;
        dai = _dai;
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        receiptToken = ReceiptToken(_receiptToken);
        feeAddress = _feeAddress;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Setters -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Update the address of VaultDAI
     * @dev Can only be called by the owner
     * @param _harvestRewardVault Address of VaultDAI
     */
    function setHarvestRewardVault(address _harvestRewardVault)
        public
        onlyOwner
    {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        emit ChangedAddress(
            "VAULT",
            address(harvestRewardVault),
            _harvestRewardVault
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
    }

    /**
     * @notice Update the address of NoMintRewardPool
     * @dev Can only be called by the owner
     * @param _harvestRewardPool Address of NoMintRewardPool
     */
    function setHarvestRewardPool(address _harvestRewardPool) public onlyOwner {
        require(_harvestRewardPool != address(0), "POOL_0x0");
        emit ChangedAddress(
            "POOL",
            address(harvestRewardPool),
            _harvestRewardPool
        );
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
    }

    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter) public onlyOwner {
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_ROUTER",
            address(sushiswapRouter),
            _sushiswapRouter
        );
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @notice Update the address of Pool's underlying token
     * @dev Can only be called by the owner
     * @param _harvestPoolToken Address of Pool's underlying token
     */
    function setHarvestPoolToken(address _harvestPoolToken) public onlyOwner {
        require(_harvestPoolToken != address(0), "TOKEN_0x0");
        emit ChangedAddress("TOKEN", harvestPoolToken, _harvestPoolToken);
        harvestPoolToken = _harvestPoolToken;
    }

    /**
     * @notice Update the address of FARM
     * @dev Can only be called by the owner
     * @param _farmToken Address of FARM
     */
    function setFarmToken(address _farmToken) public onlyOwner {
        require(_farmToken != address(0), "FARM_0x0");
        emit ChangedAddress("FARM", farmToken, _farmToken);
        farmToken = _farmToken;
    }

    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _feeAddress Fee's address
     */
    function setTreasury(address payable _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress(
            "TREASURY",
            address(treasuryAddress),
            address(_feeAddress)
        );
        treasuryAddress = _feeAddress;
    }

    /**
     * @notice Approve contract (only approved contracts or msg.sender==tx.origin can call this strategy)
     * @dev Can only be called by the owner
     * @param account Contract's address
     */
    function approveContractAccess(address account) external onlyOwner {
        require(account != address(0), "0x0");
        approved[account] = true;
    }

    /**
     * @notice Revoke contract's access (only approved contracts or msg.sender==tx.origin can call this strategy)
     * @dev Can only be called by the owner
     * @param account Contract's address
     */
    function revokeContractAccess(address account) external onlyOwner {
        require(account != address(0), "0x0");
        approved[account] = false;
    }

    /**
     * @notice Blacklist address; blacklisted addresses do not receive receipt tokens
     * @dev Can only be called by the owner
     * @param account User/contract address
     */
    function blacklistAddress(address account) external onlyOwner {
        require(account != address(0), "0x0");
        emit BlacklistChanged("BLACKLIST", account, blacklisted[account], true);
        blacklisted[account] = true;
    }

    /**
     * @notice Remove address from blacklisted addresses; blacklisted addresses do not receive receipt tokens
     * @dev Can only be called by the owner
     * @param account User/contract address
     */
    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), "0x0");
        emit BlacklistChanged("REMOVE", account, blacklisted[account], false);
        blacklisted[account] = false;
    }

    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime > 0, "TIME_0");
        lockTime = _lockTime;
    }

    function setFeeAddress(address payable _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
        emit FeeAddressSet(msg.sender, _feeAddress);
    }

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        fee = _fee;
        emit FeeSet(msg.sender, _fee);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() public onlyOwner {
        if (ethDust > 0) {
            treasuryAddress.transfer(ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        public
        onlyOwner
    {
        require(_token != address(0), "token_0x0");
        require(to != address(0), "to_0x0");
        require(_token != farmToken, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }

    /**
     * @notice Check if user can withdraw based on current lock time
     * @param user Address of the user
     * @return true or false
     */
    function isWithdrawalAvailable(address user) public view returns (bool) {
        if (lockTime > 0) {
            return userInfo[user].timestamp.add(lockTime) <= block.timestamp;
        }
        return true;
    }

    /**
     * @notice Deposit to this strategy for rewards
     * @param daiAmount Amount of DAI investment
     * @param deadline Number of blocks until transaction expires
     * @return Amount of fDAI
     */
    function deposit(uint256 daiAmount, uint256 deadline)
        public
        nonReentrant
        returns (uint256)
    {
        // -----
        // validate
        // -----
        _defend();
        require(daiAmount > 0, "DAI_0");
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(totalDai.add(daiAmount) <= cap, "CAP_REACHED");

        DepositData memory results;
        UserInfo storage user = userInfo[msg.sender];

        if (user.amountfDai == 0) {
            user.wasUserBlacklisted = blacklisted[msg.sender];
        }
        if (user.timestamp == 0) {
            user.timestamp = block.timestamp;
        }

        IERC20(dai).safeTransferFrom(msg.sender, address(this), daiAmount);

        totalDai = totalDai.add(daiAmount);
        user.amountDai = user.amountDai.add(daiAmount);

        results.obtainedDai = daiAmount;

        // -----
        // deposit DAI into harvest and get fDAI
        // -----
        IERC20(dai).safeIncreaseAllowance(
            address(harvestRewardVault),
            results.obtainedDai
        );

        results.prevfDaiBalance = IERC20(harvestPoolToken).balanceOf(
            address(this)
        );
        harvestRewardVault.deposit(results.obtainedDai);
        results.obtainedfDai = (
            IERC20(harvestPoolToken).balanceOf(address(this))
        )
            .sub(results.prevfDaiBalance);

        // -----
        // stake fDAI into the NoMintRewardPool
        // -----
        IERC20(harvestPoolToken).safeIncreaseAllowance(
            address(harvestRewardPool),
            results.obtainedfDai
        );
        user.amountfDai = user.amountfDai.add(results.obtainedfDai);
        if (!user.wasUserBlacklisted) {
            user.amountReceiptToken = user.amountReceiptToken.add(
                results.obtainedfDai
            );
            receiptToken.mint(msg.sender, results.obtainedfDai);
            emit ReceiptMinted(msg.sender, results.obtainedfDai);
        }

        harvestRewardPool.stake(results.obtainedfDai);

        emit Deposit(
            msg.sender,
            tx.origin,
            results.obtainedDai,
            results.obtainedfDai
        );

        if (firstDepositTimestamp == 0) {
            firstDepositTimestamp = block.timestamp;
        }
        if (user.joinTimestamp == 0) {
            user.joinTimestamp = block.timestamp;
        }
        totalDeposits = totalDeposits.add(results.obtainedfDai);
        harvestRewardPool.getReward(); //transfers FARM to this contract

        user.deposits.push(
            UserDeposits({
                timestamp: block.timestamp,
                amountfDai: results.obtainedfDai
            })
        );

        user.underlyingRatio = _getRatio(user.amountfDai, user.amountDai, 18);
        return results.obtainedfDai;
    }

    function _updateDeposits(
        bool removeAll,
        uint256 remainingAmountfDai,
        address account
    ) private {
        UserInfo storage user = userInfo[account];
        if (removeAll) {
            delete user.deposits;
            return;
        }

        for (uint256 i = user.deposits.length; i > 0; i--) {
            if (remainingAmountfDai >= user.deposits[i - 1].amountfDai) {
                remainingAmountfDai = remainingAmountfDai.sub(
                    user.deposits[i - 1].amountfDai
                );
                user.deposits[i - 1].amountfDai = 0;
            } else {
                user.deposits[i - 1].amountfDai = user.deposits[i - 1]
                    .amountfDai
                    .sub(remainingAmountfDai);
                remainingAmountfDai = 0;
            }

            if (remainingAmountfDai == 0) {
                break;
            }
        }
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of ETH obtained
     */
    function withdraw(uint256 amount, uint256 deadline)
        public
        nonReentrant
        returns (uint256)
    {
        // -----
        // validation
        // -----
        uint256 receiptBalance = receiptToken.balanceOf(msg.sender);

        _defend();
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amountfDai >= amount, "AMOUNT_GREATER_THAN_BALANCE");
        if (!user.wasUserBlacklisted) {
            require(
                receiptBalance >= user.amountReceiptToken,
                "RECEIPT_AMOUNT"
            );
        }
        if (lockTime > 0) {
            require(
                user.timestamp.add(lockTime) <= block.timestamp,
                "LOCK_TIME"
            );
        }
        WithdrawData memory results;
        results.prevDustEthBalance = address(this).balance;

        // -----
        // withdraw from NoMintRewardPool and get fDai back
        // -----
        results.prevfDaiBalance = IERC20(harvestPoolToken).balanceOf(
            address(this)
        );
        IERC20(harvestPoolToken).safeIncreaseAllowance(
            address(harvestRewardPool),
            amount
        );

        harvestRewardPool.getReward(); //transfers FARM to this contract
        results.farmBalance = IERC20(farmToken).balanceOf(address(this));
        results.rewards = getPendingRewards(msg.sender, amount);

        _updateDeposits(amount == user.amountfDai, amount, msg.sender);

        harvestRewardPool.withdraw(amount);

        results.obtainedfDai = (
            IERC20(harvestPoolToken).balanceOf(address(this))
        )
            .sub(results.prevfDaiBalance);

        //not sure if it's possible to get more from harvest so better to protect
        if (results.obtainedfDai < user.amountfDai) {
            user.amountfDai = user.amountfDai.sub(results.obtainedfDai);
            if (!user.wasUserBlacklisted) {
                user.amountReceiptToken = user.amountReceiptToken.sub(
                    results.obtainedfDai
                );
                receiptToken.burn(msg.sender, results.obtainedfDai);
                emit ReceiptBurned(msg.sender, results.obtainedfDai);
            }
        } else {
            user.amountfDai = 0;
            if (!user.wasUserBlacklisted) {
                receiptToken.burn(msg.sender, user.amountReceiptToken);
                emit ReceiptBurned(msg.sender, user.amountReceiptToken);
                user.amountReceiptToken = 0;
            }
        }

        // -----
        // withdraw from Harvest-DAI vault and get Dai back
        // -----
        IERC20(harvestPoolToken).safeIncreaseAllowance(
            address(harvestRewardVault),
            results.obtainedfDai
        );

        results.prevDaiBalance = IERC20(dai).balanceOf(address(this));
        harvestRewardVault.withdraw(results.obtainedfDai);
        results.obtainedDai = (IERC20(dai).balanceOf(address(this))).sub(
            results.prevDaiBalance
        );

        emit ObtainedInfo(
            msg.sender,
            results.obtainedDai,
            results.obtainedfDai
        );

        if (amount == user.amountfDai) {
            //there is no point to do the ratio math as we can just get the difference between current obtained tokens and initial obtained tokens
            if (results.obtainedDai > user.amountDai) {
                results.feeableDai = results.obtainedDai.sub(user.amountDai);
            }
        } else {
            uint256 currentRatio =
                _getRatio(results.obtainedfDai, results.obtainedDai, 18);
            results.feeableDai = 0;

            if (currentRatio < user.underlyingRatio) {
                uint256 noOfOriginalTokensForCurrentAmount =
                    (amount.mul(10**18)).div(user.underlyingRatio);
                if (noOfOriginalTokensForCurrentAmount < results.obtainedDai) {
                    results.feeableDai = results.obtainedDai.sub(
                        noOfOriginalTokensForCurrentAmount
                    );
                }
            }
        }
        if (results.feeableDai > 0) {
            uint256 extraTokensFee = _calculateFee(results.feeableDai);
            emit ExtraTokens(
                msg.sender,
                results.feeableDai.sub(extraTokensFee)
            );
            user.earnedTokens = user.earnedTokens.add(
                results.feeableDai.sub(extraTokensFee)
            );
        }

        //not sure if it's possible to get more from harvest so better to protect
        if (results.obtainedDai <= user.amountDai) {
            user.amountDai = user.amountDai.sub(results.obtainedDai);
        } else {
            user.amountDai = 0;
        }
        results.obtainedDai = results.obtainedDai.sub(results.feeableDai);
        //feeableDai/2 => goes to the user
        //feeableDai/2 => goes to the treasury in ETH
        //obtainedDai => goes to the user

        results.auctionedDai = 0;
        if (results.feeableDai > 0) {
            results.auctionedDai = results.feeableDai.div(2);
        }
        results.feeableDai = results.feeableDai.sub(results.auctionedDai);

        results.totalDai = results.obtainedDai.add(results.feeableDai);

        // -----
        // swap auctioned DAI to ETH
        // -----
        address[] memory swapPath = new address[](2);
        swapPath[0] = dai;
        swapPath[1] = weth;

        if (results.auctionedDai > 0) {
            uint256[] memory daiFeeableSwapAmounts =
                sushiswapRouter.swapExactTokensForETH(
                    results.auctionedDai,
                    uint256(0),
                    swapPath,
                    address(this),
                    deadline
                );

            emit ExtraTokensExchanged(
                msg.sender,
                results.auctionedDai,
                daiFeeableSwapAmounts[daiFeeableSwapAmounts.length - 1]
            );

            results.auctionedEth = results.auctionedEth.add(
                daiFeeableSwapAmounts[daiFeeableSwapAmounts.length - 1]
            );
        }
        uint256 transferableRewards = results.rewards;
        if (transferableRewards > results.farmBalance) {
            transferableRewards = results.farmBalance;
        }
        if (transferableRewards > 0) {
            emit RewardsEarned(msg.sender, transferableRewards);
            user.earnedRewards = user.earnedRewards.add(transferableRewards);

            //swap 50% of rewards with ETH and add them to results.auctionedEth
            uint256 auctionedRewards = transferableRewards.div(2);
            //swap 50% of rewards with DAI and add them to results.totalDai
            uint256 userRewards = transferableRewards.sub(auctionedRewards);

            swapPath[0] = farmToken;

            IERC20(farmToken).safeIncreaseAllowance(
                address(sushiswapRouter),
                transferableRewards
            );

            //swap 50% of rewards with ETH and add them to auctionedEth
            uint256[] memory farmSwapAmounts =
                sushiswapRouter.swapExactTokensForETH(
                    auctionedRewards,
                    uint256(0),
                    swapPath,
                    address(this),
                    deadline
                );

            emit RewardsExchanged(
                msg.sender,
                "ETH",
                auctionedRewards,
                farmSwapAmounts[farmSwapAmounts.length - 1]
            );

            results.auctionedEth = results.auctionedEth.add(
                farmSwapAmounts[farmSwapAmounts.length - 1]
            );

            //however, it should be > 0
            if (userRewards > 0) {
                farmSwapAmounts = sushiswapRouter.swapExactTokensForETH(
                    userRewards,
                    uint256(0),
                    swapPath,
                    address(this),
                    deadline
                );

                swapPath[0] = weth;
                swapPath[1] = dai;

                farmSwapAmounts = sushiswapRouter.swapExactETHForTokens{
                    value: farmSwapAmounts[farmSwapAmounts.length - 1]
                }(uint256(0), swapPath, address(this), deadline);

                emit RewardsExchanged(
                    msg.sender,
                    "DAI",
                    userRewards,
                    farmSwapAmounts[farmSwapAmounts.length - 1]
                );

                results.totalDai = results.totalDai.add(
                    farmSwapAmounts[farmSwapAmounts.length - 1]
                );
            }
        }

        // -----
        // transfer ETH to user
        // -----
        totalDeposits = totalDeposits.sub(results.obtainedfDai);
        if (user.amountfDai == 0) //full exit
        {
            //if user exits to early, obtained ETH might be lower than what user initially invested and there will be some left in amountEth
            //making sure we reset it
            user.amountDai = 0;
        } else {
            if (user.amountDai > results.totalDai) {
                user.amountDai = user.amountDai.sub(results.totalDai);
            } else {
                user.amountDai = 0;
            }
        }

        if (results.totalDai < totalDai) {
            totalDai = totalDai.sub(results.totalDai);
        } else {
            totalDai = 0;
        }

        //at some point we might not have any fees
        if (fee > 0) {
            uint256 feeDai = _calculateFee(results.totalDai);
            results.totalDai = results.totalDai.sub(feeDai);

            swapPath[0] = dai;
            swapPath[1] = weth;

            IERC20(dai).safeIncreaseAllowance(address(sushiswapRouter), feeDai);

            uint256[] memory feeSwapAmount =
                sushiswapRouter.swapExactTokensForETH(
                    feeDai,
                    uint256(0),
                    swapPath,
                    address(this),
                    deadline
                );

            feeAddress.transfer(feeSwapAmount[feeSwapAmount.length - 1]);
            user.userCollectedFees = user.userCollectedFees.add(
                feeSwapAmount[feeSwapAmount.length - 1]
            );
        }

        IERC20(dai).safeTransfer(msg.sender, results.totalDai);
        treasuryAddress.transfer(results.auctionedEth);
        user.userTreasuryEth = user.userTreasuryEth.add(results.auctionedEth);

        emit Withdraw(
            msg.sender,
            tx.origin,
            results.obtainedDai,
            results.obtainedfDai,
            results.auctionedEth
        );

        ethDust = ethDust.add(
            address(this).balance.sub(results.prevDustEthBalance)
        );

        if (user.amountfDai == 0 || user.amountDai == 0) {
            user.underlyingRatio = 0;
        } else {
            user.underlyingRatio = _getRatio(
                user.amountfDai,
                user.amountDai,
                18
            );
        }

        return results.totalDai;
    }

    /// @notice Transfer rewards to this strategy
    function updateReward() public onlyOwner {
        harvestRewardPool.getReward();
    }

    function _calculateFee(uint256 amount) private view returns (uint256) {
        return (amount.mul(fee)).div(feeFactor);
    }

    function _defend() private view returns (bool) {
        require(
            approved[msg.sender] || msg.sender == tx.origin,
            "access_denied"
        );
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Getters -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice View function to see pending rewards for account.
     * @param account user account to check
     * @param amount amount you want to calculate for; if 0 will calculate for entire amount
     * @return pending rewards
     */
    function getPendingRewards(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[account];

        if (amount == 0) {
            amount = user.amountfDai;
        }
        if (user.deposits.length == 0 || user.amountfDai == 0) {
            return 0;
        }

        uint256 rewards = 0;
        uint256 remaingAmount = amount;

        uint256 i = user.deposits.length - 1;
        while (remaingAmount > 0) {
            uint256 depositRewards =
                _getPendingRewards(user.deposits[i], remaingAmount);

            rewards = rewards.add(depositRewards);

            if (remaingAmount >= user.deposits[i].amountfDai) {
                remaingAmount = remaingAmount.sub(user.deposits[i].amountfDai);
            } else {
                remaingAmount = 0;
            }

            if (i == 0) {
                break;
            }
            i = i.sub(1);
        }

        return rewards;
    }

    function _getPendingRewards(
        UserDeposits memory user,
        uint256 remainingAmount
    ) private view returns (uint256) {
        if (user.amountfDai == 0) {
            return 0;
        }
        uint256 toCalculateForAmount = 0;
        if (user.amountfDai <= remainingAmount) {
            toCalculateForAmount = user.amountfDai;
        } else {
            toCalculateForAmount = remainingAmount;
        }

        uint256 rewardPerBlock = 0;
        uint256 balance = IERC20(farmToken).balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint256 diff = block.timestamp.sub(firstDepositTimestamp);
        if (diff == 0) {
            rewardPerBlock = balance;
        } else {
            rewardPerBlock = balance.div(diff);
        }
        uint256 rewardPerBlockUser =
            rewardPerBlock.mul(block.timestamp.sub(user.timestamp));
        uint256 ratio = _getRatio(toCalculateForAmount, totalDeposits, 18);
        return (rewardPerBlockUser.mul(ratio)).div(10**18);
    }

    function _getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) private pure returns (uint256) {
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    receive() external payable {}
}