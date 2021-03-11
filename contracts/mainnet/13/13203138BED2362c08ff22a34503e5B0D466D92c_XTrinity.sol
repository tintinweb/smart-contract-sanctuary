/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/utils/SafeERC20.sol

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol


pragma solidity ^0.6.12;


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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token != IERC20(0)) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            require(
                from == msg.sender && msg.value >= amount,
                "msg.value is zero"
            );
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

// File: contracts/interfaces/IUniswapV2.sol


pragma solidity ^0.6.0;


interface IUniRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getPair(IERC20 tokenA, IERC20 tokenB)
        external
        view
        returns (IUniswapV2Exchange pair);
}

interface IUniswapV2Exchange {
    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    //function name() external pure returns (string memory);
    //function symbol() external pure returns (string memory);
    //function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    //function allowance(address owner, address spender) external view returns (uint);
    //function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);

    //function transferFrom(address from, address to, uint value) external returns (bool);
    //function DOMAIN_SEPARATOR() external view returns (bytes32);
    //function PERMIT_TYPEHASH() external pure returns (bytes32);
    //function nonces(address owner) external view returns (uint);

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    //event Mint(address indexed sender, uint amount0, uint amount1);
    //event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    /*event Swap(
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

function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    */
}

// File: contracts/utils/UniswapV2Lib.sol


pragma solidity ^0.6.12;



contract UniswapUtils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        //require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        //require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
}

library UniswapV2ExchangeLib {
    using SafeMath for uint256;

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getReturn(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amountIn
    )
        internal
        view
        returns (
            uint256 result,
            bool needSync,
            bool needSkim
        )
    {
        uint256 reserveIn = fromToken.balanceOf(address(exchange));
        uint256 reserveOut = destToken.balanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1, ) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(min(reserveOut, reserve1));
        uint256 denominator =
            min(reserveIn, reserve0).mul(1000).add(amountInWithFee);
        result = (denominator == 0) ? 0 : numerator.div(denominator);
    }
}

// File: contracts/interfaces/ICurve.sol


pragma solidity ^0.6.0;

abstract contract ICurveFiCurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function A() external view virtual returns (uint256);

    function balances(uint256 arg0) external view virtual returns (uint256);

    function fee() external view virtual returns (uint256);
}

// File: contracts/utils/CurveUtils.sol


pragma solidity ^0.6.12;


/**
 * @dev reverse-engineered utils to help Curve amount calculations
 */
