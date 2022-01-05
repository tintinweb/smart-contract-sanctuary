/**
 *Submitted for verification at snowtrace.io on 2022-01-04
*/

// SPDX-License-Identifier: UNLICENSED
// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/math/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File contracts/interfaces/IBakeryPair.sol

pragma solidity ^0.8.0;

interface IBakeryPair {
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

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;
}


// File contracts/interfaces/IDODOV2.sol


pragma solidity ^0.8.0;

interface IDODOV2 {
    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function getVaultReserve()
        external
        view
        returns (uint256 baseReserve, uint256 quoteReserve);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);
}


// File contracts/interfaces/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}


// File contracts/interfaces/IVyperSwap.sol


pragma solidity ^0.8.0;

interface IVyperSwap {
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;
}


// File contracts/interfaces/IVyperUnderlyingSwap.sol


pragma solidity ^0.8.0;

interface IVyperUnderlyingSwap {
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange_underlying(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;
}


// File contracts/interfaces/IDoppleSwap.sol


pragma solidity ^0.8.0;

interface IDoppleSwap {
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}


// File contracts/interfaces/IDODOV2Proxy.sol


pragma solidity ^0.8.0;

interface IDODOV2Proxy {
    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}


// File contracts/interfaces/IBalancer.sol


pragma solidity ^0.8.0;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

library Balancer {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }
}

