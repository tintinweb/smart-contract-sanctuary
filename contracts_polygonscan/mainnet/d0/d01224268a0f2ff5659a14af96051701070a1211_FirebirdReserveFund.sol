/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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

    uint256[49] private __gap;
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IValueLiquidRouter {
    event Exchange(address pair, uint256 amountOut, address output);
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    function factory() external view returns (address);

    function controller() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address pair,
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
        address pair,
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

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    ) external payable returns (uint256 totalAmountOut);

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    ) external payable returns (uint256 totalAmountIn);

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to
    ) external returns (uint256 liquidity);

    function createPairETH(
        address token,
        uint256 amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to
    ) external payable returns (uint256 liquidity);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
}

/*
    Bancor Formula interface
*/
interface IValueLiquidFormula {
    function getReserveAndWeights(address pair, address tokenA)
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getFactoryReserveAndWeights(
        address factory,
        address pair,
        address tokenA
    )
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountIn);

    function getPairAmountIn(
        address pair,
        address tokenIn,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountOut);

    function getPairAmountOut(
        address pair,
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function ensureConstantValue(
        uint256 reserve0,
        uint256 reserve1,
        uint256 balance0Adjusted,
        uint256 balance1Adjusted,
        uint32 tokenWeight0
    ) external view returns (bool);

    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function mintLiquidityFee(
        uint256 totalLiquidity,
        uint112 reserve0,
        uint112 reserve1,
        uint32 tokenWeight0,
        uint32 tokenWeight1,
        uint112 collectedFee0,
        uint112 collectedFee1
    ) external view returns (uint256 amount);
}

interface IValueLiquidPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

interface IOneSwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (address);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getTokenLength() external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    // withdraw fee update function
    function updateUserWithdrawFee(address recipient, uint256 transferAmount) external;

    function calculateRemoveLiquidity(address account, uint256 amount) external view returns (uint256[] memory);

    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function withdrawAdminFees() external;
}

interface IRewardPool {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
}

interface IBurnabledERC20 {
    function burn(uint256) external;
}

interface IProtocolFeeRemover {
    function transfer(address _token, uint256 _value) external;

    function remove(address[] calldata pairs) external;
}

interface ImHopeStakingPool {
    function allocateMoreRewards(uint256 _addedReward, uint256 _days) external;
}

