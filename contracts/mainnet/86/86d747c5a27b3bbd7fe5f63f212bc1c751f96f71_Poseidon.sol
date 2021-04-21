/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

/*
    The farming contract
    riptide.finance

    MasterChef
    + restaking rewards
    + dual toggled token rewards

    Thanks sushiswap, surf, niceee, dracula.

    @nightg0at
    SPDX-License-Identifier: MIT
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// File: @openzeppelin/contracts/GSN/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/ds-math/math.sol

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// GPL-3.0-or-later

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: contracts/restaking/interfaces/IStakingAdapter.sol

/*
  The interface for any of our staking adapters

  @nightg0at
*/

pragma solidity 0.6.12;

interface IStakingAdapter {
    function claim() external;
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function emergencyWithdraw() external;
    function rewardTokenAddress() external view returns(address);
    function lpTokenAddress() external view returns(address);
    function pending() external view returns (uint256);
    function balance() external view returns (uint256);
}

// File: contracts/interfaces/ITideToken.sol

/*
  TideToken interface

  @nightg0at
*/

pragma solidity 0.6.12;


interface ITideToken is IERC20 {
  function owner() external view returns (address);
  function mint(address _to, uint256 _amount) external;
  function setParent(address _newConfig) external;
  function wipeout(address _recipient, uint256 _amount) external;
}

// File: contracts/Poseidon.sol