interface IBalancerRouter {
    function swap(
        Balancer.SingleSwap memory singleSwap,
        Balancer.FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

interface IBalancerPool {
    function getPoolId() external view returns (bytes32);
}


// File contracts/interfaces/IArkenApprove.sol


pragma solidity ^0.8.0;

interface IArkenApprove {
    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function updateCallableAddress(address _callableAddress) external;
}


// File contracts/lib/OwnableUpgradeable.sol


pragma solidity ^0.8.0;

abstract contract OwnableUpgradeable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function ownableUpgradeableInitialize() internal {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/lib/UniswapV2Library.sol

pragma solidity ^0.8.0;


library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(
            reserveA > 0 && reserveB > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountAfterFee // 9970 = fee 0.3%
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(
            reserveIn > 0 && reserveOut > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        uint256 amountInWithFee = amountIn.mul(amountAfterFee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountAfterFee // 9970 = fee 0.3%
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(
            reserveIn > 0 && reserveOut > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(amountAfterFee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        uint256 amountAfterFee
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                amountAfterFee
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        uint256 amountAfterFee
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                amountAfterFee
            );
        }
    }
}


// File contracts/ArkenDexV3.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
















contract ArkenDexV3 is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 public constant _DEADLINE_ = 2**256 - 1;
    address public constant _ETH_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public _FEE_WALLET_ADDR_;
    address public _DODO_APPROVE_ADDR_;
    address public _WETH_;
    address public _WETH_DFYN_;
    address public _ARKEN_APPROVE_;

    /*
    ==============================================================================

    █▀▀ █░█ █▀▀ █▄░█ ▀█▀ █▀
    ██▄ ▀▄▀ ██▄ █░▀█ ░█░ ▄█

    ==============================================================================
    */
    event Swapped(
        address srcToken,
        address dstToken,
        uint256 amountIn,
        uint256 returnAmount
    );
    event FeeWalletUpdated(address newFeeWallet);
    event WETHUpdated(address newWETH);
    event WETHDfynUpdated(address newWETHDfyn);
    event DODOApproveUpdated(address newDODOApproveAddress);
    event ArkenApproveUpdated(address newArkenApproveAddress);

    /*
    ==============================================================================

    █▀▀ █▀█ █▄░█ █▀▀ █ █▀▀ █░█ █▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█ █▀
    █▄▄ █▄█ █░▀█ █▀░ █ █▄█ █▄█ █▀▄ █▀█ ░█░ █ █▄█ █░▀█ ▄█

    ==============================================================================
    */
    constructor(
        address _ownerAddress,
        address payable _feeWalletAddress,
        address _wrappedEther,
        address _wrappedEtherDfyn,
        address _dodoApproveAddress,
        address _arkenApprove
    ) {
        transferOwnership(_ownerAddress);
        _FEE_WALLET_ADDR_ = _feeWalletAddress;
        _DODO_APPROVE_ADDR_ = _dodoApproveAddress;
        _WETH_ = _wrappedEther;
        _WETH_DFYN_ = _wrappedEtherDfyn;
        _ARKEN_APPROVE_ = _arkenApprove;
    }

    receive() external payable {}

    fallback() external payable {}

    function updateFeeWallet(address payable _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), 'fee wallet zero address');
        _FEE_WALLET_ADDR_ = _feeWallet;
        emit FeeWalletUpdated(_FEE_WALLET_ADDR_);
    }

    function updateWETH(address _weth) external onlyOwner {
        require(_weth != address(0), 'WETH zero address');
        _WETH_ = _weth;
        emit WETHUpdated(_WETH_);
    }

    function updateWETHDfyn(address _weth_dfyn) external onlyOwner {
        require(_weth_dfyn != address(0), 'WETH dfyn zero address');
        _WETH_DFYN_ = _weth_dfyn;
        emit WETHDfynUpdated(_WETH_DFYN_);
    }

    function updateDODOApproveAddress(address _dodoApproveAddress)
        external
        onlyOwner
    {
        require(_dodoApproveAddress != address(0), 'dodo approve zero address');
        _DODO_APPROVE_ADDR_ = _dodoApproveAddress;
        emit DODOApproveUpdated(_DODO_APPROVE_ADDR_);
    }

    function updateArkenApprove(address _arkenApprove) external onlyOwner {
        require(_arkenApprove != address(0), 'arken approve zero address');
        _ARKEN_APPROVE_ = _arkenApprove;
        emit ArkenApproveUpdated(_ARKEN_APPROVE_);
    }

    /*
    ==================================================================================

    ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░   ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░   ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░
    ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄   ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄   ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄

    ==================================================================================
    */

    enum RouterInterface {
        UNISWAP_V2,
        BAKERY,
        VYPER,
        VYPER_UNDERLYING,
        DOPPLE,
        DODO_V2,
        DODO_V1,
        DFYN,
        BALANCER
    }
    struct TradeRoute {
        address routerAddress;
        address lpAddress;
        address fromToken;
        address toToken;
        address from;
        address to;
        uint32 part;
        uint8 direction; // DODO
        int16 fromTokenIndex; // Vyper
        int16 toTokenIndex; // Vyper
        uint16 amountAfterFee; // 9970 = fee 0.3% -- 10000 = no fee
        RouterInterface dexInterface; // uint8
    }
    struct TradeDescription {
        address srcToken;
        address dstToken;
        uint256 amountIn;
        uint256 amountOutMin;
        address payable to;
        TradeRoute[] routes;
        bool isRouterSource;
        bool isSourceFee;
    }

    function trade(TradeDescription memory desc) external payable {
        require(desc.amountIn > 0, 'Amount-in needs to be more than zero');
        if (_ETH_ == desc.srcToken) {
            require(
                desc.amountIn == msg.value,
                'Ether value not match amount-in'
            );
            require(
                desc.isRouterSource,
                'Source token Ether requires isRouterSource=true'
            );
        }

        uint256 beforeDstAmt = _getBalance(desc.dstToken, desc.to);

        uint256 returnAmount = _trade(desc);

        if (returnAmount > 0) {
            if (_ETH_ == desc.dstToken) {
                (bool sent, ) = desc.to.call{value: returnAmount}('');
                require(sent, 'Failed to send Ether');
            } else {
                IERC20(desc.dstToken).safeTransfer(desc.to, returnAmount);
            }
        }

        uint256 receivedAmt = _getBalance(desc.dstToken, desc.to).sub(
            beforeDstAmt
        );
        require(
            receivedAmt >= desc.amountOutMin,
            'Received token is not enough'
        );

        emit Swapped(desc.srcToken, desc.dstToken, desc.amountIn, receivedAmt);
    }

    function _trade(TradeDescription memory desc)
        internal
        returns (uint256 returnAmount)
    {
        if (desc.isSourceFee) {
            if (_ETH_ == desc.srcToken) {
                _collectFee(desc.amountIn, desc.srcToken);
            } else {
                uint256 fee = _calculateFee(desc.amountIn);
                require(fee < desc.amountIn, 'Fee exceeds amount');
                _transferFromSender(
                    desc.srcToken,
                    _FEE_WALLET_ADDR_,
                    fee,
                    desc.srcToken
                );
            }
        }
        if (desc.isRouterSource && _ETH_ != desc.srcToken) {
            _transferFromSender(
                desc.srcToken,
                address(this),
                _getAmountInForTrade(desc),
                desc.srcToken
            );
        }
        if (_ETH_ == desc.srcToken) {
            _wrapEther(_WETH_, address(this).balance);
        }

        for (uint256 i = 0; i < desc.routes.length; i++) {
            _tradeRoute(desc.routes[i], desc);
        }

        if (_ETH_ == desc.dstToken) {
            returnAmount = IERC20(_WETH_).balanceOf(address(this));
            _unwrapEther(_WETH_, returnAmount);
        } else {
            returnAmount = IERC20(desc.dstToken).balanceOf(address(this));
        }
        if (!desc.isSourceFee) {
            require(
                returnAmount >= desc.amountOutMin,
                'Return amount is not enough'
            );
            returnAmount = _collectFee(returnAmount, desc.dstToken);
        }
    }

    /*

    █▀▄ █▀▀ ▀▄▀
    █▄▀ ██▄ █░█

    */

    function _tradeRoute(TradeRoute memory route, TradeDescription memory desc)
        internal
    {
        require(
            route.part <= 100000000,
            'Route percentage can not exceed 100000000'
        );
        require(
            route.fromToken != _ETH_ && route.toToken != _ETH_,
            'TradeRoute from/to token cannot be Ether'
        );
        if (route.from == address(1)) {
            require(
                route.fromToken == desc.srcToken,
                'Cannot transfer token from msg.sender'
            );
        }
        uint256 amountIn;
        if (route.from == address(0) || desc.srcToken == _ETH_) {
            amountIn = IERC20(
                route.fromToken == _WETH_DFYN_ ? _WETH_ : route.fromToken
            ).balanceOf(address(this)).mul(route.part).div(100000000);
        } else if (route.from == address(1)) {
            amountIn = _getAmountInForTrade(desc).mul(route.part).div(
                100000000
            );
        }
        if (route.dexInterface == RouterInterface.UNISWAP_V2) {
            _tradeUniswapV2(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.BAKERY) {
            _tradeBakery(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.DODO_V2) {
            _tradeDODOV2(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.DODO_V1) {
            _tradeDODOV1(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.DFYN) {
            _tradeDfyn(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.VYPER) {
            _tradeVyper(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.VYPER_UNDERLYING) {
            _tradeVyperUnderlying(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.DOPPLE) {
            _tradeDopple(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.BALANCER) {
            _tradeBalancer(route, amountIn, desc);
        } else {
            require(false, 'unknown router interface');
        }
    }

    function _tradeUniswapV2(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory desc
    ) internal {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken
            );
        }
        IUniswapV2Pair pair = IUniswapV2Pair(route.lpAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveFrom, uint256 reserveTo) = route.fromToken ==
            pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        amountIn = IERC20(route.fromToken).balanceOf(route.lpAddress).sub(
            reserveFrom
        );
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveFrom,
            reserveTo,
            route.amountAfterFee
        );
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (route.toToken == pair.token0()) {
            pair.swap(amountOut, 0, to, '');
        } else {
            pair.swap(0, amountOut, to, '');
        }
    }

    function _tradeDfyn(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory desc
    ) internal {
        if (route.fromToken == _WETH_DFYN_) {
            _unwrapEther(_WETH_, amountIn);
            _wrapEther(_WETH_DFYN_, amountIn);
        }
        _tradeUniswapV2(route, amountIn, desc);
        if (route.toToken == _WETH_DFYN_) {
            uint256 amountOut = IERC20(_WETH_DFYN_).balanceOf(address(this));
            _unwrapEther(_WETH_DFYN_, amountOut);
            _wrapEther(_WETH_, amountOut);
        }
    }

    function _tradeBakery(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory desc
    ) internal {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken
            );
        }
        IBakeryPair pair = IBakeryPair(route.lpAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveFrom, uint256 reserveTo) = route.fromToken ==
            pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        amountIn = IERC20(route.fromToken).balanceOf(route.lpAddress).sub(
            reserveFrom
        );
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveFrom,
            reserveTo,
            route.amountAfterFee
        );
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (route.toToken == pair.token0()) {
            pair.swap(amountOut, 0, to);
        } else {
            pair.swap(0, amountOut, to);
        }
    }

    function _tradeDODOV2(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory desc
    ) internal {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken
            );
        }
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (IDODOV2(route.lpAddress)._BASE_TOKEN_() == route.fromToken) {
            IDODOV2(route.lpAddress).sellBase(to);
        } else {
            IDODOV2(route.lpAddress).sellQuote(to);
        }
    }

    function _tradeDODOV1(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory
    ) internal {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, _DODO_APPROVE_ADDR_, amountIn);
        address[] memory dodoPairs = new address[](1);
        dodoPairs[0] = route.lpAddress;
        IDODOV2Proxy(route.routerAddress).dodoSwapV1(
            route.fromToken,
            route.toToken,
            amountIn,
            1,
            dodoPairs,
            route.direction,
            false,
            _DEADLINE_
        );
    }