contract FirebirdReserveFund is OwnableUpgradeSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public strategist;

    // flags
    bool public publicAllowed; // set to true to allow public to call rebalance()

    // price
    uint256 public hopePriceToSell; // to rebalance if price is high

    address public constant hope = address(0xd78C475133731CD54daDCb430F7aAE4F03C1E660);
    address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address public constant wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);

    address public hopeWethPair = address(0xdd600F769a6BFe5Dac39f5DA23C18433E6d92CBa);
    address public hopeWmaticPair = address(0x5E9cd0861F927ADEccfEB2C0124879b277Dd66aC);
    address public wethUsdcPair = address(0x39D736D2b254eE30796f43Ec665143010b558F82);
    address public wmaticUsdcPair = address(0xCe2cB67b11ec0399E39AF20433927424f9033233);

    IProtocolFeeRemover public protocolFeeRemover = IProtocolFeeRemover(0xEf7E3401f70aE2e49E3D2af0A30d2978A059cd7b);
    address[] public protocolFeePairsToRemove;
    address[] public toCashoutTokenList;

    IUniswapV2Router public quickswapRouter = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    mapping(address => mapping(address => address[])) public quickswapPaths;

    IValueLiquidRouter public firebirdRouter = IValueLiquidRouter(0xF6fa9Ea1f64f1BBfA8d71f7f43fAF6D45520bfac); // FireBirdRouter
    IValueLiquidFormula public firebirdFormula = IValueLiquidFormula(0x7973b6961C8C5ca8026B9FB82332626e715ff8c7);
    mapping(address => mapping(address => address[])) public firebirdPaths;

    mapping(address => uint256) public maxAmountToTrade; // HOPE, WETH, WMATIC, USDC

    address public constant os3FBird = address(0x4a592De6899fF00fBC2c99d7af260B5E7F88D1B4);
    address public constant os3FBirdSwap = address(0x01C9475dBD36e46d1961572C8DE24b74616Bae9e);
    address public constant osIron3pool = address(0xC45c1087a6eF7A956af96B0fEED5a7c270f5C901);
    address public constant osIron3poolSwap = address(0x563E49a74fd6AB193751f6C616ce7Cf900D678E5);
    address public constant dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address public constant usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address public constant iron = address(0xD86b5923F3AD7b585eD81B448170ae026c65ae9a);

    // address public constant mHopeStakingPool = address(0x0C80Da180F82B82c85939198d7f64bc4DC5Abb04);

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    uint256 private _locked = 0;
    address[] public pairWithOwner;
    mapping(address => address) public projectOwner; // Pair -> Project owner wallet
    mapping(address => uint256) public projectOwnerProfitShareRate; // 100 = 1%

    address public mHopeStakingPool;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event SwapToken(address inputToken, address outputToken, uint256 amount, uint256 amountReceived);
    event BurnToken(address token, uint256 amount);
    event CollectFeeFromProtocol(address[] pairs);
    event CollectFeeAndShareProfitToOwner(address pair, address projectOwner, uint256 shareProfit, uint256 totalProfit);
    event GetBackTokenFromProtocol(address token, uint256 amount);
    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);
    event OneSwapRemoveLiquidity(uint256 amount);
    event CollectOneSwapFees(uint256 timestampe);

    /* ========== Modifiers =============== */

    modifier onlyStrategist() {
        require(strategist == msg.sender || owner() == msg.sender, "!strategist");
        _;
    }

    modifier checkPublicAllow() {
        require(publicAllowed || strategist == msg.sender || owner() == msg.sender, "!authorised nor !publicAllowed");
        _;
    }

    modifier lock() {
        require(_locked == 0, "LOCKED");
        _locked = 1;
        _;
        _locked = 0;
    }

    /* ========== GOVERNANCE ========== */

    function initialize() external initializer {
        OwnableUpgradeSafe.__Ownable_init();

        //        hopePriceToSell = 1000000; // >= 1 USDC
        //
        //        hopeWethPair = address(0xdd600F769a6BFe5Dac39f5DA23C18433E6d92CBa);
        //        hopeWmaticPair = address(0x5E9cd0861F927ADEccfEB2C0124879b277Dd66aC);
        //        wethUsdcPair = address(0x39D736D2b254eE30796f43Ec665143010b558F82);
        //        wmaticUsdcPair = address(0xCe2cB67b11ec0399E39AF20433927424f9033233);
        //
        //        protocolFeeRemover = IProtocolFeeRemover(0xEf7E3401f70aE2e49E3D2af0A30d2978A059cd7b);
        //
        //        quickswapRouter = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        //        firebirdRouter = IValueLiquidRouter(0xF6fa9Ea1f64f1BBfA8d71f7f43fAF6D45520bfac);
        //        firebirdFormula = IValueLiquidFormula(0x7973b6961C8C5ca8026B9FB82332626e715ff8c7);
        //
        //        firebirdPaths[hope][weth] = [hopeWethPair];
        //        firebirdPaths[hope][wmatic] = [hopeWmaticPair];
        //        firebirdPaths[weth][usdc] = [wethUsdcPair];
        //        firebirdPaths[wmatic][usdc] = [wmaticUsdcPair];
        //        firebirdPaths[hope][usdc] = [hopeWethPair, wethUsdcPair];
        //
        //        firebirdPaths[weth][hope] = [hopeWethPair];
        //        firebirdPaths[wmatic][hope] = [hopeWmaticPair];
        //        firebirdPaths[usdc][weth] = [wethUsdcPair];
        //        firebirdPaths[usdc][wmatic] = [wmaticUsdcPair];
        //        firebirdPaths[usdc][hope] = [wethUsdcPair, hopeWethPair];
        //
        //        maxAmountToTrade[hope] = 20000 ether;
        //        maxAmountToTrade[weth] = 5 ether;
        //        maxAmountToTrade[wmatic] = 10000 ether;
        //        maxAmountToTrade[usdc] = 10000000000; // 10k
        //
        //        toCashoutTokenList.push(weth);
        //        toCashoutTokenList.push(wmatic);
        //        toCashoutTokenList.push(weth);
        //        toCashoutTokenList.push(wbtc);
        //
        //        firebirdPaths[wbtc][usdc] = [address(0x10F525CFbCe668815Da5142460af0fCfb5163C81), wethUsdcPair]; // WBTC -> WETH -> USDC
        //
        //        strategist = msg.sender;
        //        publicAllowed = true;
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(_spender, _amount);
    }

    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;
    }

    function setPublicAllowed(bool _publicAllowed) external onlyStrategist {
        publicAllowed = _publicAllowed;
    }

    function setQuickswapPath(
        address _input,
        address _output,
        address[] memory _path
    ) external onlyStrategist {
        quickswapPaths[_input][_output] = _path;
    }

    function setFirebirdPaths(
        address _inputToken,
        address _outputToken,
        address[] memory _path
    ) external onlyOwner {
        delete firebirdPaths[_inputToken][_outputToken];
        firebirdPaths[_inputToken][_outputToken] = _path;
    }

    function setFirebirdPathsToUsdcViaWeth(address _inputToken, address _pairWithWeth) external onlyOwner {
        delete firebirdPaths[_inputToken][usdc];
        firebirdPaths[_inputToken][usdc] = [_pairWithWeth, wethUsdcPair];
    }

    function setFirebirdPathsToUsdcViaWmatic(address _inputToken, address _pairWithWmatic) external onlyOwner {
        delete firebirdPaths[_inputToken][usdc];
        firebirdPaths[_inputToken][usdc] = [_pairWithWmatic, wmaticUsdcPair];
    }

    function setProtocolFeeRemover(IProtocolFeeRemover _protocolFeeRemover) external onlyOwner {
        protocolFeeRemover = _protocolFeeRemover;
    }

    function setProtocolFeePairsToRemove(address[] memory _protocolFeePairsToRemove) external onlyOwner {
        delete protocolFeePairsToRemove;
        protocolFeePairsToRemove = _protocolFeePairsToRemove;
    }

    function addProtocolFeePairs(address[] memory _protocolFeePairsToRemove) external onlyOwner {
        uint256 _length = _protocolFeePairsToRemove.length;
        for (uint256 i = 0; i < _length; i++) {
            addProtocolFeePair(_protocolFeePairsToRemove[i]);
        }
    }

    function addProtocolFeePair(address _pair) public onlyOwner {
        uint256 _length = protocolFeePairsToRemove.length;
        for (uint256 i = 0; i < _length; i++) {
            require(protocolFeePairsToRemove[i] != address(_pair), "duplicated pair");
        }
        protocolFeePairsToRemove.push(_pair);
    }

    function addTokenToCashout(address _token) external onlyOwner {
        uint256 _length = toCashoutTokenList.length;
        for (uint256 i = 0; i < _length; i++) {
            require(toCashoutTokenList[i] != address(_token), "duplicated token");
        }
        toCashoutTokenList.push(_token);
    }

    //    function removeTokenToCashout(address _token) external onlyOwner returns (bool) {
    //        uint256 _length = toCashoutTokenList.length;
    //        for (uint256 i = 0; i < _length; i++) {
    //            if (toCashoutTokenList[i] == _token) {
    //                if (i < _length - 1) {
    //                    toCashoutTokenList[i] = toCashoutTokenList[_length - 1];
    //                }
    //                delete toCashoutTokenList[_length - 1];
    //                toCashoutTokenList.pop();
    //                return true;
    //            }
    //        }
    //        revert("not found");
    //    }

    function grantFund(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function allocateUsdcRewardsToStakingPool(uint256 _addedReward, uint256 _days) external onlyOwner {
        IERC20(usdc).safeIncreaseAllowance(mHopeStakingPool, _addedReward);
        ImHopeStakingPool(mHopeStakingPool).allocateMoreRewards(_addedReward, _days);
    }

    function setMHopeStakingPool(address _mHopeStakingPool) external onlyOwner {
        require(_mHopeStakingPool != address(0), "invalid address");
        mHopeStakingPool = _mHopeStakingPool;
    }

    function setMaxAmountToTrade(address _token, uint256 _amount) external onlyStrategist {
        maxAmountToTrade[_token] = _amount;
    }

    function setHopePriceToSell(uint256 _hopePriceToSell) external onlyStrategist {
        require(_hopePriceToSell >= 500000 ether && _hopePriceToSell <= 8000000, "out of range"); // [0.5, 8] USDC
        hopePriceToSell = _hopePriceToSell;
    }

    function setPairProjectOwnerProfitSharing(
        address _pair,
        address _projectOwner,
        uint256 _shareRate
    ) public onlyOwner {
        require(_shareRate <= 10000, "over 100%");
        projectOwner[_pair] = _projectOwner;
        projectOwnerProfitShareRate[_pair] = _shareRate;
    }

    function addPairWithOwner(
        address _pair,
        address _projectOwner,
        uint256 _shareRate
    ) external onlyOwner {
        uint256 _length = pairWithOwner.length;
        for (uint256 i = 0; i < _length; i++) {
            require(pairWithOwner[i] != address(_pair), "duplicated token");
        }
        pairWithOwner.push(_pair);
        setPairProjectOwnerProfitSharing(_pair, _projectOwner, _shareRate);
    }

    function removePairWithOwner(address _pair) external onlyOwner returns (bool) {
        uint256 _length = pairWithOwner.length;
        for (uint256 i = 0; i < _length; i++) {
            if (pairWithOwner[i] == _pair) {
                if (i < _length - 1) {
                    pairWithOwner[i] = pairWithOwner[_length - 1];
                }
                delete pairWithOwner[_length - 1];
                pairWithOwner.pop();
                setPairProjectOwnerProfitSharing(_pair, address(0), 0);
                return true;
            }
        }
        revert("not found");
    }

    /* ========== VIEW FUNCTIONS ========== */

    function protocolFeePairsToRemoveLength() external view returns (uint256) {
        return protocolFeePairsToRemove.length;
    }

    function toCashoutTokenListLength() external view returns (uint256) {
        return toCashoutTokenList.length;
    }

    function pairWithOwnerLength() external view returns (uint256) {
        return pairWithOwner.length;
    }

    function tokenBalances()
        public
        view
        returns (
            uint256 _hopeBal,
            uint256 _wethBal,
            uint256 _wmaticBal,
            uint256 _usdcBal
        )
    {
        _hopeBal = IERC20(hope).balanceOf(address(this));
        _wethBal = IERC20(weth).balanceOf(address(this));
        _wmaticBal = IERC20(wmatic).balanceOf(address(this));
        _usdcBal = IERC20(usdc).balanceOf(address(this));
    }

    function exchangeRate(
        address _inputToken,
        address _outputToken,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        uint256[] memory amounts = firebirdFormula.getAmountsOut(_inputToken, _outputToken, _tokenAmount, firebirdPaths[_inputToken][_outputToken]);
        return amounts[amounts.length - 1];
    }

    function getHopeToUsdcPrice() public view returns (uint256) {
        return exchangeRate(weth, usdc, exchangeRate(hope, weth, 1 ether));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function collectFeeAndShareProfitToOwner(address _pair) public lock {
        address _projectOwner = projectOwner[_pair];
        uint256 _shareRate = projectOwnerProfitShareRate[_pair];
        if (_projectOwner != address(0) && _shareRate > 0) {
            require(publicAllowed || _projectOwner == msg.sender || strategist == msg.sender || owner() == msg.sender, "!authorised nor !publicAllowed");
            address _protocolFeeRemover = address(protocolFeeRemover);
            uint256 _pairBal = IERC20(_pair).balanceOf(_protocolFeeRemover);
            if (_pairBal > 0) {
                uint256 _shareProfit = _pairBal.mul(_shareRate).div(10000);
                uint256 _before = IERC20(_pair).balanceOf(address(this));
                IProtocolFeeRemover(_protocolFeeRemover).transfer(_pair, _shareProfit);
                uint256 _after = IERC20(_pair).balanceOf(address(this));
                IERC20(_pair).safeTransfer(_projectOwner, _after.sub(_before));
                emit CollectFeeAndShareProfitToOwner(_pair, _projectOwner, _shareProfit, _pairBal);
            }
            address[] memory _pairs = new address[](1);
            _pairs[0] = _pair;
            IProtocolFeeRemover(_protocolFeeRemover).remove(_pairs);
        }
    }

    function collectFeeFromProtocol() public checkPublicAllow {
        uint256 _length = pairWithOwner.length;
        for (uint256 i = 0; i < _length; i++) {
            collectFeeAndShareProfitToOwner(pairWithOwner[i]);
        }
        protocolFeeRemover.remove(protocolFeePairsToRemove);
        emit CollectFeeFromProtocol(protocolFeePairsToRemove);
    }

    function collectOneSwapFees() public checkPublicAllow {
        IOneSwap(os3FBirdSwap).withdrawAdminFees();
        IOneSwap(osIron3poolSwap).withdrawAdminFees();
        uint8 _daiIndex = IOneSwap(os3FBirdSwap).getTokenIndex(dai);
        uint8 _usdcIndex = IOneSwap(os3FBirdSwap).getTokenIndex(usdc);
        uint8 _usdtIndex = IOneSwap(os3FBirdSwap).getTokenIndex(usdt);
        uint256 _ironBal = IERC20(iron).balanceOf(address(this));
        if (_ironBal > 0) {
            // IERC20(iron).safeIncreaseAllowance(osIron3poolSwap, _ironBal);
            // uint256 _outputAmount = IOneSwap(osIron3poolSwap).swap(1, 0, _ironBal, 1, now.add(60)); // IRON (1) -> 3FBIRD (0)
            // emit SwapToken(iron, os3FBird, _ironBal, _outputAmount);
            _quickswapSwapToken(new address[](0), iron, usdc, _ironBal);
        }
        uint256 _os3FBirdBal = IERC20(os3FBird).balanceOf(address(this));
        if (_os3FBirdBal > 0) {
            IERC20(os3FBird).safeIncreaseAllowance(os3FBirdSwap, _os3FBirdBal);
            IOneSwap(os3FBirdSwap).removeLiquidityOneToken(_os3FBirdBal, _usdcIndex, 1, now.add(60));
            emit OneSwapRemoveLiquidity(_os3FBirdBal);
        }
        uint256 _daiBal = IERC20(dai).balanceOf(address(this));
        if (_daiBal > 0) {
            IERC20(dai).safeIncreaseAllowance(os3FBirdSwap, _daiBal);
            uint256 _outputAmount = IOneSwap(os3FBirdSwap).swap(_daiIndex, _usdcIndex, _daiBal, 1, now.add(60));
            emit SwapToken(dai, usdc, _daiBal, _outputAmount);
        }
        uint256 _usdtBal = IERC20(usdt).balanceOf(address(this));
        if (_usdtBal > 0) {
            IERC20(usdt).safeIncreaseAllowance(os3FBirdSwap, _usdtBal);
            uint256 _outputAmount = IOneSwap(os3FBirdSwap).swap(_usdtIndex, _usdcIndex, _usdtBal, 1, now.add(60));
            emit SwapToken(usdt, usdc, _usdtBal, _outputAmount);
        }
        emit CollectOneSwapFees(now);
    }

    function cashoutHopeToUsdc() public checkPublicAllow {
        uint256 _hopePrice = getHopeToUsdcPrice();
        if (_hopePrice >= hopePriceToSell) {
            uint256 _sellingHope = IERC20(hope).balanceOf(address(this));
            (uint256 _hopeWethReserve, , uint256 _totalHopeReserve) = hopeLpReserves();
            uint256 _sellAmountToWethPool = _sellingHope.mul(_hopeWethReserve).div(_totalHopeReserve);
            uint256 _sellAmountToWmaticPool = _sellingHope.sub(_sellAmountToWethPool);
            _firebirdSwapToken(hope, weth, _sellAmountToWethPool);
            _firebirdSwapToken(hope, wmatic, _sellAmountToWmaticPool);
        }
    }

    function sellTokensToUsdc() public checkPublicAllow {
        uint256 _length = toCashoutTokenList.length;
        for (uint256 i = 0; i < _length; i++) {
            address _token = toCashoutTokenList[i];
            uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
            if (_tokenBal > 0) {
                require(firebirdPaths[_token][usdc].length > 0, "No route to sell");
                _firebirdSwapToken(_token, usdc, _tokenBal);
            }
        }
    }

    function workForReserveFund() external checkPublicAllow {
        collectFeeFromProtocol();
        collectOneSwapFees();
        cashoutHopeToUsdc();
        sellTokensToUsdc();
    }

    function getBackTokenFromProtocol(address _token, uint256 _amount) public onlyStrategist {
        IProtocolFeeRemover(protocolFeeRemover).transfer(_token, _amount);
        emit GetBackTokenFromProtocol(_token, _amount);
    }

    function forceBurn(uint256 _hopeAmount) external onlyOwner {
        IBurnabledERC20(hope).burn(_hopeAmount);
    }

    function forceSell(address _buyingToken, uint256 _hopeAmount) public onlyStrategist {
        _firebirdSwapToken(hope, _buyingToken, _hopeAmount);
    }

    function forceSellToUsdc(uint256 _hopeAmount) external onlyStrategist {
        forceSell(usdc, _hopeAmount);
    }

    function forceBuy(address _sellingToken, uint256 _sellingAmount) external onlyStrategist {
        require(getHopeToUsdcPrice() <= hopePriceToSell, "current price is too high");
        _firebirdSwapToken(_sellingToken, hope, _sellingAmount);
    }

    //    function trimNonCoreToken(address _sellingToken) public onlyStrategist {
    //        require(_sellingToken != hope && _sellingToken != weth && _sellingToken != wmatic && _sellingToken != usdc, "core");
    //        uint256 _bal = IERC20(_sellingToken).balanceOf(address(this));
    //        if (_bal > 0) {
    //            _firebirdSwapToken(_sellingToken, hope, _bal);
    //        }
    //    }

    //    function quickswapSwapToken(address _inputToken, address _outputToken, uint256 _amount) external onlyStrategist {
    //        _quickswapSwapToken(quickswapPaths[_inputToken][_outputToken], _inputToken, _outputToken, _amount);
    //    }

    //    function quickswapAddLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired) external onlyStrategist {
    //        _quickswapAddLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired);
    //    }

    //    function quickswapAddLiquidityMax(address _tokenA, address _tokenB) external onlyStrategist {
    //        _quickswapAddLiquidity(_tokenA, _tokenB, IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
    //    }

    //    function quickswapRemoveLiquidity(address _pair, uint256 _liquidity) external onlyStrategist {
    //        _quickswapRemoveLiquidity(_pair, _liquidity);
    //    }

    //    function quickswapRemoveLiquidityMax(address _pair) external onlyStrategist {
    //        _quickswapRemoveLiquidity(_pair, IERC20(_pair).balanceOf(address(this)));
    //    }

    function firebirdSwapToken(
        address _inputToken,
        address _outputToken,
        uint256 _amount
    ) external onlyStrategist {
        _firebirdSwapToken(_inputToken, _outputToken, _amount);
    }

    function firebirdAddLiquidity(
        address _pair,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) external onlyStrategist {
        _firebirdAddLiquidity(_pair, _amountADesired, _amountBDesired);
    }

    //    function firebirdAddLiquidityMax(address _pair) external onlyStrategist {
    //        address _tokenA = IValueLiquidPair(_pair).token0();
    //        address _tokenB = IValueLiquidPair(_pair).token1();
    //        _firebirdAddLiquidity(_pair, IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
    //    }

    function firebirdRemoveLiquidity(address _pair, uint256 _liquidity) external onlyStrategist {
        _firebirdRemoveLiquidity(_pair, _liquidity);
    }

    //    function firebirdRemoveLiquidityMax(address _pair) external onlyStrategist {
    //        _firebirdRemoveLiquidity(_pair, IERC20(_pair).balanceOf(address(this)));
    //    }

    /* ========== FARMING ========== */

    function depositToPool(
        address _pool,
        uint256 _pid,
        address _lpAdd,
        uint256 _lpAmount
    ) public onlyStrategist {
        IERC20(_lpAdd).safeIncreaseAllowance(_pool, _lpAmount);
        IRewardPool(_pool).deposit(_pid, _lpAmount);
    }

    //    function depositToPoolMax(address _pool, uint256 _pid, address _lpAdd) external onlyStrategist {
    //        uint256 _bal = IERC20(_lpAdd).balanceOf(address(this));
    //        require(_bal > 0, "no lp");
    //        depositToPool(_pool, _pid, _lpAdd, _bal);
    //    }

    function withdrawFromPool(
        address _pool,
        uint256 _pid,
        uint256 _lpAmount
    ) public onlyStrategist {
        IRewardPool(_pool).withdraw(_pid, _lpAmount);
    }

    //    function withdrawFromPoolMax(address _pool, uint256 _pid) external onlyStrategist {
    //        uint256 _stakedAmount = stakeAmountFromPool(_pool, _pid);
    //        withdrawFromPool(_pool, _pid, _stakedAmount);
    //    }

    function claimFromPool(address _pool, uint256 _pid) public checkPublicAllow {
        IRewardPool(_pool).withdraw(_pid, 0);
    }

    function pendingFromPool(address _pool, uint256 _pid) external view returns (uint256) {
        return IRewardPool(_pool).pendingReward(_pid, address(this));
    }

    function stakeAmountFromPool(address _pool, uint256 _pid) public view returns (uint256 _stakedAmount) {
        (_stakedAmount, ) = IRewardPool(_pool).userInfo(_pid, address(this));
    }

    /* ========== LIBRARIES ========== */

    function _quickswapSwapToken(
        address[] memory _path,
        address _inputToken,
        address _outputToken,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        uint256 _maxAmount = maxAmountToTrade[_inputToken];
        if (_maxAmount > 0 && _maxAmount < _amount) {
            _amount = _maxAmount;
        }
        if (_path.length <= 1) {
            _path = new address[](2);
            _path[0] = _inputToken;
            _path[1] = _outputToken;
        }
        IERC20(_inputToken).safeIncreaseAllowance(address(quickswapRouter), _amount);
        uint256[] memory amountReceiveds = IUniswapV2Router(quickswapRouter).swapExactTokensForTokens(_amount, 1, _path, address(this), now.add(60));
        emit SwapToken(_inputToken, _outputToken, _amount, amountReceiveds[amountReceiveds.length - 1]);
    }

    //    function _quickswapAddLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired) internal {
    //        IERC20(_tokenA).safeIncreaseAllowance(address(quickswapRouter), _amountADesired);
    //        IERC20(_tokenB).safeIncreaseAllowance(address(quickswapRouter), _amountBDesired);
    //        IUniswapV2Router(quickswapRouter).addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired, 1, 1, address(this), now.add(60));
    //    }

    //    function _quickswapRemoveLiquidity(address _pair, uint256 _liquidity) internal {
    //        address _tokenA = IUniswapV2Pair(_pair).token0();
    //        address _tokenB = IUniswapV2Pair(_pair).token1();
    //        IERC20(_pair).safeIncreaseAllowance(address(quickswapRouter), _liquidity);
    //        IUniswapV2Router(quickswapRouter).removeLiquidity(_tokenA, _tokenB, _liquidity, 1, 1, address(this), now.add(60));
    //    }

    function _firebirdSwapToken(
        address _inputToken,
        address _outputToken,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        uint256 _maxAmount = maxAmountToTrade[_inputToken];
        if (_maxAmount > 0 && _maxAmount < _amount) {
            _amount = _maxAmount;
        }
        IERC20(_inputToken).safeIncreaseAllowance(address(firebirdRouter), _amount);
        uint256[] memory amountReceiveds = firebirdRouter.swapExactTokensForTokens(_inputToken, _outputToken, _amount, 1, firebirdPaths[_inputToken][_outputToken], address(this), now.add(60));
        emit SwapToken(_inputToken, _outputToken, _amount, amountReceiveds[amountReceiveds.length - 1]);
    }

    function _firebirdAddLiquidity(
        address _pair,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) internal {
        address _tokenA = IValueLiquidPair(_pair).token0();
        address _tokenB = IValueLiquidPair(_pair).token1();
        IERC20(_tokenA).safeIncreaseAllowance(address(firebirdRouter), _amountADesired);
        IERC20(_tokenB).safeIncreaseAllowance(address(firebirdRouter), _amountBDesired);
        firebirdRouter.addLiquidity(_pair, _tokenA, _tokenB, _amountADesired, _amountBDesired, 0, 0, address(this), now.add(60));
    }

    function _firebirdRemoveLiquidity(address _pair, uint256 _liquidity) internal {
        IERC20(_pair).safeIncreaseAllowance(address(firebirdRouter), _liquidity);
        address _tokenA = IValueLiquidPair(_pair).token0();
        address _tokenB = IValueLiquidPair(_pair).token1();
        firebirdRouter.removeLiquidity(_pair, _tokenA, _tokenB, _liquidity, 1, 1, address(this), now.add(60));
    }

    function _getReserves(
        address tokenA,
        address tokenB,
        address pair
    ) internal view returns (uint256 _reserveA, uint256 _reserveB) {
        address _token0 = IUniswapV2Pair(pair).token0();
        address _token1 = IUniswapV2Pair(pair).token1();
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        if (_token0 == tokenA) {
            if (_token1 == tokenB) {
                _reserveA = uint256(_reserve0);
                _reserveB = uint256(_reserve1);
            }
        } else if (_token0 == tokenB) {
            if (_token1 == tokenA) {
                _reserveA = uint256(_reserve1);
                _reserveB = uint256(_reserve0);
            }
        }
    }

    function hopeLpReserves()
        public
        view
        returns (
            uint256 _hopeWethReserve,
            uint256 _hopeWmaticReserve,
            uint256 _totalHopeReserve
        )
    {
        (_hopeWethReserve, ) = _getReserves(hope, weth, hopeWethPair);
        (_hopeWmaticReserve, ) = _getReserves(hope, usdc, hopeWmaticPair);
        _totalHopeReserve = _hopeWethReserve.add(_hopeWmaticReserve);
    }

    /* ========== EMERGENCY ========== */

    function renounceOwnership() public override onlyOwner {
        revert("Dangerous");
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string("ReserveFund::executeTransaction: Transaction execution reverted."));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }

    receive() external payable {}
}