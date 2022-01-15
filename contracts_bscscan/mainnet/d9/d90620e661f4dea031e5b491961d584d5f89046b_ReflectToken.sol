/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: interfaces/IRouter.sol

interface IUniRouterV1
{
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

interface IUniRouterV2 is IUniRouterV1
{
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

// File: interfaces/IFactory.sol

interface IFactory
{
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/Reflect.sol

contract ReflectToken is IERC20, Ownable
{
    //========================
    // LIBS
    //========================

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //========================
    // STRUCTS
    //========================

    struct FeeInfo
    {
        uint256 reflectionFee;
        uint256 liquidityFee;
        uint256 teamFee;
        uint256 marketingFee;
        uint256 burnFee;
    }

    struct FeeValues
    {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;

        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tLiquidityFee;
        uint256 tTeamFee;
        uint256 tMarketingFee;
        uint256 tBurnFee;
    }

    struct tFeeValues
    {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tLiquidityFee;
        uint256 tTeamFee;
        uint256 tMarketingFee;
        uint256 tBurnFee;
    }

    struct UserInfo
    {
        uint256 rOwned;
        uint256 tOwned;
        bool excludedFromFee;
        bool excludedFromReward;
        bool blacklisted;
    }

    //========================
    // CONSTANTS
    //========================

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;      
    uint256 private constant PERCENT_FACTOR = 10000; //100%

    //========================
    // ATTRIBUTES
    //========================
    
    IERC20 private immutable wBNB; //wrapped BNB

    //general
    string public name; 
    string public symbol;
    uint8 public decimals;
    uint256 private rTotal; //total reflections
    uint256 private tTotal; //total supply    
    mapping(address => UserInfo) private userMap; //user info
    address[] private excluded; //list if users that are excluded from rewards
    mapping (address => mapping (address => uint256)) private allowances; //allowances
    uint256 private nonce; //nonce for random

    //fees    
    uint256 public maxFee = 30; //max fee percent (30% = ~43% Slippage)
    uint256 private tFeeTotal; //total collected
    FeeInfo public buyFees; //applied on buys from routerPair
    FeeInfo public p2pFees; //applied on transfers between wallets
    FeeInfo public sellFees; //applied on sells from routerPair
    FeeInfo private emptyFees; //all 0
    address public teamFeeAddress; //address to send team fee to
    address public marketingFeeAddress; //address to send marketing fee too
    uint256 public accumulatedLiquidityFee;
    uint256 public accumulatedTeamFee;
    uint256 public accumulatedMarketingFee;

    //router / pair / swap info
    IUniRouterV2 public router; //router to use for swaps
    IERC20 public routerPair; //LP token on current router

    //liquidify
    bool private inSwapAndLiquify; //currently liquifiying
    bool public swapAndLiquifyEnabled; //liquify enabled
    uint256 public swapTokensAtHigh; //liquify trigger high
    uint256 public swapTokensAtLow; //liquify trigger high
    uint256 public minRemainingTokens; //tokens that have to remain

    //========================
    // EVENTS
    //========================

    event SwapAndLiquifyEnabledUpdated(bool _enabled);
    event Liquified(uint256 _tokensSwapped, uint256 _bnbReceived, uint256 _tokensIntoLiquidity);
    event SwappedForBNB(uint256 _tokensSwapped, uint256 _bnbReceived);
    event ChangeFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee);

    //========================
    // CREATE
    //========================