contract CurveUtils {
    address internal constant CURVE_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // 3-pool DAI/USDC/USDT
    address internal constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    ICurveFiCurve internal curve = ICurveFiCurve(CURVE_ADDRESS);

    uint256 private constant N_COINS = 3;
    uint256[N_COINS] private RATES; //
    uint256[N_COINS] private PRECISION_MUL;
    uint256 private constant LENDING_PRECISION = 10**18;
    uint256 private constant FEE_DENOMINATOR = 10**10;

    mapping(address => int128) internal curveIndex;
    mapping(int128 => address) internal reverseCurveIndex;

    /**
     * @dev get index of a token in Curve pool contract
     */
    function getCurveIndex(address token) internal view returns (int128) {
        // to avoid 'stack too deep' compiler issue
        return curveIndex[token] - 1;
    }

    /**
     * @dev init internal variables at creation
     */
    function init() public virtual {
        RATES = [
            1000000000000000000,
            1000000000000000000000000000000,
            1000000000000000000000000000000
        ];
        PRECISION_MUL = [1, 1000000000000, 1000000000000];

        curveIndex[DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[USDC_ADDRESS] = 2;
        curveIndex[USDT_ADDRESS] = 3;
        reverseCurveIndex[0] = DAI_ADDRESS;
        reverseCurveIndex[1] = USDC_ADDRESS;
        reverseCurveIndex[2] = USDT_ADDRESS;
    }

    /**
     * @dev curve-specific maths
     */
    function get_D(uint256[N_COINS] memory xp, uint256 amp)
        internal
        pure
        returns (uint256)
    {
        uint256 S = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            S += xp[i];
        }
        if (S == 0) {
            return 0;
        }

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;

        for (uint256 i = 0; i < 255; i++) {
            uint256 D_P = D;

            for (uint256 j = 0; j < N_COINS; j++) {
                D_P = (D_P * D) / (xp[j] * N_COINS + 1); // +1 is to prevent /0
            }

            Dprev = D;
            D =
                ((Ann * S + D_P * N_COINS) * D) /
                ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if ((D - Dprev) <= 1) {
                    break;
                }
            } else {
                if ((Dprev - D) <= 1) {
                    break;
                }
            }
        }
        return D;
    }

    /**
     * @dev curve-specific maths
     */
    function get_y(
        uint256 i,
        uint256 j,
        uint256 x,
        uint256[N_COINS] memory xp_
    ) internal view returns (uint256) {
        //x in the input is converted to the same price/precision
        uint256 amp = curve.A();
        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * N_COINS;

        uint256 _x = 0;

        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i == i) {
                _x = x;
            } else if (_i != j) {
                _x = xp_[_i];
            } else {
                continue;
            }

            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }

        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann; //  # - D
        uint256 y_prev = 0;
        uint256 y = D;

        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            //# Equality with the precision of 1
            if (y > y_prev) {
                if ((y - y_prev) <= 1) {
                    break;
                } else if ((y_prev - y) <= 1) {
                    break;
                }
            }
        }

        return y;
    }

    /**
     * @dev curve-specific maths - this method does not exists in the curve pool but we recreated it
     */
    function get_dx_underlying(
        uint256 i,
        uint256 j,
        uint256 dy
    ) internal view returns (uint256) {
        //dx and dy in underlying units
        //uint256[N_COINS] rates = self._stored_rates();

        uint256[N_COINS] memory xp = _xp();

        uint256[N_COINS] memory precisions = PRECISION_MUL;

        uint256 y =
            xp[j] -
                ((dy * FEE_DENOMINATOR) / (FEE_DENOMINATOR - curve.fee())) *
                precisions[j];
        uint256 x = get_y(j, i, y, xp);
        uint256 dx = (x - xp[i]) / precisions[i];
        return dx;
    }

    /**
     * @dev curve-specific maths
     */
    function _xp() internal view returns (uint256[N_COINS] memory) {
        uint256[N_COINS] memory result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * curve.balances(i)) / LENDING_PRECISION;
        }

        return result;
    }
}

// File: contracts/access/Context.sol


pragma solidity ^0.6.0;

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

// File: contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.6.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// File: contracts/XTrinity.sol


pragma solidity ^0.6.12;







/**
 * @title XTrinity exchanger contract
 * @dev this is an implementation of a split exchange that takes the input amount and proposes a better price
 * given the liquidity obtained from multiple AMM DEX exchanges considering their liquidity at the moment
 * might also help mitigating a flashloan attack
 */