pragma solidity 0.6.12;

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Poseidon is Ownable, DSMath {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 tidalRewardDebt; // Reward debt. See explanation below.
        uint256 riptideRewardDebt; // Reward debt. See explanation below.
        uint256 otherRewardDebt;
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 withdrawFee; // Amount of LP liquidated on withdraw (often 0)
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accTidalPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
        uint256 accRiptidePerShare; // Accumulated SUSHIs per share, times 1e12. See below.
        uint256 accOtherPerShare; // Accumulated OTHERs per share, times 1e12. See below.
        IStakingAdapter adapter; // Manages external farming
        IERC20 otherToken; // The OTHER reward token for this pool, if any
    }

    IUniswapV2Router02 router;

    ITideToken public tidal;
    ITideToken public riptide;

    // Dev address.
    address public devaddr;
    // Fee address
    address public feeaddr;
    // Reward tokens created per block.
    uint256 public baseRewardPerBlock = 2496e11; // base reward token emission (0.0002496)
    uint256 public devDivisor = 238; // dev fund of 4.2%, 1000/238 = 4.20168...

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;

    // Don't add the same pool twice
    mapping (address => bool) private poolIsAdded;

    // Tide phase. The address of either tidal or riptide. Tidal to start
    address public phase;
    uint256 public constant TIDAL_CAP = 69e18;
    uint256 public constant TIDAL_VERTEX = 42e18;

    // weather
    bool public stormy = false;
    uint256 public stormDivisor = 2;

    // weather god
    address public zeus;

    // surf and whirlpool
    address public surf;
    address public whirlpool;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IUniswapV2Router02 _router,
        ITideToken _tidal,
        ITideToken _riptide,
        address _surf, // 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c
        address _whirlpool, // 0x999b1e6EDCb412b59ECF0C5e14c20948Ce81F40b
        address _devaddr,
        uint256 _startBlock
    ) public {
        router = _router;
        tidal = _tidal;
        riptide = _riptide;
        surf = _surf;
        whirlpool = _whirlpool;
        devaddr = _devaddr;
        feeaddr = _devaddr;
        startBlock = _startBlock;
        phase = address(_tidal);
    }

    // rudimentary checks for the staking adapter
    modifier validAdapter(IStakingAdapter _adapter) {
        require(address(_adapter) != address(0), "no adapter specified");
        require(_adapter.rewardTokenAddress() != address(0), "no other reward token specified in staking adapter");
        require(_adapter.lpTokenAddress() != address(0), "no staking token specified in staking adapter");
        _;
    }

    modifier onlyZeus() {
        require(msg.sender == zeus, "only zeus can call this method");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // This is assumed to not be a restaking pool.
    // Restaking can be added later or with addWithRestaking() instead of add()
    function add(uint256 _allocPoint, IERC20 _lpToken, uint256 _withdrawFee, bool _withUpdate) public onlyOwner {
        require(poolIsAdded[address(_lpToken)] == false, 'add: pool already added');
        poolIsAdded[address(_lpToken)] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            withdrawFee: _withdrawFee,
            lastRewardBlock: lastRewardBlock,
            accTidalPerShare: 0,
            accRiptidePerShare: 0,
            accOtherPerShare: 0,
            adapter: IStakingAdapter(0),
            otherToken: IERC20(0)
        }));
    }

    // Add a new lp to the pool that uses restaking. Can only be called by the owner.
    function addWithRestaking(uint256 _allocPoint, uint256 _withdrawFee, bool _withUpdate, IStakingAdapter _adapter) public onlyOwner validAdapter(_adapter) {
        IERC20 _lpToken = IERC20(_adapter.lpTokenAddress());

        require(poolIsAdded[address(_lpToken)] == false, 'add: pool already added');
        poolIsAdded[address(_lpToken)] = true;
        
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            withdrawFee: _withdrawFee,
            lastRewardBlock: lastRewardBlock,
            accTidalPerShare: 0,
            accRiptidePerShare: 0,
            accOtherPerShare: 0,
            adapter: _adapter,
            otherToken: IERC20(_adapter.rewardTokenAddress())
        }));
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set a new restaking adapter.
    function setRestaking(uint256 _pid, IStakingAdapter _adapter, bool _claim) public onlyOwner validAdapter(_adapter) {
        if (_claim) {
            updatePool(_pid);
        }
        if (isRestaking(_pid)) {
            withdrawRestakedLP(_pid);
        }
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) == _adapter.lpTokenAddress(), "LP mismatch");
        pool.accOtherPerShare = 0;
        pool.adapter = _adapter;
        pool.otherToken = IERC20(_adapter.rewardTokenAddress());

        // transfer LPs to new target if we have any
        uint256 poolBal = pool.lpToken.balanceOf(address(this));
        if (poolBal > 0) {
            pool.lpToken.safeTransfer(address(pool.adapter), poolBal);
            pool.adapter.deposit(poolBal);
        }
    }

    // remove restaking
    function removeRestaking(uint256 _pid, bool _claim) public onlyOwner {
        require(isRestaking(_pid), "not a restaking pool");
        if (_claim) {
            updatePool(_pid);
        }
        withdrawRestakedLP(_pid);
        poolInfo[_pid].adapter = IStakingAdapter(address(0));
        require(!isRestaking(_pid), "failed to remove restaking");
    }

    // should always be called with update unless prohibited by gas
    function setWeather(bool _isStormy, bool _withUpdate) public onlyZeus {
        if (_withUpdate) {
            massUpdatePools();
        }
        stormy = _isStormy;
    }

    function setWeatherConfig(address _newZeus, uint256 _newStormDivisor) public onlyOwner {
        require(_newStormDivisor != 0, "Cannot divide by zero");
        stormDivisor = _newStormDivisor;
        zeus = _newZeus; // can be address(0)
    }

    function setRewardPerBlock(uint256 _newReward) public onlyOwner {
        baseRewardPerBlock = _newReward;
    }

    // used if surf.finance upgrade their contracts
    function setSurfConfig(address _newSurf, address _newWhirlpool) public onlyOwner {
        surf = _newSurf;
        whirlpool = _newWhirlpool;
    }

    function _tokensPerBlock(address _tideToken) internal view returns (uint256) {
        if (phase == _tideToken) {
            if (stormy) {
                return baseRewardPerBlock.div(stormDivisor);
            } else {
                return baseRewardPerBlock;
            }
        } else {
            return 0;
        }
    }

    function tokensPerBlock(address _tideToken) external view returns (uint256) {
        return _tokensPerBlock(_tideToken);
    }

    // View function to see pending tide tokens on frontend.
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTidalPerShare = pool.accTidalPerShare;
        uint256 accRiptidePerShare = pool.accRiptidePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (isRestaking(_pid)) {
            lpSupply = pool.adapter.balance();
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // we don't have a bonus multiplier stage, so just work out the unclaimed blockspan
            uint256 span = block.number.sub(pool.lastRewardBlock);
            // get pending tokens if we are in phase
            uint256 pendingTidal = 0;
            uint256 pendingRiptide = 0;
            if (phase == address(tidal)) {
                pendingTidal = span.mul(_tokensPerBlock(address(tidal))).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (phase == address(riptide)) {
                pendingRiptide = span.mul(_tokensPerBlock(address(riptide))).mul(pool.allocPoint).div(totalAllocPoint);
            }
            accTidalPerShare = accTidalPerShare.add(pendingTidal.mul(1e12).div(lpSupply));
            accRiptidePerShare = accRiptidePerShare.add(pendingRiptide.mul(1e12).div(lpSupply));
        }
        uint256 unclaimedTidal = user.amount.mul(accTidalPerShare).div(1e12).sub(user.tidalRewardDebt);
        uint256 unclaimedRiptide = user.amount.mul(accRiptidePerShare).div(1e12).sub(user.riptideRewardDebt);
        return (unclaimedTidal, unclaimedRiptide);
    }

    // View function to see our pending OTHERs on frontend (whatever the restaked reward token is)
    function pendingOther(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOtherPerShare = pool.accOtherPerShare;
        uint256 lpSupply = pool.adapter.balance();
 
        if (lpSupply != 0) {
            uint256 otherReward = pool.adapter.pending();
            accOtherPerShare = accOtherPerShare.add(otherReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
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

        updatePhase();

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = getPoolSupply(_pid);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (isRestaking(_pid)) {
            uint256 pendingOtherTokens = pool.adapter.pending();
            if (pendingOtherTokens >= 0) {
                uint256 otherBalanceBefore = pool.otherToken.balanceOf(address(this));
                pool.adapter.claim();
                uint256 otherBalanceAfter = pool.otherToken.balanceOf(address(this));
                pendingOtherTokens = otherBalanceAfter.sub(otherBalanceBefore);
                pool.accOtherPerShare = pool.accOtherPerShare.add(pendingOtherTokens.mul(1e12).div(lpSupply));
            }
        }

        uint256 span = block.number.sub(pool.lastRewardBlock);
        if (phase == address(tidal)) {
            uint256 tidalReward = span.mul(_tokensPerBlock(address(tidal))).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 devTidalReward = tidalReward.mul(10).div(devDivisor);
            if (tidal.totalSupply().add(tidalReward).add(devTidalReward) > TIDAL_CAP) {
                // we would exceed the cap
                uint256 totalTidalReward = TIDAL_CAP.sub(tidal.totalSupply());
                // split proportionally
                uint256 newDevTidalReward = totalTidalReward.mul(10).div(devDivisor-10); // ~ reverse percentage approximation
                uint256 newTidalReward = totalTidalReward.sub(newDevTidalReward);
                tidal.mint(devaddr, newDevTidalReward); 
                tidal.mint(address(this), newTidalReward);
                pool.accTidalPerShare = pool.accTidalPerShare.add(newTidalReward.mul(1e12).div(lpSupply));

                uint256 totalRiptideReward = tidalReward.sub(totalTidalReward);
                uint256 newDevRiptideReward = totalRiptideReward.mul(10).div(devDivisor-10);
                uint256 newRiptideReward = totalRiptideReward.sub(newDevRiptideReward);
                riptide.mint(devaddr, newDevRiptideReward);
                riptide.mint(devaddr, newRiptideReward);
                pool.accRiptidePerShare = pool.accRiptidePerShare.add(newRiptideReward.mul(1e12).div(lpSupply));
            } else {
                tidal.mint(devaddr, devTidalReward); 
                tidal.mint(address(this), tidalReward);
                pool.accTidalPerShare = pool.accTidalPerShare.add(tidalReward.mul(1e12).div(lpSupply));
            }
        } else {
            uint256 riptideReward = span.mul(_tokensPerBlock(address(riptide))).mul(pool.allocPoint).div(totalAllocPoint);
            riptide.mint(devaddr, riptideReward.mul(10).div(devDivisor));
            riptide.mint(address(this), riptideReward);
            pool.accRiptidePerShare = pool.accRiptidePerShare.add(riptideReward.mul(1e12).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }

    // Internal view function to get the amount of LP tokens staked in the specified pool
    function getPoolSupply(uint256 _pid) internal view returns (uint256 lpSupply) {
        PoolInfo memory pool = poolInfo[_pid];
        if (isRestaking(_pid)) {
            lpSupply = pool.adapter.balance();
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
    }

    function isRestaking(uint256 _pid) public view returns (bool outcome) {
        if (address(poolInfo[_pid].adapter) != address(0)) {
            outcome = true;
        } else {
            outcome = false;
        }
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pendingOtherTokens = 0;
        if (user.amount > 0) {
            uint256 pendingTidal = user.amount.mul(pool.accTidalPerShare).div(1e12).sub(user.tidalRewardDebt);
            if(pendingTidal > 0) {
                safeTideTransfer(msg.sender, pendingTidal, tidal);
            }
            uint256 pendingRiptide = user.amount.mul(pool.accRiptidePerShare).div(1e12).sub(user.riptideRewardDebt);
            if(pendingRiptide > 0) {
                safeTideTransfer(msg.sender, pendingRiptide, riptide);
            }
            pendingOtherTokens = user.amount.mul(pool.accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (isRestaking(_pid)) {
                pool.lpToken.safeTransfer(address(pool.adapter), _amount);
                pool.adapter.deposit(_amount);
            }
            user.amount = user.amount.add(_amount);
        }
        // we can't guarantee we have the tokens until after adapter.deposit()
        if (pendingOtherTokens > 0) {
            safeOtherTransfer(msg.sender, pendingOtherTokens, _pid);
        }
        user.tidalRewardDebt = user.amount.mul(pool.accTidalPerShare).div(1e12);
        user.riptideRewardDebt = user.amount.mul(pool.accRiptidePerShare).div(1e12);
        user.otherRewardDebt = user.amount.mul(pool.accOtherPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }


    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pendingTidal = user.amount.mul(pool.accTidalPerShare).div(1e12).sub(user.tidalRewardDebt);
        if(pendingTidal > 0) {
            safeTideTransfer(msg.sender, pendingTidal, tidal);
        }
        uint256 pendingRiptide = user.amount.mul(pool.accRiptidePerShare).div(1e12).sub(user.riptideRewardDebt);
        if(pendingRiptide > 0) {
            safeTideTransfer(msg.sender, pendingRiptide, riptide);
        }
        uint256 pendingOtherTokens = user.amount.mul(pool.accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
        if(_amount > 0) {
            uint256 amount = _amount;
            user.amount = user.amount.sub(amount);
            if (isRestaking(_pid)) {
                pool.adapter.withdraw(amount);
            }
            if (pool.withdrawFee > 0) {
                uint256 fee = wmul(amount, pool.withdrawFee);
                amount = amount.sub(fee);
                processWithdrawFee(address(pool.lpToken), fee);
            }
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }
        //  we can't guarantee we have the tokens until after adapter.withdraw()
        if (pendingOtherTokens > 0) {
            safeOtherTransfer(msg.sender, pendingOtherTokens, _pid);
        }
        user.tidalRewardDebt = user.amount.mul(pool.accTidalPerShare).div(1e12);
        user.riptideRewardDebt = user.amount.mul(pool.accRiptidePerShare).div(1e12);
        user.otherRewardDebt = user.amount.mul(pool.accOtherPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function processWithdrawFee(address _lpToken, uint256 _fee) private {
        // get token addresses & balances
        address token0 = IUniswapV2Pair(_lpToken).token0();
        address token1 = IUniswapV2Pair(_lpToken).token1();

        // remove liquidity
        IERC20(_lpToken).approve(address(router), _fee);
        (uint256 token0Amount, uint256 token1Amount) = router.removeLiquidity(token0, token1, _fee, 0, 0, address(this), block.timestamp);
        IERC20(_lpToken).approve(address(router), 0);

        address[] memory surfPath = new address[](2);
        surfPath[1] = surf;

        // sell and transfer
        if (token0 == surf) {
            surfPath[0] = token1;
            router.swapExactTokensForTokens(
                token1Amount,
                0,
                surfPath,
                whirlpool,
                block.timestamp
            );
            IERC20(token0).transfer(whirlpool, token0Amount);
        } else if (token1 == surf) {
            surfPath[0] = token0;
            router.swapExactTokensForTokens(
                token0Amount,
                0,
                surfPath,
                whirlpool,
                block.timestamp
            );
            IERC20(token1).transfer(whirlpool, token1Amount);
        } else {
            // this is not a reward/surf pair. Transfer to fee wallet
            IERC20(token0).transfer(feeaddr, token0Amount);
            IERC20(token1).transfer(feeaddr, token1Amount);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.tidalRewardDebt = 0;
        user.riptideRewardDebt = 0;
        if (isRestaking(_pid)) {
            pool.adapter.withdraw(amount);
        }
        if (pool.withdrawFee > 0) {
            uint256 fee = wmul(amount, pool.withdrawFee);
            amount = amount.sub(fee);
            pool.lpToken.transfer(feeaddr, fee);
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Withdraw LP tokens from the restaking target back here
    // Does not claim rewards
    function withdrawRestakedLP(uint256 _pid) internal {
        require(isRestaking(_pid), "not a restaking pool");
        PoolInfo storage pool = poolInfo[_pid];
        uint lpBalanceBefore = pool.lpToken.balanceOf(address(this));
        pool.adapter.emergencyWithdraw();
        uint lpBalanceAfter = pool.lpToken.balanceOf(address(this));
        emit EmergencyWithdraw(address(pool.adapter), _pid, lpBalanceAfter.sub(lpBalanceBefore));
    }


    // Safe tide token transfer function, just in case if rounding error causes pool to not have enough tokens of type _tideToken
    function safeTideTransfer(address _to, uint256 _amount, ITideToken _tideToken) internal {
        uint256 tokenBal = _tideToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            _tideToken.transfer(_to, tokenBal);
        } else {
            _tideToken.transfer(_to, _amount);
        }
    }

    // as above but for any restaking token
    function safeOtherTransfer(address _to, uint256 _amount, uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 otherBal = pool.otherToken.balanceOf(address(this));
        if (_amount > otherBal) {
            pool.otherToken.transfer(_to, otherBal);
        } else {
            pool.otherToken.transfer(_to, _amount);
        }
    }

    // Update dev fee address
    function dev(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    // Set dev fee divisor
    function setNewDevDivisor(uint256 _newDivisor) public onlyOwner {
        require(_newDivisor >= 145, "Dev fee too high"); // ~6.9% max
        devDivisor = _newDivisor;
    }

    // Update withdraw fee recipient
    function fee(address _feeaddr) public onlyOwner {
        feeaddr = _feeaddr;
    }

    // transfer ownership from this contract to a new owner
    function transferTokenOwnership(address _owned, address _newOwner) public onlyOwner {
        Ownable(_owned).transferOwnership(_newOwner);
    }

    /*
        set a new tidal token
        before calling, ensure:
            tokens per block is set to 0 beforehand and reinstated afterwards
            this is the sibling of riptide
            poseidon is the owner
            poseidon's new and old tidal balances match
    */
    function setNewTidalToken(address _newTidal) public onlyOwner {
        require(ITideToken(_newTidal).owner() == address(this), "Poseidon not the owner");
        if (phase == address(tidal)) phase = _newTidal;
        tidal = ITideToken(_newTidal);
    }

    /*
        set a new riptide token
        before calling, see above
    */
    function setNewRiptideToken(address _newRiptide) public onlyOwner {
        require(ITideToken(_newRiptide).owner() == address(this), "Poseidon not the owner");
        if (phase == address(riptide)) phase = _newRiptide;
        riptide = ITideToken(_newRiptide);
    }

    // return the active reward token (the phase; either tide or riptide)
    function getPhase() public view returns (address) {
        return phase;
    }

    // called every pool update.
    function updatePhase() internal {
        if (phase == address(tidal) && tidal.totalSupply() >= TIDAL_CAP){
            phase = address(riptide);
        }
        else if (phase == address(riptide) && tidal.totalSupply() < TIDAL_VERTEX) {
            phase = address(tidal);
        }
    }

}