    //Routers:
    //- BSC Test (PCS): 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    constructor()
    {
        //init
        IUniRouterV2 routerAddress = IUniRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address initialOwner = 0x597aDd1B26e5F8311FEc6863e12c99fD65634747;
        marketingFeeAddress = 0x64c93d688755DC2cfb741389ae638735D80a5386;        
        name = "Reflect8";
        symbol = "RFLCT8";
        decimals = 18;
        tTotal = 1000000000000000 ether;        
        minRemainingTokens = 1 ether;
        swapTokensAtLow = tTotal.mul(1).div(PERCENT_FACTOR);
        swapTokensAtHigh = tTotal.mul(50).div(PERCENT_FACTOR);        

        //config
        router = routerAddress;
        wBNB = IERC20(router.WETH());
        rTotal = (type(uint256).max - (type(uint256).max % totalSupply()));
        swapAndLiquifyEnabled = true;
        excludeFromFee(address(this));

        //create pair
        routerPair = IERC20(IFactory(router.factory()).createPair(address(this), address(wBNB)));

        //user init and give total supply        
        UserInfo storage user = userMap[initialOwner];
        user.rOwned = rTotal;
        user.excludedFromFee = true;
        emit Transfer(address(0), initialOwner, tTotal);

        //exclude from rewards
        excludeFromReward(BURN_ADDRESS);

        //config fees
        buyFees = FeeInfo(
        {
            reflectionFee: 300,
            liquidityFee: 200,
            teamFee: 0,
            marketingFee: 2500,
            burnFee: 0
        });
        sellFees = FeeInfo(
        {
            reflectionFee: 500,
            liquidityFee: 200,
            teamFee: 0,
            marketingFee: 2100,
            burnFee: 200
        });
        p2pFees = FeeInfo(
        {
            reflectionFee: 0,
            liquidityFee: 0,
            teamFee: 0,
            marketingFee: 0,
            burnFee: 0
        });
    }   

    //========================
    // GENERAL FUNCTIONS
    //========================   

    //to receive BNB from router when swapping
    receive() external payable {}  
    
    function allowance(address _owner, address _spender) public view override returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool)
    {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool)
    {
        require(allowances[msg.sender][_spender] >= _subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].sub(_subtractedValue));
        return true;
    }    

    function _approve(address _owner, address _spender, uint256 _amount) private        
    {
        //check
        preventBlacklisted(_owner, "Owner address is blacklisted");
        preventBlacklisted(_spender, "Spender address is blacklisted");
        require(_owner != address(0), "BEP20: approve from the zero address");
        require(_spender != address(0), "BEP20: approve to the zero address");

        //approve
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    } 

    function preventBlacklisted(address _account, string memory _errorMsg) private view
    {
        UserInfo storage user = userMap[_account];
        require(!user.blacklisted, _errorMsg);
    }

    function getCurrentSupply() private view returns(uint256, uint256)
    {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        for (uint256 n = 0; n < excluded.length; n++)
        {
            UserInfo storage user = userMap[excluded[n]];
            if (user.rOwned > rSupply
                || user.tOwned > tSupply)
            {
                return (rTotal, tTotal);
            }

            //reduce by excluded            
            rSupply = rSupply.sub(user.rOwned);
            tSupply = tSupply.sub(user.tOwned);
        }

        if (rSupply < rTotal.div(tTotal))
        {
            return (rTotal, tTotal);
        }
        return (rSupply, tSupply);
    }

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function setMaxFee(uint256 _fee) external onlyOwner
    {
        //initial check
        require(_fee < maxFee, "Fee must be lower than current");
        require(_fee >= 1000, "Fee must be at least 10%");        

        maxFee = _fee;

        //valid fees check
        checkFees(getFees(0));
        checkFees(getFees(-1));
        checkFees(getFees(1));
    }

    function setMinTokenAmount(uint256 _tokens) external onlyOwner
    {
        minRemainingTokens = _tokens;
    } 

    function setSwapTokensAtAmount(uint256 _low, uint256 _high) external onlyOwner
    {
        require(_high > _low, "High must be more than low");
        swapTokensAtLow = _low;
        swapTokensAtHigh = _high;
    }