contract XTrinity is Ownable, CurveUtils, UniswapUtils {
    using UniversalERC20 for IERC20;
    using Address for address;

    using SafeMath for uint256;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    IERC20 private constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant WETH_ADDRESS =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    //address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address private constant UNI_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant BONUS_ADDRESS =
        0x8c545be506a335e24145EdD6e01D2754296ff018;
    IWETH internal constant weth = IWETH(address(WETH_ADDRESS));

    uint256 private constant PC_DENOMINATOR = 1e5;
    address[] private exchanges = [UNI_FACTORY, SUSHI_FACTORY, CURVE_ADDRESS];
    uint256 private constant ex_count = 3;
    uint256 public slippageFee; //1000 = 1% slippage
    uint256 public minPc;

    bool private initialized;

    /** @dev helper to identify if we work with ETH
     */
    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }

    /** @dev helper to identify if we work with WETH
     */
    function isWETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(WETH_ADDRESS));
    }

    /** @dev helper to identify if we work with ETH or WETH
     */
    function isofETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS) ||
            address(token) == address(WETH_ADDRESS));
    }

    /**
     * @dev initializer method instead of a constructor - though we don't normally use proxy here we still might want to
     */
    function init() public virtual override {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        _init();
    }

    /**
     * @dev internal variable initialization
     */
    function _init() internal virtual {
        slippageFee = 1000; //1%
        minPc = 20000; // 10%
        CurveUtils.init();
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit() public virtual onlyOwner {
        _init();
    }

    /**
     * @dev set the slippage %%
     */
    function setMinPc(uint256 _minPC) external onlyOwner {
        minPc = _minPC;
    }

    /**
     * @dev set the slippage %%
     */
    function setSlippageFee(uint256 _slippageFee) external onlyOwner {
        slippageFee = _slippageFee;
    }

    /**
     * @dev universal method to get the given AMM address reserves
     */
    function getReserves(
        IERC20 fromToken,
        IERC20 toToken,
        address factory
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        IERC20 _from = isETH(fromToken) ? WETH_ADDRESS : fromToken;
        IERC20 _to = isETH(toToken) ? WETH_ADDRESS : toToken;

        address fromAddress = address(_from);
        address toAddress = address(_to);

        if (factory != CURVE_ADDRESS) {
            //UNI
            IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);

            IUniswapV2Exchange pair = uniFactory.getPair(_from, _to);

            if (address(pair) != address(0)) {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

                (address token0, ) = sortTokens(fromAddress, toAddress);
                (reserveA, reserveB) = fromAddress == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
            }
        } else {
            // CURVE
            int128 fromIndex = int128(curveIndex[fromAddress]);
            int128 toIndex = int128(curveIndex[toAddress]);
            if (fromIndex > 0 && toIndex > 0) {
                reserveA = curve.balances(uint256(getCurveIndex(fromAddress)));
                reserveB = curve.balances(uint256(getCurveIndex(toAddress)));
            }
        }
    }

    /**
     * @dev Method to get the full reserves for the 2 token to be exchanged plus the proposed distribution to obtain the best price
     */
    function getFullReserves(IERC20 fromToken, IERC20 toToken)
        public
        view
        returns (
            uint256 fromTotal,
            uint256 destTotal,
            uint256[ex_count] memory dist,
            uint256[2][ex_count] memory res
        )
    {
        for (uint256 i = 0; i < ex_count; i++) {
            (uint256 balance0, uint256 balance1) =
                getReserves(fromToken, toToken, exchanges[i]);
            fromTotal += balance0;
            destTotal += balance1; //balance1 is toToken and the bigger it is  the juicier for us

            (res[i][0], res[i][1]) = (balance0, balance1);
        }

        if (destTotal > 0) {
            for (uint256 i = 0; i < ex_count; i++) {
                dist[i] = res[i][1].mul(PC_DENOMINATOR).div(destTotal);
            }
        }
    }

    /**
     * @dev Standard Uniswap V2 way to calculate the output amount given the input amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /**
     * @dev Standard Uniswap V2 way
     * given an output amount of an asset and pair reserves, returns a required input amount of the other asset
     */

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        // modification to prevent method fail if there is no liquidity
        if (amountOut >= reserveOut) {
            amountIn = uint256(-1);
        } else {
            uint256 numerator = reserveIn.mul(amountOut).mul(1000);
            uint256 denominator = reserveOut.sub(amountOut).mul(997);
            amountIn = (numerator / denominator).add(1);
        }
    }

    /**
     * @dev Method to get a direct quote between the given tokens - might not be always available
     * as there might not be any direct liquidity between them
     */
    function quoteDirect(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    )
        public
        view
        returns (uint256 returnAmount, uint256[ex_count] memory swapAmounts)
    {
        (
            ,
            ,
            uint256[ex_count] memory distribution,
            uint256[2][ex_count] memory reserves
        ) = getFullReserves(fromToken, toToken);

        uint256 addDistribution;
        uint256 eligible;
        uint256 lastNonZeroIndex;

        for (uint256 i = 0; i < ex_count; i++) {
            if (distribution[i] > minPc) {
                lastNonZeroIndex = i;
                eligible++;
            } else {
                addDistribution += distribution[i];
                distribution[i] = 0;
            }
        }
        require(eligible > 0, "No eligible pools");

        uint256 remainingAmount = amount;

        for (uint256 i = 0; i <= lastNonZeroIndex; i++) {
            if (distribution[i] > 0) {
                if (addDistribution > 0) {
                    distribution[i] += addDistribution.div(eligible);
                }

                if (i == lastNonZeroIndex) {
                    swapAmounts[i] = remainingAmount;
                } else {
                    swapAmounts[i] =
                        (amount * distribution[i]) /
                        PC_DENOMINATOR;
                }

                if (exchanges[i] == CURVE_ADDRESS) {
                    returnAmount += curve.get_dy_underlying(
                        getCurveIndex(address(fromToken)),
                        getCurveIndex(address(toToken)),
                        swapAmounts[i]
                    );
                } else {
                    returnAmount += getAmountOut(
                        swapAmounts[i],
                        reserves[i][0],
                        reserves[i][1]
                    );
                }

                remainingAmount -= swapAmounts[i];
            }
        }
    }

    /**
     * @dev Method to get a reverse direct quote between the given tokens - might not be always available
     * as there might not be any direct liquidity between them
     */
    function reverseQuoteDirect(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    )
        public
        view
        returns (uint256 inputAmount, uint256[ex_count] memory swapAmounts)
    {
        (
            ,
            ,
            uint256[ex_count] memory distribution,
            uint256[2][ex_count] memory reserves
        ) = getFullReserves(fromToken, toToken);

        uint256 addDistribution;
        uint256 eligible;
        uint256 lastNonZeroIndex;

        for (uint256 i = 0; i < ex_count; i++) {
            if (distribution[i] > minPc) {
                lastNonZeroIndex = i;
                eligible++;
            } else {
                addDistribution += distribution[i];
                distribution[i] = 0;
            }
        }
        require(eligible > 0, "No eligible pools");

        uint256 remainingAmount = returnAmount;

        for (uint256 i = 0; i <= lastNonZeroIndex; i++) {
            if (distribution[i] > 0) {
                if (addDistribution > 0) {
                    distribution[i] += addDistribution.div(eligible);
                }

                if (i == lastNonZeroIndex) {
                    swapAmounts[i] = remainingAmount;
                } else {
                    swapAmounts[i] =
                        (returnAmount * distribution[i]) /
                        PC_DENOMINATOR;
                }

                if (exchanges[i] == CURVE_ADDRESS) {
                    inputAmount += get_dx_underlying(
                        uint256(getCurveIndex(address(fromToken))),
                        uint256(getCurveIndex(address(toToken))),
                        swapAmounts[i]
                    );
                } else {
                    inputAmount += getAmountIn(
                        swapAmounts[i],
                        reserves[i][0],
                        reserves[i][1]
                    );
                }

                remainingAmount -= swapAmounts[i];
            }
        }
    }

    /**
     * @dev Method to get a best quote between the direct and through the WETH -
     * as there is more liquidity between token/ETH than token0/token1
     */
    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256[ex_count] memory swapAmountsIn,
            uint256[ex_count] memory swapAmountsOut,
            bool swapVia
        )
    {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            (
                uint256 returnAmountDirect,
                uint256[ex_count] memory swapAmounts1
            ) = quoteDirect(fromToken, toToken, amount);
            returnAmount = returnAmountDirect;
            swapAmountsIn = swapAmounts1;
            if (!isofETH(toToken) && !isofETH(fromToken)) {
                (
                    uint256 returnAmountETH,
                    uint256[ex_count] memory swapAmounts2
                ) = quoteDirect(fromToken, WETH_ADDRESS, amount);
                (
                    uint256 returnAmountVia,
                    uint256[ex_count] memory swapAmounts3
                ) = quoteDirect(WETH_ADDRESS, toToken, returnAmountETH);

                if (returnAmountVia > returnAmountDirect) {
                    returnAmount = returnAmountVia;
                    swapAmountsIn = swapAmounts2;
                    swapAmountsOut = swapAmounts3;
                    swapVia = true;
                }
            }
        }
    }

    /**
     * @dev Method to get a best Reverse Quote between the direct and through the WETH -
     * as there is more liquidity between token/ETH than token0/token1
     */
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    )
        public
        view
        returns (
            uint256 inputAmount,
            uint256[ex_count] memory swapAmountsIn,
            uint256[ex_count] memory swapAmountsOut,
            bool swapVia
        )
    {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            (uint256 inputAmountDirect, uint256[ex_count] memory swapAmounts1) =
                reverseQuoteDirect(fromToken, toToken, returnAmount);
            inputAmount = inputAmountDirect;
            swapAmountsIn = swapAmounts1;
            if (!isofETH(toToken) && !isofETH(fromToken)) {
                (
                    uint256 inputAmountETH,
                    uint256[ex_count] memory swapAmounts3
                ) = reverseQuoteDirect(WETH_ADDRESS, toToken, returnAmount);
                (
                    uint256 inputAmountVia,
                    uint256[ex_count] memory swapAmounts2
                ) = reverseQuoteDirect(fromToken, WETH_ADDRESS, inputAmountETH);

                if (inputAmountVia < inputAmountDirect) {
                    inputAmount = inputAmountVia;
                    swapAmountsIn = swapAmounts2;
                    swapAmountsOut = swapAmounts3;
                    swapVia = true;
                }
            }
        }
    }

    /**
     * @dev run a swap across multiple exchanges given the splitted amounts
     * @param swapAmounts - array of splitted amounts
     */
    function executeSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256[ex_count] memory swapAmounts
    ) internal returns (uint256 returnAmount) {
        for (uint256 i = 0; i < swapAmounts.length; i++) {
            if (swapAmounts[i] > 0) {
                uint256 thisBalance =
                    fromToken.universalBalanceOf(address(this));
                uint256 swapAmount = min(thisBalance, swapAmounts[i]);

                if (exchanges[i] != CURVE_ADDRESS) {
                    returnAmount += _swapOnUniswapV2Internal(
                        fromToken,
                        toToken,
                        swapAmount,
                        exchanges[i]
                    );
                } else {
                    returnAmount += _swapOnCurve(
                        fromToken,
                        toToken,
                        swapAmount
                    );
                }
            }
        }
    }

    /**
     * @dev Main function to run a swap
     * @param slipProtect - enable/disable slip protection
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable virtual returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            return amount;
        }

        if (isETH(fromToken)) {
            amount = msg.value;
            weth.deposit{value: amount}();
            fromToken = WETH_ADDRESS;
        } else {
            fromToken.universalTransferFrom(msg.sender, address(this), amount);
        }

        amount = min(fromToken.balanceOf(address(this)), amount);

        (
            uint256 returnQuoteAmount,
            uint256[ex_count] memory swapAmountsIn,
            uint256[ex_count] memory swapAmountsOut,
            bool swapVia
        ) = quote(fromToken, toToken, amount);

        uint256 minAmount;
        if (slipProtect) {
            uint256 feeSlippage =
                returnQuoteAmount.mul(slippageFee).div(PC_DENOMINATOR);
            minAmount = returnQuoteAmount.sub(feeSlippage);
        }

        if (swapVia) {
            executeSwap(fromToken, WETH_ADDRESS, swapAmountsIn);
            returnAmount = executeSwap(WETH_ADDRESS, toToken, swapAmountsOut);
        } else {
            returnAmount = executeSwap(fromToken, toToken, swapAmountsIn);
        }
        require(returnAmount >= minAmount, "XTrinity slippage is too high");

        if (isETH(toToken)) {
            toToken = IERC20(0);
            weth.withdraw(WETH_ADDRESS.balanceOf(address(this)));
        }
        toToken.universalTransfer(msg.sender, returnAmount);
    }

    /**
     * @dev fallback function to withdraw tokens from contract
     * - not normally needed
     */
    function transferTokenBack(address TokenAddress)
        external
        onlyOwner
        returns (uint256 returnBalance)
    {
        IERC20 Token = IERC20(TokenAddress);
        returnBalance = Token.universalBalanceOf(address(this));
        if (returnBalance > 0) {
            Token.universalTransfer(msg.sender, returnBalance);
        }
    }

    function _swapOnCurve(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) private returns (uint256 returnAmount) {
        //using curve

        if (fromToken.allowance(address(this), CURVE_ADDRESS) < amount) {
            fromToken.universalApprove(CURVE_ADDRESS, 0);
            fromToken.universalApprove(CURVE_ADDRESS, uint256(-1));
        }

        uint256 startBalance = destToken.balanceOf(address(this));

        // actual index is -1
        curve.exchange(
            getCurveIndex(address(fromToken)),
            getCurveIndex(address(destToken)),
            amount,
            0
        );

        return destToken.balanceOf(address(this)) - startBalance;
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        address factory
    ) private returns (uint256 returnAmount) {
        destToken = isETH(destToken) ? WETH_ADDRESS : destToken;
        IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);
        IUniswapV2Exchange exchange = uniFactory.getPair(fromToken, destToken);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(
            fromToken,
            destToken,
            amount
        );
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(BONUS_ADDRESS);
        }

        fromToken.universalTransfer(address(exchange), amount);
        if (uint256(address(fromToken)) < uint256(address(destToken))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }
    }

    /**
     * @dev payable fallback to allow for WETH withdrawal
     */
    receive() external payable {}
}