    function _tradeVyper(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory
    ) internal {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IVyperSwap(route.routerAddress).exchange(
            route.fromTokenIndex,
            route.toTokenIndex,
            amountIn,
            0
        );
    }

    function _tradeVyperUnderlying(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory
    ) internal {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IVyperUnderlyingSwap(route.routerAddress).exchange_underlying(
            route.fromTokenIndex,
            route.toTokenIndex,
            amountIn,
            0
        );
    }

    function _tradeDopple(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory
    ) internal {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IDoppleSwap doppleSwap = IDoppleSwap(route.routerAddress);
        uint8 tokenIndexFrom = doppleSwap.getTokenIndex(route.fromToken);
        uint8 tokenIndexTo = doppleSwap.getTokenIndex(route.toToken);
        doppleSwap.swap(tokenIndexFrom, tokenIndexTo, amountIn, 0, _DEADLINE_);
    }

    function _tradeBalancer(
        TradeRoute memory route,
        uint256 amountIn,
        TradeDescription memory
    ) internal {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IBalancerRouter(route.routerAddress).swap(
            Balancer.SingleSwap({
                poolId: IBalancerPool(route.lpAddress).getPoolId(),
                kind: Balancer.SwapKind.GIVEN_IN,
                assetIn: IAsset(route.fromToken),
                assetOut: IAsset(route.toToken),
                amount: amountIn,
                userData: '0x'
            }),
            Balancer.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(this),
                toInternalBalance: false
            }),
            0,
            _DEADLINE_
        );
    }

    /*

    █▀▀ █▀█ █░░ █░░ █▀▀ █▀▀ ▀█▀   █▀▀ █▀▀ █▀▀
    █▄▄ █▄█ █▄▄ █▄▄ ██▄ █▄▄ ░█░   █▀░ ██▄ ██▄

    */

    function _collectFee(uint256 amount, address token)
        internal
        returns (uint256 remainingAmount)
    {
        uint256 fee = _calculateFee(amount);
        require(fee < amount, 'Fee exceeds amount');
        remainingAmount = amount.sub(fee);
        if (_ETH_ == token) {
            (bool sent, ) = _FEE_WALLET_ADDR_.call{value: fee}('');
            require(sent, 'Failed to send Ether too fee');
        } else {
            IERC20(token).safeTransfer(_FEE_WALLET_ADDR_, fee);
        }
    }

    function _calculateFee(uint256 amount) internal pure returns (uint256 fee) {
        return amount.div(1000); // 0.1%
    }

    function _getAmountInForTrade(TradeDescription memory desc)
        internal
        pure
        returns (uint256 amountIn)
    {
        if (!desc.isSourceFee) return desc.amountIn;
        return desc.amountIn.sub(_calculateFee(desc.amountIn));
    }

    // internal functions

    function _transferFromSender(
        address token,
        address to,
        uint256 amount,
        address srcToken
    ) internal {
        if (srcToken != _ETH_) {
            IArkenApprove(_ARKEN_APPROVE_).transferToken(
                address(token),
                msg.sender,
                to,
                amount
            );
        } else if (srcToken == _ETH_) {
            _wrapEther(_WETH_, amount);
            if (to != address(this)) {
                SafeERC20.safeTransfer(IERC20(_WETH_), to, amount);
            }
        }
    }

    function _wrapEther(address weth, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
    }

    function _unwrapEther(address weth, uint256 amount) internal {
        IWETH(weth).withdraw(amount);
    }

    function _increaseAllowance(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (amount > allowance) {
            uint256 increaseAmount = MAX_INT.sub(allowance);
            IERC20(token).safeIncreaseAllowance(spender, increaseAmount);
        }
    }

    function _getBalance(address token, address account)
        internal
        view
        returns (uint256)
    {
        if (_ETH_ == token) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /*

    █▀▄ █▀▀ █░█
    █▄▀ ██▄ ▀▄▀

    */
    function testTransfer(TradeDescription memory desc)
        external
        payable
        returns (uint256 returnAmount)
    {
        IERC20 dstToken = IERC20(desc.dstToken);
        returnAmount = _trade(desc);
        uint256 beforeAmount = dstToken.balanceOf(desc.to);
        dstToken.safeTransfer(desc.to, returnAmount);
        uint256 afterAmount = dstToken.balanceOf(desc.to);
        uint256 got = afterAmount.sub(beforeAmount);
        require(got == returnAmount, 'ArkenTester: Has Tax');
    }
}