    function setReflectionFee(int8 _feeType, uint256 _fee) external onlyOwner
    {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, _fee, fees.liquidityFee, fees.teamFee, fees.marketingFee, fees.burnFee);
    }

    function setLiquidityFee(int8 _feeType, uint256 _fee) external onlyOwner
    {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, _fee, fees.teamFee, fees.marketingFee, fees.burnFee);
    }

    function setTeamFee(int8 _feeType, uint256 _fee) external onlyOwner
    {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, _fee, fees.marketingFee, fees.burnFee);
    }

    function setMarketingFee(int8 _feeType, uint256 _fee) external onlyOwner
    {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, fees.teamFee, _fee, fees.burnFee);
    }

    function setBurnFee(int8 _feeType, uint256 _fee) external onlyOwner
    {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, fees.teamFee, fees.marketingFee, _fee);
    }

    function setAllFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee) external onlyOwner
    {
        setFees(_feeType, _reflectionFee, _liquidityFee, _teamFee, _marketingFee, _burnFee);        
    }

    function setTeamFeeAddress(address _address) external onlyOwner
    {
        require(_address != address(0), "Address Zero is not allowed");
        excludeFromReward(_address);
        teamFeeAddress = _address;
    }

    function setMarketingFeeAddress(address _address) external onlyOwner
    {
        require(_address != address(0), "Address Zero is not allowed");
        excludeFromReward(_address);
        marketingFeeAddress = _address;
    }

    function updateRouterAndPair(IUniRouterV2 _router, IERC20 _routerPair) public onlyOwner
    {
        if (router != _router)
        {
            router = _router;
            excludeFromReward(address(router));
        }
        if (routerPair != _routerPair)
        {
            routerPair = _routerPair;
            excludeFromReward(address(routerPair));
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner
    {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //========================
    // USER CONFIG FUNCTIONS
    //========================  

    function excludeFromFee(address _account) public onlyOwner
    {
        UserInfo storage user = userMap[_account];
        user.excludedFromFee = true;
    }

    function includeInFee(address _account) public onlyOwner
    {        
        UserInfo storage user = userMap[_account];
        user.excludedFromFee = false;
    }

    function blacklistAddress(address _account) public onlyOwner
    {
        UserInfo storage user = userMap[_account];
        user.blacklisted = true;
    }

    function unBlacklistAddress(address _account) public onlyOwner
    {
        UserInfo storage user = userMap[_account];
        user.blacklisted = false;
    }   

    function excludeFromReward(address _account) public onlyOwner
    {
        //check
        UserInfo storage user = userMap[_account];
        require(!user.excludedFromReward, "Account is already excluded");

        //exclude
        if (user.rOwned > 0)
        {
            user.tOwned = tokenFromReflection(user.rOwned);
        }
        user.excludedFromReward = true;
        excluded.push(_account);
    }

    function includeInReward(address _account) external onlyOwner
    {
        //check
        UserInfo storage user = userMap[_account];
        require(user.excludedFromReward, "Account is already included");

        //include
        for (uint256 n = 0; n < excluded.length; n++)
        {
            if (excluded[n] == _account)
            {
                excluded[n] = excluded[excluded.length - 1];
                user.tOwned = 0;
                user.excludedFromReward = false;
                excluded.pop();
                break;
            }
        }
    }

    //========================
    // USER INFO FUNCTIONS
    //======================== 

    function isExcludedFromFee(address _account) public view returns (bool)
    {
        UserInfo storage user = userMap[_account];
        return user.excludedFromFee;
    }

    function isBlacklisted(address _account) public view returns (bool)
    {
        UserInfo storage user = userMap[_account];
        return user.blacklisted;
    }

    function balanceOf(address _account) public view override returns (uint256)
    {
        UserInfo storage user = userMap[_account];
        if (user.excludedFromReward)
        {
            return user.tOwned;
        }
        return tokenFromReflection(user.rOwned);
    }

    function isExcludedFromReward(address _account) public view returns (bool)
    {
        UserInfo storage user = userMap[_account];
        return user.excludedFromReward;
    }

    //========================
    // INFO FUNCTIONS
    //======================== 
    
    function totalFees() public view returns (uint256)
    {
        return tFeeTotal;
    }

    function totalSupply() public view override returns (uint256)
    {
        return tTotal;
    }

    //========================
    // FEE FUNCTIONS
    //========================  

    function getSwapAmount() private returns (uint256)
    {
        uint256 pr = uint256(keccak256(abi.encodePacked(tx.origin, block.timestamp, nonce++)));
        return swapTokensAtLow.add(pr.mod(swapTokensAtHigh.sub(swapTokensAtLow)));
    }

    function manualProcessFees(uint256 _amount) external onlyOwner
    {
        processFees(_amount);
    }

    function processFees(uint256 _amount) private
    {
        //get fee shares
        uint256 accumulatedTotal = accumulatedLiquidityFee.add(accumulatedTeamFee).add(accumulatedMarketingFee);
        uint256 tokenForLiquidity = _amount.mul(accumulatedLiquidityFee).div(accumulatedTotal);
        uint256 tokenForMarketing = _amount.mul(accumulatedMarketingFee).div(accumulatedTotal);
        uint256 tokenForTeam = _amount.mul(accumulatedTeamFee).div(accumulatedTotal);
        uint256 liquidityHalf = tokenForLiquidity.div(2);
        uint256 liquidityHalfOther = tokenForLiquidity.sub(liquidityHalf);
        uint256 swapAmount = tokenForMarketing.add(tokenForMarketing).add(liquidityHalf);

        //deduct accumulated
        accumulatedLiquidityFee = accumulatedLiquidityFee.sub(tokenForLiquidity);
        accumulatedMarketingFee = accumulatedMarketingFee.sub(tokenForMarketing);
        accumulatedTeamFee = accumulatedTeamFee.sub(tokenForTeam);

        //lock
        inSwapAndLiquify = true;

        //swap tokens for BNB
        uint256 initialBalance = address(this).balance;
        swapForBNB(swapAmount);
        uint256 gainedBalance = address(this).balance.sub(initialBalance);        

        //process marketing fee
        uint256 bnbForMarketing = gainedBalance.mul(accumulatedMarketingFee).div(accumulatedTotal);
        payable(marketingFeeAddress).transfer(bnbForMarketing);

        //process team fee
        uint256 bnbForTeam = gainedBalance.mul(accumulatedTeamFee).div(accumulatedTotal);
        payable(teamFeeAddress).transfer(bnbForTeam);

        //process liquidity fee
        uint256 remainingGainedBalance = address(this).balance.sub(initialBalance); 
        addLiquidity(liquidityHalfOther, remainingGainedBalance);

        //unlock
        inSwapAndLiquify = false;
    }

    function takeFees(address _sender, FeeValues memory _values) private
    {
        //liquidity 
        takeFee(_sender, _values.tLiquidityFee, address(this));
        accumulatedLiquidityFee = accumulatedLiquidityFee.add(_values.tLiquidityFee);

        //team
        takeFee(_sender, _values.tTeamFee, address(this));
        accumulatedTeamFee = accumulatedTeamFee.add(_values.tTeamFee);

        //marketing
        takeFee(_sender, _values.tMarketingFee, address(this));
        accumulatedMarketingFee = accumulatedMarketingFee.add(_values.tMarketingFee);

        //burn
        takeBurn(_sender, _values.tBurnFee);
    }

    function takeFee(address _sender, uint256 _tAmount, address _recipient) private
    {
        if (_recipient == address(0)
            || _tAmount == 0)
        {
            return;
        }

        //take fee
        uint256 rAmount = _tAmount.mul(getRate());
        UserInfo storage user = userMap[_recipient];
        user.rOwned = user.rOwned.add(rAmount);
        if (user.excludedFromReward)
        {
            user.tOwned = user.tOwned.add(_tAmount);
        }        

        //event
        emit Transfer(_sender, _recipient, _tAmount);
    }

    function takeBurn(address sender, uint256 _amount) private
    {
        if (_amount == 0)
        {
            return;
        }

        //burn
        UserInfo storage user = userMap[BURN_ADDRESS];
        user.tOwned = user.tOwned.add(_amount);

        //event
        emit Transfer(sender, BURN_ADDRESS, _amount);
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256)
    {
        if (_fee == 0)
        {
            return 0;
        }
        return _amount.mul(_fee).div(PERCENT_FACTOR);
    }

    //========================
    // FEE HELPER FUNCTIONS
    //======================== 

    function checkFees(FeeInfo memory _info) private view
    {
        uint256 fees = _info.reflectionFee
        .add(_info.liquidityFee)
        .add(_info.teamFee)
        .add(_info.marketingFee)
        .add(_info.burnFee);

        require(fees <= maxFee, "Fees exceeded max limitation");
    }

    function getFees(int8 _feeType) private view returns (FeeInfo memory)
    {
        if (_feeType < 0)
        {
            return sellFees;
        }
        else if (_feeType > 0)
        {
            return buyFees;
        }
        return p2pFees;
    }

    function setFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee) internal
    {
        if (_feeType < 0)
        {
            //sell
            sellFees.reflectionFee  = _reflectionFee;
            sellFees.liquidityFee   = _liquidityFee;
            sellFees.teamFee        = _teamFee;
            sellFees.marketingFee   = _marketingFee;
            sellFees.burnFee        = _burnFee;
            checkFees(sellFees);         
        }
        else if (_feeType > 0)
        {
            //buy
            buyFees.reflectionFee   = _reflectionFee;
            buyFees.liquidityFee    = _liquidityFee;
            buyFees.teamFee         = _teamFee;
            buyFees.marketingFee    = _marketingFee;
            buyFees.burnFee         = _burnFee;
            checkFees(buyFees);              
        }
        else
        {
            //p2p
            p2pFees.reflectionFee   = _reflectionFee;
            p2pFees.liquidityFee    = _liquidityFee;
            p2pFees.teamFee         = _teamFee;
            p2pFees.marketingFee    = _marketingFee;
            p2pFees.burnFee         = _burnFee;
            checkFees(p2pFees);   
        }      

        //event
        emit ChangeFees(_feeType, _reflectionFee, _liquidityFee, _teamFee, _marketingFee, _burnFee);
    }
   
    //========================
    // LIQUIDITY FUNCTIONS
    //========================  

    function swapForBNB(uint256 _amount) private
    {
        //swap tokens for BNB        
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(_amount);
        uint256 newBalance = address(this).balance.sub(initialBalance);

        emit SwappedForBNB(_amount, newBalance);
    }

    function swapTokensForBNB(uint256 _amount) private
    {
        //path to wBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(wBNB);       

        //swap
        _approve(address(this), address(router), _amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount) private
    {
        //add the liquidity
        _approve(address(this), address(router), _tokenAmount);
        router.addLiquidityETH{value: _bnbAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //========================
    // REFLECTION FUNCTIONS
    //========================    
    
    function getValues(uint256 _tAmount, FeeInfo memory _fees) private view returns (FeeValues memory)
    {
        tFeeValues memory tValues = getTValues(_tAmount, _fees);
        uint256 tTransferFee = tValues.tLiquidityFee.add(tValues.tTeamFee).add(tValues.tMarketingFee).add(tValues.tBurnFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(_tAmount, tValues.tReflectionFee, tTransferFee, getRate());
        return FeeValues(
        {
            rAmount: rAmount,
            rTransferAmount: rTransferAmount,
            rFee: rFee,
            
            tTransferAmount: tValues.tTransferAmount,
            tReflectionFee: tValues.tReflectionFee,
            tLiquidityFee: tValues.tLiquidityFee,
            tTeamFee: tValues.tTeamFee,
            tMarketingFee: tValues.tMarketingFee,
            tBurnFee: tValues.tBurnFee
        });
    }

    function getTValues(uint256 _tAmount, FeeInfo memory _fees) private pure returns (tFeeValues memory)
    {
        tFeeValues memory tValues = tFeeValues(
        {
            tTransferAmount: 0,
            tReflectionFee: calculateFee(_tAmount, _fees.reflectionFee),
            tLiquidityFee: calculateFee(_tAmount, _fees.liquidityFee),
            tTeamFee: calculateFee(_tAmount, _fees.teamFee),
            tMarketingFee: calculateFee(_tAmount, _fees.marketingFee),
            tBurnFee: calculateFee(_tAmount, _fees.burnFee)
        });

        tValues.tTransferAmount = _tAmount.sub(tValues.tReflectionFee).sub(tValues.tLiquidityFee).sub(tValues.tTeamFee).sub(tValues.tMarketingFee).sub(tValues.tBurnFee);
        return tValues;
    }

    function getRValues(uint256 _tAmount, uint256 _tFee, uint256 _tTransferFee, uint256 _currentRate) private pure returns (uint256, uint256, uint256)
    {
        uint256 rAmount = _tAmount.mul(_currentRate);
        uint256 rFee = _tFee.mul(_currentRate);
        uint256 rTransferFee = _tTransferFee.mul(_currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTransferFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() private view returns(uint256)
    {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function tokenFromReflection(uint256 _rAmount) public view returns (uint256)
    {
        require(_rAmount <= rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getRate();
        return _rAmount.div(currentRate);
    }

    function reflectFee(uint256 _rFee, uint256 _tFee) private
    {
        rTotal = rTotal.sub(_rFee);
        tFeeTotal = tFeeTotal.add(_tFee);
    }   

    //========================
    // TRANSFER FUNCTIONS
    //========================    

    function getTransferAmount(uint256 _amount, address _from) private view returns (uint256)
    {
        uint256 transferAmount = _amount;
        if (_from != address(router)
            && _from != address(routerPair)
            && _from != address(this))
        {
            uint256 maxTransferAmount = balanceOf(_from);
            maxTransferAmount = (maxTransferAmount > minRemainingTokens ? maxTransferAmount.sub(minRemainingTokens) : 0);
            if (transferAmount > maxTransferAmount)
            {
                transferAmount = maxTransferAmount;
            }
        }

        return transferAmount;
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    } 

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool)
    {
        //check
        require(allowances[_sender][msg.sender] >= _amount, "BEP20: transfer amount exceeds allowance");

        //transfer and change allowance
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender].sub(_amount));

        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) private
    {
        //check
        preventBlacklisted(msg.sender, "Address is blacklisted");
        preventBlacklisted(_from, "From address is blacklisted");
        preventBlacklisted(_to, "To address is blacklisted");
        require(_from != address(0), "BEP20: transfer from the zero address");
        require(_to != address(0), "BEP20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        //check transfer amount
        uint256 transferAmount = getTransferAmount(_amount, _from);
        require(transferAmount > 0, "Balance must be greater than minimum allowed balance");

        //swap if balance > swapTokensAtHigh and prevent recursive call
        uint256 contractTokenBalance = balanceOf(address(this));
        if (swapAndLiquifyEnabled
            && contractTokenBalance >= swapTokensAtHigh
            && !inSwapAndLiquify
            && _from != address(routerPair)
            && _to == address(routerPair))
        {
            processFees(getSwapAmount());
        }

        //if any account is excluded from fee, remove fee
        bool takeFeeOnTransfer = true;
        if (isExcludedFromFee(_from)
            || isExcludedFromFee(_to))
        {
            takeFeeOnTransfer = false;
        }

        //get fee
        FeeInfo memory fees = emptyFees;
        if (takeFeeOnTransfer)        
        {
            if (_from == address(routerPair))
            {
                fees = buyFees;
            }
            else if (_to == address(routerPair))
            {
                fees = sellFees;
            }
            else
            {
                fees = p2pFees;
            }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        tokenTransfer(_from, _to, transferAmount, fees);
    }    

    function tokenTransfer(address _sender, address _recipient, uint256 _amount, FeeInfo memory _fees) private
    {
        bool senderExcluded = isExcludedFromReward(_sender);
        bool recipientExcluded = isExcludedFromReward(_recipient);

        if (senderExcluded
            && !recipientExcluded)
        {
            transferFromExcluded(_sender, _recipient, _amount, _fees);
        }
        else if (!senderExcluded
            && recipientExcluded)
        {
            transferToExcluded(_sender, _recipient, _amount, _fees);
        }
        else if (senderExcluded
            && recipientExcluded)
        {
            transferBothExcluded(_sender, _recipient, _amount, _fees);
        }
        else
        {
            transferStandard(_sender, _recipient, _amount, _fees);
        }
    }

    function transferBothExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private
    {
        //get values
        FeeValues memory values = getValues(_tAmount, _fees);

        //sender
        UserInfo storage userSender = userMap[_sender];
        userSender.tOwned = userSender.tOwned.sub(_tAmount);
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);

        //recipient
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.tOwned = userRecipient.tOwned.add(values.tTransferAmount);
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);

        //fees and reflection
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);

        //event
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }

    function transferStandard(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private
    {
        //get values
        FeeValues memory values = getValues(_tAmount, _fees);

        //sender
        UserInfo storage userSender = userMap[_sender];
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);

        //recipient
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);

        //fees and reflection
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);

        //event
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }

    function transferToExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private
    {
        //get values
        FeeValues memory values = getValues(_tAmount, _fees);

        //sender
        UserInfo storage userSender = userMap[_sender];
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);

        //recipient
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.tOwned = userRecipient.tOwned.add(values.tTransferAmount);
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);

        //fees and reflection
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);

        //event
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }

    function transferFromExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private
    {
        //get values
        FeeValues memory values = getValues(_tAmount, _fees);

        //sender
        UserInfo storage userSender = userMap[_sender];
        userSender.tOwned = userSender.tOwned.sub(_tAmount);
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);

        //recipient
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);

        //fees and reflection
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);

        //event
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }   
}